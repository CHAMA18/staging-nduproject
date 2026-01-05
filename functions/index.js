const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const runtimeConfig = typeof functions.config === 'function' ? functions.config() : {};
const appConfig = runtimeConfig.app || {};
const configuredBaseUrl = appConfig.base_url || appConfig.baseUrl || '';
const configAllowedOrigins = appConfig.allowed_origins || appConfig.allowedOrigins || '';
const envAllowedOrigins = process.env.APP_ALLOWED_ORIGINS || '';
const APP_BASE_URL = process.env.APP_BASE_URL || configuredBaseUrl || 'https://ndu-d3f60.web.app';
const EXTRA_ALLOWED_ORIGINS = [configAllowedOrigins, envAllowedOrigins]
  .flatMap((value) => value.split(','))
  .map((origin) => origin.trim())
  .filter(Boolean);
const CORS_ALLOWED_ORIGINS = [
  /^(http|https):\/\/localhost(:\d+)?$/,
  /^(http|https):\/\/127\.0\.0\.1(:\d+)?$/,
  /\.web\.app$/,
  /\.firebaseapp\.com$/,
  APP_BASE_URL,
  ...EXTRA_ALLOWED_ORIGINS
];
const FX_CACHE_TTL_MS = 6 * 60 * 60 * 1000;
const fxCache = { usdToNgn: null, fetchedAt: 0 };

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Verify Firebase Auth token from request headers
 */
async function verifyAuthToken(req) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  try {
    const idToken = authHeader.split('Bearer ')[1];
    return await admin.auth().verifyIdToken(idToken);
  } catch (error) {
    console.error('Auth token verification failed:', error);
    return null;
  }
}

/**
 * Set CORS headers for response
 */
function setCorsHeaders(req, res) {
  const origin = req.headers.origin;
  const isAllowed = origin && CORS_ALLOWED_ORIGINS.some((allowed) =>
    typeof allowed === 'string' ? allowed === origin : allowed.test(origin)
  );
  
  if (isAllowed) {
    res.set('Access-Control-Allow-Origin', origin);
  }
  res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

function getRequestOrigin(req) {
  return req.headers.origin || APP_BASE_URL;
}

function getPayPalBaseUrl(clientId) {
  const env = (process.env.PAYPAL_ENV || '').toLowerCase();
  if (env === 'sandbox') return 'https://api-m.sandbox.paypal.com';
  if (env === 'live') return 'https://api-m.paypal.com';

  const normalizedId = (clientId || '').toLowerCase();
  if (normalizedId.startsWith('sb') || normalizedId.includes('sandbox')) {
    return 'https://api-m.sandbox.paypal.com';
  }

  return 'https://api-m.paypal.com';
}

async function getUsdToNgnRate() {
  const now = Date.now();
  if (fxCache.usdToNgn && now - fxCache.fetchedAt < FX_CACHE_TTL_MS) {
    return fxCache.usdToNgn;
  }

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 3500);
    const response = await fetch('https://open.er-api.com/v6/latest/USD', {
      signal: controller.signal,
    });
    clearTimeout(timeout);

    if (!response.ok) {
      throw new Error(`FX fetch failed (${response.status})`);
    }

    const data = await response.json();
    const rate = Number(data?.rates?.NGN);
    if (!Number.isFinite(rate) || rate <= 0) {
      throw new Error('FX rate for NGN unavailable');
    }

    fxCache.usdToNgn = rate;
    fxCache.fetchedAt = now;
    return rate;
  } catch (error) {
    console.warn('FX rate fetch failed:', error.message || error);
    return null;
  }
}

/**
 * Get subscription pricing in cents
 */
function getSubscriptionPrice(tier, isAnnual) {
  const prices = {
    project: { monthly: 7900, annual: 79000 },
    program: { monthly: 18900, annual: 189000 },
    portfolio: { monthly: 44900, annual: 449000 }
  };
  const tierPrices = prices[tier] || prices.project;
  return isAnnual ? tierPrices.annual : tierPrices.monthly;
}

/**
 * Validate a coupon and calculate the discounted price (in cents).
 */
