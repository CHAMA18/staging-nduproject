# ndu_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Cloud Functions Setup

### Set Secrets

Before deploying, configure the required secrets using Firebase CLI:

```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set PAYPAL_CLIENT_ID
firebase functions:secrets:set PAYPAL_CLIENT_SECRET
firebase functions:secrets:set PAYSTACK_SECRET_KEY
```

Each command will prompt you to enter the secret value securely.

### Deploy Functions

After setting all secrets, deploy the Cloud Functions:

```bash
firebase deploy --only functions
```

---

## Payment Integration Setup

This app supports three payment providers: **Stripe**, **PayPal**, and **Paystack**. All API keys are securely stored using Firebase Secret Manager.

### 1. Stripe Setup

1. Create a Stripe account at [stripe.com](https://stripe.com)
2. Get your **Secret Key** from the Stripe Dashboard → Developers → API Keys
3. Set the secret:
   ```bash
   firebase functions:secrets:set STRIPE_SECRET_KEY
   ```
4. (Optional) Configure webhooks in Stripe Dashboard for real-time payment status updates

**Available Functions:**
- `createStripeCheckout` - Creates a Stripe Checkout session
- `verifyStripePayment` - Verifies payment completion

### 2. PayPal Setup

1. Create a PayPal Developer account at [developer.paypal.com](https://developer.paypal.com)
2. Create an app in the PayPal Dashboard to get your **Client ID** and **Client Secret**
3. Set the secrets:
   ```bash
   firebase functions:secrets:set PAYPAL_CLIENT_ID
   firebase functions:secrets:set PAYPAL_CLIENT_SECRET
   ```
4. For production, ensure you're using live credentials (not sandbox)

**Available Functions:**
- `createPayPalOrder` - Creates a PayPal order for checkout
- `verifyPayPalPayment` - Captures and verifies the PayPal payment

### 3. Paystack Setup

1. Create a Paystack account at [paystack.com](https://paystack.com)
2. Get your **Secret Key** from Paystack Dashboard → Settings → API Keys
3. Set the secret:
   ```bash
   firebase functions:secrets:set PAYSTACK_SECRET_KEY
   ```

**Available Functions:**
- `createPaystackTransaction` - Initializes a Paystack transaction
- `verifyPaystackPayment` - Verifies Paystack payment status

### 4. Coupon System

Coupons work across all payment platforms. Manage coupons via the admin dashboard at `admin.nduproject.com`.

**Available Functions:**
- `applyCoupon` - Validates and calculates discounted price
- `useCoupon` - Increments coupon usage count after payment

### 5. Invoice History

Invoices are automatically recorded after successful payments and can be viewed in the admin dashboard.

**Available Functions:**
- `getUserInvoices` - Fetches payment history from all providers
- `recordInvoice` - Manually records an invoice

### 6. Subscription Management

**Available Functions:**
- `cancelSubscription` - Cancels an active subscription

### Deployment Checklist

1. **Set all required secrets** (see commands above)
2. **Deploy Cloud Functions:**
   ```bash
   firebase deploy --only functions
   ```
3. **Update CORS origins** in `functions/index.js` to include your production domains
4. **Configure Firestore indexes** if needed for invoice/subscription queries
5. **Test each payment flow** in sandbox/test mode before going live

### Pricing Configuration

Subscription prices are defined in `functions/index.js` in the `getSubscriptionPrice()` function:

| Tier       | Monthly   | Annual     |
|------------|-----------|------------|
| Project    | $79.00    | $790.00    |
| Program    | $189.00   | $1,890.00  |
| Portfolio  | $449.00   | $4,490.00  |

To modify pricing, update the `prices` object in the function and redeploy.
