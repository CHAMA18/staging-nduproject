import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:ndu_project/routing/app_router.dart';
import 'package:ndu_project/services/user_preferences_service.dart';

/// Splash screen shown only on native mobile apps (iOS/Android)
/// NEVER shown on web platform
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup fade animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Navigate after splash
    _navigateAfterSplash();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateAfterSplash() async {
    // Wait for minimum splash duration (1.5 seconds)
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check if first-time user
    final isFirstTime = await UserPreferencesService.isFirstTimeUser();

    if (isFirstTime) {
      // First time user → Onboarding
      context.go('/onboarding');
    } else {
      // Returning user → Check auth status
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Authenticated → Dashboard
        context.go('/${AppRoutes.dashboard}');
      } else {
        // Not authenticated → Login
        context.go('/${AppRoutes.signIn}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFD700), // Brand yellow
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // NDU Project Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Center(
                  child: Text(
                    'NDU',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'NDUPROJECT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'INITIATE. DELIVER. ITERATE.',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