async function validateCouponForTier(couponCode, tier, originalPriceCents) {
  if (!couponCode) {
    return { couponId: null, discountedPriceCents: originalPriceCents, discountPercent: 0, discountAmount: 0 };
  }

  const couponSnapshot = await db.collection('coupons')
    .where('code', '==', couponCode.toUpperCase())
    .limit(1)
    .get();

  if (couponSnapshot.empty) {
    throw new Error('Coupon not found');
  }

  const couponDoc = couponSnapshot.docs[0];
  const coupon = couponDoc.data();

  const now = new Date();
  const validFrom = coupon.validFrom?.toDate ? coupon.validFrom.toDate() : new Date(0);
  const validUntil = coupon.validUntil?.toDate ? coupon.validUntil.toDate() : new Date(0);

  if (!coupon.isActive) throw new Error('Coupon is inactive');
  if (now < validFrom || now > validUntil) throw new Error('Coupon has expired');
  if (coupon.maxUses && coupon.currentUses >= coupon.maxUses) throw new Error('Coupon usage limit reached');
  if (coupon.applicableTiers && coupon.applicableTiers.length > 0 && !coupon.applicableTiers.includes(tier)) {
    throw new Error('Coupon not valid for this plan');
  }

  let discountedPriceCents = originalPriceCents;
  if (coupon.discountAmount && coupon.discountAmount > 0) {
    discountedPriceCents = Math.max(0, originalPriceCents - Math.round(coupon.discountAmount * 100));
  } else if (coupon.discountPercent && coupon.discountPercent > 0) {
    discountedPriceCents = Math.max(0, Math.round(originalPriceCents * (1 - coupon.discountPercent / 100)));
  }

  return {
    couponId: couponDoc.id,
    discountedPriceCents,
    discountPercent: coupon.discountPercent || 0,
    discountAmount: coupon.discountAmount || 0,
  };
}

/**
 * Secure OpenAI API Proxy
 * 
 * This Cloud Function acts as a secure proxy to OpenAI's API, keeping the API key
 * server-side and never exposing it to client code or version control.
 * 
 * Setup Instructions:
 * 1. Set your OpenAI API key as a secret in Firebase:
 *    firebase functions:secrets:set OPENAI_API_KEY
 *    
 * 2. Deploy this function:
 *    firebase deploy --only functions
 *    
 * 3. Update lib/services/api_config_secure.dart:
 *    Change baseUrl to your Cloud Function URL:
 *    'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/openaiProxy'
 * 
 * Security Features:
 * - API key stored as Firebase secret (never in code or environment)
 * - Optional Firebase Auth verification
 * - CORS configured for your app domain only
 * - Request validation and sanitization
 * - Rate limiting per user (optional)
 */

