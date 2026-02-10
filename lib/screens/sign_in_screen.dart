import 'package:flutter/material.dart';
import 'package:ndu_project/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ndu_project/services/firebase_auth_service.dart';
import 'package:ndu_project/services/access_policy.dart';
import 'package:ndu_project/screens/create_account_screen.dart';
import 'package:ndu_project/widgets/app_logo.dart';
import 'package:ndu_project/widgets/responsive.dart';
import 'package:ndu_project/widgets/elevated_auth_container.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/subscription_service.dart'; // Added

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMePreference();
  }

  Future<void> _loadRememberMePreference() async {
    final rememberMe = await FirebaseAuthService.getRememberMe();
    if (mounted) {
      setState(() => _rememberMe = rememberMe);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isMobileViewport(context)) {
      await _showDeviceRestrictionDialog();
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuthService.signInWithGoogle();
      if (!mounted) return;
      _showSnack('Signed in with Google', Colors.green);
      _navigateAfterSignIn();
    } catch (e) {
      _showSnack('Google sign-in failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailSignIn() async {
    if (_isMobileViewport(context)) {
      await _showDeviceRestrictionDialog();
      return;
    }
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnack('Please fill in all fields', Colors.red);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuthService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );
      if (!mounted) return;
      final user = cred.user;
      await user?.reload();
      if (!mounted) return;
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null &&
          (refreshed.emailVerified || _isGoogleProvider(refreshed))) {
        _navigateAfterSignIn();
      } else {
        await _showVerifyEmailDialog(
            refreshed?.email ?? _emailController.text.trim());
        // Keep user on sign-in; optionally sign out to prevent accidental access
        try {
          await FirebaseAuthService.signOut();
        } catch (_) {}
      }
    } catch (e) {
      _showSnack('Sign in failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isGoogleProvider(User user) {
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  void _navigateAfterSignIn() {
    if (!mounted) return;
    if (_shouldDeferToAuthWrapper()) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      String target;
      final isAdminHost = AccessPolicy.isRestrictedAdminHost();

      if (isAdminHost) {
        target = '/${AppRoutes.adminHome}';
      } else {
        // Check for active subscription (including trials)
        try {
          final hasSubscription =
              await SubscriptionService.hasActiveSubscription();
          if (hasSubscription) {
            target = '/${AppRoutes.dashboard}';
          } else {
            target = '/${AppRoutes.pricing}';
          }
        } catch (e) {
          debugPrint('Error checking subscription on sign in: $e');
          // Fallback to pricing if check fails
          target = '/${AppRoutes.pricing}';
        }
      }

      if (!mounted) return;
      context.go(target);
    });
  }

  bool _shouldDeferToAuthWrapper() {
    try {
      final path = GoRouterState.of(context).uri.path;
      return path.startsWith('/${AppRoutes.adminPortal}') ||
          path.startsWith('/admin-');
    } catch (_) {
      return false;
    }
  }

  Future<void> _showVerifyEmailDialog(String email) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verify your email'),
        content: Text(
            'We\'ve sent a verification link to\n$email. Please verify your email, then come back and sign in.'),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.currentUser
                    ?.sendEmailVerification();
                if (mounted) {
                  _showSnack('Verification email sent', Colors.green);
                }
              } catch (e) {
                if (mounted) _showSnack('Failed to resend: $e', Colors.red);
              }
            },
            child: const Text('Resend'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _isMobileViewport(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;
    return shortestSide < 600;
  }

  Future<void> _showDeviceRestrictionDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Device Not Supported'),
        content: const Text(
            'Use either a Tablet/Desktop for the best experience possible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryText = Color(0xFF1F2933);
    const secondaryText = Color(0xFF616E7C);
    const fieldBorder = Color(0xFFD2D6DC);
    const dividerColor = Color(0xFFCBD2D9);
    const headlineAccent = LightModeColors.accent;

    InputDecoration fieldDecoration(String hint, {Widget? suffix}) {
      final borderShape = BorderRadius.circular(12);
      return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: secondaryText.withValues(alpha: 0.6), fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: borderShape,
          borderSide: const BorderSide(color: fieldBorder, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderShape,
          borderSide: const BorderSide(color: fieldBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderShape,
          borderSide: const BorderSide(color: headlineAccent, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        suffixIcon: suffix,
      );
    }

    // Responsive sizes
    final bool isTablet = AppBreakpoints.isTablet(context);
    final bool isDesktop = AppBreakpoints.isDesktop(context);
    final double maxContentWidth = isDesktop ? 480 : (isTablet ? 440 : 400);
    final EdgeInsets pagePadding = EdgeInsets.symmetric(
      horizontal: AppBreakpoints.pagePadding(context),
      vertical: 32,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: pagePadding,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(child: AppLogo(height: 320)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedAuthContainer(
                  maxWidth: maxContentWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Google sign-in button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: Image.asset('assets/images/search.png',
                              height: 20, width: 20),
                          label: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        primaryText),
                                  ),
                                )
                              : const Text(
                                  'Log in with Google',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: primaryText,
                                      fontWeight: FontWeight.w600),
                                ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: fieldBorder, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(
                              child:
                                  Divider(color: dividerColor, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text('OR',
                                style: TextStyle(
                                    color: secondaryText, fontSize: 13)),
                          ),
                          const Expanded(
                              child:
                                  Divider(color: dividerColor, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      const Text('Email',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryText)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 54,
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15),
                          decoration: fieldDecoration('jane.joe@gmail.com'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('Password',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryText)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 54,
                        child: TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(fontSize: 15),
                          decoration: fieldDecoration(
                            '**********',
                            suffix: IconButton(
                              icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: secondaryText),
                              onPressed: () => setState(() =>
                                  _isPasswordVisible = !_isPasswordVisible),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) => setState(
                                      () => _rememberMe = value ?? false),
                                  activeColor: headlineAccent,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Remember Me',
                                style: TextStyle(
                                    color: secondaryText, fontSize: 13),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () async {
                              final email = _emailController.text.trim();
                              if (email.isEmpty) {
                                _showSnack('Enter your email to reset password',
                                    Colors.red);
                                return;
                              }
                              setState(() => _isLoading = true);
                              try {
                                await FirebaseAuthService
                                    .sendPasswordResetEmail(email);
                                _showSnack('Password reset link sent to $email',
                                    Colors.green);
                              } catch (e) {
                                _showSnack('Failed to send reset email: $e',
                                    Colors.red);
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LightModeColors.accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Sign In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CreateAccountScreen()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(color: secondaryText, fontSize: 13),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          const TextSpan(
                            text: 'Create Account',
                            style: TextStyle(
                                color: headlineAccent,
                                decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