exports.openaiProxy = functions
  .runWith({
    secrets: ['OPENAI_API_KEY'],
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    // CORS configuration - restrict to your domain in production
    const allowedOrigins = [
      'https://your-app-domain.web.app',
      'https://your-app-domain.firebaseapp.com'
    ];
    
    const origin = req.headers.origin;
    const isLocalhost = typeof origin === 'string' && (origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1'));
    if (isLocalhost || allowedOrigins.includes(origin)) {
      res.set('Access-Control-Allow-Origin', origin);
    }
    
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed. Use POST.' });
      return;
    }
    
    try {
      // Optional: Verify Firebase Auth token
      // Uncomment the following lines to require authentication:
      /*
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.status(401).json({ error: 'Unauthorized. Missing or invalid token.' });
        return;
      }
      
      const idToken = authHeader.split('Bearer ')[1];
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const userId = decodedToken.uid;
      
      // Optional: Implement rate limiting per user
      // Check Firestore for user's request count and block if exceeded
      */
      
      // Get OpenAI API key from Firebase secrets
      const apiKey = process.env.OPENAI_API_KEY;
      if (!apiKey) {
        console.error('OPENAI_API_KEY secret not configured');
        res.status(500).json({ error: 'Service configuration error' });
        return;
      }
      
      // Determine endpoint path from request payload
      // If client provides explicit endpoint, use it. Otherwise, infer:
      // - Presence of `input` usually means Responses API
      // - Otherwise default to Chat Completions
      let endpoint = req.body.endpoint;
      if (!endpoint) {
        if (req.body && (typeof req.body === 'object') && ('input' in req.body)) {
          endpoint = '/responses';
        } else {
          endpoint = '/chat/completions';
        }
      }
      const openaiUrl = `https://api.openai.com/v1${endpoint}`;
      
      // Forward the request to OpenAI
      const openaiResponse = await fetch(openaiUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${apiKey}`
        },
        body: JSON.stringify(req.body.payload || req.body)
      });
      
      const data = await openaiResponse.json();
      
      // Return OpenAI's response to the client
      res.status(openaiResponse.status).json(data);
      
    } catch (error) {
      console.error('OpenAI proxy error:', error);
      res.status(500).json({ 
        error: 'Failed to process request',
        message: error.message 
      });
    }
  });

// ============================================================================
// STRIPE PAYMENT FUNCTIONS
// ============================================================================

/**
 * Create Stripe Checkout Session
 * 
 * Setup: firebase functions:secrets:set STRIPE_SECRET_KEY
 */
exports.createStripeCheckout = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
      if (!stripeSecretKey) {
        console.error('STRIPE_SECRET_KEY not configured');
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { tier, isAnnual, email, couponCode } = req.body;
      const userId = decodedToken.uid;
      let priceInCents = getSubscriptionPrice(tier, isAnnual);
      let couponId = null;

      if (couponCode) {
        try {
          const couponResult = await validateCouponForTier(couponCode, tier, priceInCents);
          priceInCents = couponResult.discountedPriceCents;
          couponId = couponResult.couponId;
        } catch (err) {
          res.status(400).json({ error: err.message || 'Invalid coupon' });
          return;
        }
      }
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'stripe',
        isAnnual: isAnnual || false,
        couponId: couponId || null,
        couponCode: couponCode ? couponCode.toUpperCase() : null,
        discountedPriceCents: priceInCents,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Call Stripe API to create checkout session
      const origin = getRequestOrigin(req);
      const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${stripeSecretKey}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: new URLSearchParams({
          'payment_method_types[]': 'card',
          'line_items[0][price_data][currency]': 'usd',
          'line_items[0][price_data][product_data][name]': `${tier.charAt(0).toUpperCase() + tier.slice(1)} Plan`,
          'line_items[0][price_data][unit_amount]': priceInCents.toString(),
          'line_items[0][quantity]': '1',
          'mode': 'payment',
          'success_url': `${origin}/payment-success?session_id={CHECKOUT_SESSION_ID}&subscription_id=${subscriptionRef.id}`,
          'cancel_url': `${origin}/pricing`,
          'customer_email': email,
          'metadata[subscription_id]': subscriptionRef.id,
          'metadata[user_id]': userId,
          'metadata[tier]': tier,
          ...(couponId ? { 'metadata[coupon_id]': couponId } : {})
        })
      });
      
      const session = await response.json();
      
      if (session.error) {
        throw new Error(session.error.message);
      }
      
      // Update subscription with Stripe session ID
      await subscriptionRef.update({
        externalSubscriptionId: session.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({
        success: true,
        checkoutUrl: session.url,
        subscriptionId: subscriptionRef.id
      });
      
    } catch (error) {
      console.error('Stripe checkout error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Verify Stripe Payment
 */
exports.verifyStripePayment = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
      if (!stripeSecretKey) {
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { reference } = req.body;
      
      // Retrieve session from Stripe
      const response = await fetch(`https://api.stripe.com/v1/checkout/sessions/${reference}`, {
        headers: {
          'Authorization': `Bearer ${stripeSecretKey}`
        }
      });
      
      const session = await response.json();
      
      if (session.payment_status === 'paid') {
        const subscriptionId = session.metadata?.subscription_id;
        const userId = session.metadata?.user_id;
        const tier = session.metadata?.tier;
        const couponId = session.metadata?.coupon_id;
        
        if (subscriptionId) {
          const now = new Date();
          const endDate = new Date(now);
          endDate.setFullYear(endDate.getFullYear() + 1);

          const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
          const subscriptionData = subscriptionDoc.data() || {};
          
          await db.collection('subscriptions').doc(subscriptionId).update({
            status: 'active',
            startDate: admin.firestore.Timestamp.fromDate(now),
            endDate: admin.firestore.Timestamp.fromDate(endDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          const appliedCouponId = couponId || subscriptionData.couponId;
          if (appliedCouponId) {
            await db.collection('coupons').doc(appliedCouponId).update({
              currentUses: admin.firestore.FieldValue.increment(1),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
          
          // Record invoice
          const invoiceRef = db.collection('invoices').doc();
          await invoiceRef.set({
            id: invoiceRef.id,
            userId: userId || decodedToken.uid,
            amount: session.amount_total / 100,
            currency: (session.currency || 'usd').toUpperCase(),
            status: 'paid',
            provider: 'stripe',
            subscriptionId,
            externalId: session.id,
            tier,
            description: `${tier ? tier.charAt(0).toUpperCase() + tier.slice(1) : ''} Plan Subscription`,
            receiptUrl: session.receipt_url || null,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        
        res.json({ success: true, subscriptionId });
      } else {
        res.json({ success: false, error: 'Payment not completed' });
      }
      
    } catch (error) {
      console.error('Stripe verification error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// PAYPAL PAYMENT FUNCTIONS
// ============================================================================

/**
 * Create PayPal Order
 * 
 * Setup:
 *   firebase functions:secrets:set PAYPAL_CLIENT_ID
 *   firebase functions:secrets:set PAYPAL_CLIENT_SECRET
 */
exports.createPayPalOrder = functions
  .runWith({
    secrets: ['PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const clientId = process.env.PAYPAL_CLIENT_ID;
      const clientSecret = process.env.PAYPAL_CLIENT_SECRET;
      
      if (!clientId || !clientSecret) {
        console.error('PayPal credentials not configured');
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { tier, isAnnual, couponCode } = req.body;
      const userId = decodedToken.uid;
      let priceInCents = getSubscriptionPrice(tier, isAnnual);
      let couponId = null;

      if (couponCode) {
        try {
          const couponResult = await validateCouponForTier(couponCode, tier, priceInCents);
          priceInCents = couponResult.discountedPriceCents;
          couponId = couponResult.couponId;
        } catch (err) {
          res.status(400).json({ error: err.message || 'Invalid coupon' });
          return;
        }
      }
      const priceInDollars = (priceInCents / 100).toFixed(2);
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'paypal',
        isAnnual: isAnnual || false,
        couponId: couponId || null,
        couponCode: couponCode ? couponCode.toUpperCase() : null,
        discountedPriceCents: priceInCents,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Get PayPal access token
      const paypalBaseUrl = getPayPalBaseUrl(clientId);
      const authResponse = await fetch(`${paypalBaseUrl}/v1/oauth2/token`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'grant_type=client_credentials'
      });
      
      const authData = await authResponse.json();
      if (!authData.access_token) {
        throw new Error('Failed to authenticate with PayPal');
      }
      
      // Create PayPal order
      const origin = getRequestOrigin(req);
      const orderResponse = await fetch(`${paypalBaseUrl}/v2/checkout/orders`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authData.access_token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          intent: 'CAPTURE',
          purchase_units: [{
            amount: {
              currency_code: 'USD',
              value: priceInDollars
            },
            description: `${tier.charAt(0).toUpperCase() + tier.slice(1)} Plan Subscription`,
            custom_id: subscriptionRef.id
          }],
          application_context: {
            return_url: `${origin}/payment-success?subscription_id=${subscriptionRef.id}`,
            cancel_url: `${origin}/pricing`
          }
        })
      });
      
      const order = await orderResponse.json();
      
      if (order.error) {
        throw new Error(order.error.message || 'PayPal order creation failed');
      }
      
      // Update subscription with PayPal order ID
      await subscriptionRef.update({
        externalSubscriptionId: order.id,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      const approvalLink = order.links?.find(link => link.rel === 'approve');
      
      res.json({
        success: true,
        approvalUrl: approvalLink?.href,
        orderId: order.id,
        subscriptionId: subscriptionRef.id
      });
      
    } catch (error) {
      console.error('PayPal order error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Verify PayPal Payment
 */
exports.verifyPayPalPayment = functions
  .runWith({
    secrets: ['PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const clientId = process.env.PAYPAL_CLIENT_ID;
      const clientSecret = process.env.PAYPAL_CLIENT_SECRET;
      
      if (!clientId || !clientSecret) {
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { reference } = req.body;
      
      // Get PayPal access token
      const paypalBaseUrl = getPayPalBaseUrl(clientId);
      const authResponse = await fetch(`${paypalBaseUrl}/v1/oauth2/token`, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: 'grant_type=client_credentials'
      });
      
      const authData = await authResponse.json();
      
      // Capture the payment
      const captureResponse = await fetch(`${paypalBaseUrl}/v2/checkout/orders/${reference}/capture`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authData.access_token}`,
          'Content-Type': 'application/json'
        }
      });
      
      const captureData = await captureResponse.json();
      
      if (captureData.status === 'COMPLETED') {
        const subscriptionId = captureData.purchase_units?.[0]?.custom_id;
        const purchaseUnit = captureData.purchase_units?.[0];
        const capture = purchaseUnit?.payments?.captures?.[0];
        
        if (subscriptionId) {
          const now = new Date();
          const endDate = new Date(now);
          endDate.setFullYear(endDate.getFullYear() + 1);
          
          // Get subscription to get tier and userId
          const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
          const subscriptionData = subscriptionDoc.data() || {};
          
          await db.collection('subscriptions').doc(subscriptionId).update({
            status: 'active',
            startDate: admin.firestore.Timestamp.fromDate(now),
            endDate: admin.firestore.Timestamp.fromDate(endDate),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });

          if (subscriptionData.couponId) {
            await db.collection('coupons').doc(subscriptionData.couponId).update({
              currentUses: admin.firestore.FieldValue.increment(1),
              updatedAt: admin.firestore.FieldValue.serverTimestamp()
            });
          }
          
          // Record invoice
          const invoiceRef = db.collection('invoices').doc();
          await invoiceRef.set({
            id: invoiceRef.id,
            userId: subscriptionData.userId || decodedToken.uid,
            amount: parseFloat(capture?.amount?.value || purchaseUnit?.amount?.value || 0),
            currency: (capture?.amount?.currency_code || purchaseUnit?.amount?.currency_code || 'USD'),
            status: 'paid',
            provider: 'paypal',
            subscriptionId,
            externalId: captureData.id,
            tier: subscriptionData.tier,
            description: `${subscriptionData.tier ? subscriptionData.tier.charAt(0).toUpperCase() + subscriptionData.tier.slice(1) : ''} Plan Subscription`,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            paidAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        
        res.json({ success: true, subscriptionId });
      } else {
        res.json({ success: false, error: 'Payment not completed' });
      }
      
    } catch (error) {
      console.error('PayPal verification error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// PAYSTACK PAYMENT FUNCTIONS
// ============================================================================

/**
 * Create Paystack Transaction
 * 
 * Setup: firebase functions:secrets:set PAYSTACK_SECRET_KEY
 */
exports.createPaystackTransaction = functions
  .runWith({
    secrets: ['PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const paystackSecretKey = process.env.PAYSTACK_SECRET_KEY;
      if (!paystackSecretKey) {
        console.error('PAYSTACK_SECRET_KEY not configured');
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { tier, isAnnual, email, couponCode } = req.body;
      const userId = decodedToken.uid;
      let priceInCents = getSubscriptionPrice(tier, isAnnual);
      let couponId = null;

      if (couponCode) {
        try {
          const couponResult = await validateCouponForTier(couponCode, tier, priceInCents);
          priceInCents = couponResult.discountedPriceCents;
          couponId = couponResult.couponId;
        } catch (err) {
          res.status(400).json({ error: err.message || 'Invalid coupon' });
          return;
        }
      }

      const paystackCurrency = (process.env.PAYSTACK_CURRENCY || 'NGN').toUpperCase();
      const paystackUsdRateRaw = process.env.PAYSTACK_USD_TO_NGN;
      const paystackUsdRateOverride = Number.isFinite(Number(paystackUsdRateRaw)) ? Number(paystackUsdRateRaw) : null;
      const liveUsdToNgnRate = paystackCurrency === 'NGN' ? await getUsdToNgnRate() : null;
      const paystackUsdRate = paystackUsdRateOverride ?? liveUsdToNgnRate ?? 1500;
      const paystackUsdEquivalentRaw = process.env.PAYSTACK_USD_EQUIVALENT;
      const paystackUsdEquivalent = Number.isFinite(Number(paystackUsdEquivalentRaw)) ? Number(paystackUsdEquivalentRaw) : 20;
      const baseUsdAmount = paystackUsdEquivalent > 0 ? paystackUsdEquivalent : (priceInCents / 100);
      let priceInMinorUnits;

      if (paystackCurrency === 'NGN') {
        priceInMinorUnits = Math.round(baseUsdAmount * paystackUsdRate * 100);
      } else {
        const paystackAmountMultiplierRaw = process.env.PAYSTACK_AMOUNT_MULTIPLIER;
        const paystackAmountMultiplier = Number.isFinite(Number(paystackAmountMultiplierRaw))
          ? Number(paystackAmountMultiplierRaw)
          : 1;
        priceInMinorUnits = Math.round(priceInCents * paystackAmountMultiplier);
      }
      
      // Create pending subscription record
      const subscriptionRef = db.collection('subscriptions').doc();
      await subscriptionRef.set({
        id: subscriptionRef.id,
        userId,
        tier,
        status: 'pending',
        provider: 'paystack',
        isAnnual: isAnnual || false,
        couponId: couponId || null,
        couponCode: couponCode ? couponCode.toUpperCase() : null,
        discountedPriceCents: priceInCents,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Initialize Paystack transaction
      const origin = getRequestOrigin(req);
      const response = await fetch('https://api.paystack.co/transaction/initialize', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${paystackSecretKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email,
          amount: priceInMinorUnits,
          currency: paystackCurrency,
          reference: subscriptionRef.id,
          callback_url: `${origin}/payment-success`,
          metadata: {
            subscription_id: subscriptionRef.id,
            user_id: userId,
            tier
          }
        })
      });
      
      const data = await response.json();
      
      if (!data.status) {
        throw new Error(data.message || 'Paystack initialization failed');
      }
      
      // Update subscription with Paystack reference
      await subscriptionRef.update({
        externalSubscriptionId: data.data.reference,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({
        success: true,
        authorizationUrl: data.data.authorization_url,
        accessCode: data.data.access_code,
        reference: data.data.reference,
        subscriptionId: subscriptionRef.id
      });
      
    } catch (error) {
      console.error('Paystack transaction error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Verify Paystack Payment
 */
exports.verifyPaystackPayment = functions
  .runWith({
    secrets: ['PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const paystackSecretKey = process.env.PAYSTACK_SECRET_KEY;
      if (!paystackSecretKey) {
        res.status(500).json({ error: 'Payment service not configured' });
        return;
      }
      
      const { reference } = req.body;
      
      // Verify transaction
      const response = await fetch(`https://api.paystack.co/transaction/verify/${reference}`, {
        headers: {
          'Authorization': `Bearer ${paystackSecretKey}`
        }
      });
      
      const data = await response.json();
      
      if (data.status && data.data.status === 'success') {
        const subscriptionId = data.data.metadata?.subscription_id || reference;
        const txnData = data.data;
        
        const now = new Date();
        const endDate = new Date(now);
        endDate.setFullYear(endDate.getFullYear() + 1);
        
        // Get subscription to get tier and userId
        const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
        const subscriptionData = subscriptionDoc.data() || {};
        
        await db.collection('subscriptions').doc(subscriptionId).update({
          status: 'active',
          startDate: admin.firestore.Timestamp.fromDate(now),
          endDate: admin.firestore.Timestamp.fromDate(endDate),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        if (subscriptionData.couponId) {
          await db.collection('coupons').doc(subscriptionData.couponId).update({
            currentUses: admin.firestore.FieldValue.increment(1),
            updatedAt: admin.firestore.FieldValue.serverTimestamp()
          });
        }
        
        // Record invoice
        const invoiceRef = db.collection('invoices').doc();
        await invoiceRef.set({
          id: invoiceRef.id,
          userId: subscriptionData.userId || decodedToken.uid,
          amount: (txnData.amount || 0) / 100,
          currency: txnData.currency || 'NGN',
          status: 'paid',
          provider: 'paystack',
          subscriptionId,
          externalId: txnData.reference,
          tier: subscriptionData.tier || txnData.metadata?.tier,
          description: `${subscriptionData.tier ? subscriptionData.tier.charAt(0).toUpperCase() + subscriptionData.tier.slice(1) : ''} Plan Subscription`,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        res.json({ success: true, subscriptionId });
      } else {
        res.json({ success: false, error: 'Payment not completed' });
      }
      
    } catch (error) {
      console.error('Paystack verification error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// COUPON MANAGEMENT
// ============================================================================

/**
 * Apply Coupon to Payment
 * Validates and applies a coupon code during checkout
 */
exports.applyCoupon = functions
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const { couponCode, tier, originalPrice } = req.body;
      
      if (!couponCode || !tier || originalPrice === undefined) {
        res.status(400).json({ error: 'Missing required fields' });
        return;
      }

      const originalPriceCents = Math.round(Number(originalPrice) * 100);
      const couponResult = await validateCouponForTier(couponCode, tier, originalPriceCents);
      
      res.json({
        success: true,
        couponId: couponResult.couponId,
        originalPrice,
        discountedPrice: Math.round(couponResult.discountedPriceCents) / 100,
        discountPercent: couponResult.discountPercent,
        discountAmount: couponResult.discountAmount || 0,
        description: ''
      });
      
    } catch (error) {
      console.error('Apply coupon error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Use Coupon (increment usage count)
 * Called after successful payment
 */
exports.useCoupon = functions
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const { couponId } = req.body;
      
      if (!couponId) {
        res.status(400).json({ error: 'Missing coupon ID' });
        return;
      }
      
      // Increment usage count
      await db.collection('coupons').doc(couponId).update({
        currentUses: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({ success: true });
      
    } catch (error) {
      console.error('Use coupon error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// INVOICE HISTORY
// ============================================================================

/**
 * Get User Invoice History
 * Fetches payment history from all providers for a specific user
 */
exports.getUserInvoices = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY', 'PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET', 'PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 60,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const { userId, userEmail } = req.body;
      const targetUserId = userId || decodedToken.uid;
      
      // Check if requesting user is admin or requesting own data
      const adminEmails = ['chungu424@gmail.com'];
      const isAdmin = adminEmails.includes(decodedToken.email);
      if (!isAdmin && targetUserId !== decodedToken.uid) {
        res.status(403).json({ error: 'Not authorized to view this user\'s invoices' });
        return;
      }
      
      const invoices = [];
      
      // Get subscriptions for the user to find external IDs
      const subscriptionsSnapshot = await db.collection('subscriptions')
        .where('userId', '==', targetUserId)
        .orderBy('createdAt', 'desc')
        .get();
      
      // Also fetch from invoices collection (stored after successful payments)
      const invoicesSnapshot = await db.collection('invoices')
        .where('userId', '==', targetUserId)
        .orderBy('createdAt', 'desc')
        .get();
      
      for (const doc of invoicesSnapshot.docs) {
        const data = doc.data();
        invoices.push({
          id: doc.id,
          amount: data.amount || 0,
          currency: data.currency || 'USD',
          status: data.status || 'paid',
          provider: data.provider || 'unknown',
          description: data.description || 'Subscription payment',
          createdAt: data.createdAt?.toDate()?.toISOString() || new Date().toISOString(),
          paidAt: data.paidAt?.toDate()?.toISOString(),
          subscriptionId: data.subscriptionId,
          externalId: data.externalId,
          tier: data.tier,
          receiptUrl: data.receiptUrl,
        });
      }
      
      // Try to fetch from Stripe if configured
      const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
      if (stripeSecretKey && userEmail) {
        try {
          // First find customer by email
          const customerResponse = await fetch(
            `https://api.stripe.com/v1/customers?email=${encodeURIComponent(userEmail)}&limit=1`,
            {
              headers: { 'Authorization': `Bearer ${stripeSecretKey}` }
            }
          );
          const customerData = await customerResponse.json();
          
          if (customerData.data && customerData.data.length > 0) {
            const customerId = customerData.data[0].id;
            
            // Fetch charges/payments for this customer
            const chargesResponse = await fetch(
              `https://api.stripe.com/v1/charges?customer=${customerId}&limit=100`,
              {
                headers: { 'Authorization': `Bearer ${stripeSecretKey}` }
              }
            );
            const chargesData = await chargesResponse.json();
            
            if (chargesData.data) {
              for (const charge of chargesData.data) {
                // Avoid duplicates
                if (!invoices.find(i => i.externalId === charge.id)) {
                  invoices.push({
                    id: `stripe_${charge.id}`,
                    amount: charge.amount / 100,
                    currency: charge.currency.toUpperCase(),
                    status: charge.status === 'succeeded' ? 'paid' : charge.status,
                    provider: 'stripe',
                    description: charge.description || 'Stripe payment',
                    createdAt: new Date(charge.created * 1000).toISOString(),
                    paidAt: charge.status === 'succeeded' ? new Date(charge.created * 1000).toISOString() : null,
                    externalId: charge.id,
                    receiptUrl: charge.receipt_url,
                    tier: charge.metadata?.tier,
                  });
                }
              }
            }
          }
        } catch (stripeError) {
          console.error('Error fetching Stripe invoices:', stripeError);
        }
      }
      
      // Try to fetch from PayPal if configured
      const paypalClientId = process.env.PAYPAL_CLIENT_ID;
      const paypalClientSecret = process.env.PAYPAL_CLIENT_SECRET;
      if (paypalClientId && paypalClientSecret && userEmail) {
        try {
          // Get PayPal access token
          const paypalBaseUrl = getPayPalBaseUrl(paypalClientId);
          const authResponse = await fetch(`${paypalBaseUrl}/v1/oauth2/token`, {
            method: 'POST',
            headers: {
              'Authorization': `Basic ${Buffer.from(`${paypalClientId}:${paypalClientSecret}`).toString('base64')}`,
              'Content-Type': 'application/x-www-form-urlencoded'
            },
            body: 'grant_type=client_credentials'
          });
          
          const authData = await authResponse.json();
          if (authData.access_token) {
            // Search for transactions by email (PayPal Reporting API)
            const startDate = new Date();
            startDate.setFullYear(startDate.getFullYear() - 2);
            const endDate = new Date();
            
            const transactionsResponse = await fetch(
              `${paypalBaseUrl}/v1/reporting/transactions?start_date=${startDate.toISOString()}&end_date=${endDate.toISOString()}&fields=all`,
              {
                headers: {
                  'Authorization': `Bearer ${authData.access_token}`,
                  'Content-Type': 'application/json'
                }
              }
            );
            
            const transactionsData = await transactionsResponse.json();
            if (transactionsData.transaction_details) {
              for (const txn of transactionsData.transaction_details) {
                const info = txn.transaction_info || {};
                const payerEmail = txn.payer_info?.email_address;
                
                // Only include if payer email matches
                if (payerEmail && payerEmail.toLowerCase() === userEmail.toLowerCase()) {
                  if (!invoices.find(i => i.externalId === info.transaction_id)) {
                    invoices.push({
                      id: `paypal_${info.transaction_id}`,
                      amount: parseFloat(info.transaction_amount?.value || 0),
                      currency: info.transaction_amount?.currency_code || 'USD',
                      status: info.transaction_status === 'S' ? 'paid' : info.transaction_status,
                      provider: 'paypal',
                      description: info.transaction_subject || 'PayPal payment',
                      createdAt: info.transaction_initiation_date || new Date().toISOString(),
                      paidAt: info.transaction_updated_date,
                      externalId: info.transaction_id,
                    });
                  }
                }
              }
            }
          }
        } catch (paypalError) {
          console.error('Error fetching PayPal invoices:', paypalError);
        }
      }
      
      // Try to fetch from Paystack if configured
      const paystackSecretKey = process.env.PAYSTACK_SECRET_KEY;
      if (paystackSecretKey && userEmail) {
        try {
          // First find customer by email
          const customerResponse = await fetch(
            `https://api.paystack.co/customer/${encodeURIComponent(userEmail)}`,
            {
              headers: { 'Authorization': `Bearer ${paystackSecretKey}` }
            }
          );
          const customerData = await customerResponse.json();
          
          if (customerData.status && customerData.data) {
            const customerCode = customerData.data.customer_code;
            
            // Fetch transactions for this customer
            const transactionsResponse = await fetch(
              `https://api.paystack.co/transaction?customer=${customerCode}&perPage=100`,
              {
                headers: { 'Authorization': `Bearer ${paystackSecretKey}` }
              }
            );
            const transactionsData = await transactionsResponse.json();
            
            if (transactionsData.status && transactionsData.data) {
              for (const txn of transactionsData.data) {
                if (!invoices.find(i => i.externalId === txn.reference)) {
                  invoices.push({
                    id: `paystack_${txn.id}`,
                    amount: txn.amount / 100,
                    currency: txn.currency || 'NGN',
                    status: txn.status === 'success' ? 'paid' : txn.status,
                    provider: 'paystack',
                    description: txn.metadata?.description || 'Paystack payment',
                    createdAt: txn.created_at || new Date().toISOString(),
                    paidAt: txn.paid_at,
                    externalId: txn.reference,
                    tier: txn.metadata?.tier,
                  });
                }
              }
            }
          }
        } catch (paystackError) {
          console.error('Error fetching Paystack invoices:', paystackError);
        }
      }
      
      // Sort by date descending
      invoices.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      
      res.json({ success: true, invoices });
      
    } catch (error) {
      console.error('Get invoices error:', error);
      res.status(500).json({ error: error.message });
    }
  });

/**
 * Record Invoice After Payment
 * Called by webhook or after successful payment verification
 */
exports.recordInvoice = functions
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const { 
        userId, 
        amount, 
        currency, 
        provider, 
        subscriptionId, 
        externalId, 
        tier,
        description,
        receiptUrl
      } = req.body;
      
      const invoiceRef = db.collection('invoices').doc();
      await invoiceRef.set({
        id: invoiceRef.id,
        userId: userId || decodedToken.uid,
        amount,
        currency: currency || 'USD',
        status: 'paid',
        provider,
        subscriptionId,
        externalId,
        tier,
        description: description || `${tier ? tier.charAt(0).toUpperCase() + tier.slice(1) : ''} Plan Subscription`,
        receiptUrl,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      res.json({ success: true, invoiceId: invoiceRef.id });
      
    } catch (error) {
      console.error('Record invoice error:', error);
      res.status(500).json({ error: error.message });
    }
  });

// ============================================================================
// SUBSCRIPTION MANAGEMENT
// ============================================================================

/**
 * Cancel Subscription
 */
exports.cancelSubscription = functions
  .runWith({
    secrets: ['STRIPE_SECRET_KEY', 'PAYPAL_CLIENT_ID', 'PAYPAL_CLIENT_SECRET', 'PAYSTACK_SECRET_KEY'],
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onRequest(async (req, res) => {
    setCorsHeaders(req, res);
    
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }
    
    try {
      const decodedToken = await verifyAuthToken(req);
      if (!decodedToken) {
        res.status(401).json({ error: 'Unauthorized' });
        return;
      }
      
      const { subscriptionId } = req.body;
      
      // Get subscription
      const subscriptionDoc = await db.collection('subscriptions').doc(subscriptionId).get();
      if (!subscriptionDoc.exists) {
        res.status(404).json({ error: 'Subscription not found' });
        return;
      }
      
      const subscription = subscriptionDoc.data();
      
      // Verify ownership
      if (subscription.userId !== decodedToken.uid) {
        res.status(403).json({ error: 'Not authorized to cancel this subscription' });
        return;
      }
      
      // Update subscription status to cancelled
      await db.collection('subscriptions').doc(subscriptionId).update({
        status: 'cancelled',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
      
      res.json({ success: true, message: 'Subscription cancelled successfully' });
      
    } catch (error) {
      console.error('Cancel subscription error:', error);
      res.status(500).json({ error: error.message });
    }
  });
