import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';


/// Tracks the last visited dashboard context for both client and admin
/// surfaces, so clicking the brand logo can take the user to the most
/// relevant dashboard without hard-coding per-screen logic.
class NavigationContextService {
  NavigationContextService._();
  static final NavigationContextService instance = NavigationContextService._();

  String? _lastClientDashboardRouteName; // project/program/portfolio
  String? _lastAdminDashboardRouteName; // admin-* routes

  void setLastClientDashboard(String routeName) {
    _lastClientDashboardRouteName = routeName;
    if (kDebugMode) debugPrint('NavigationContextService: last client dashboard -> $routeName');
  }

  void setLastAdminDashboard(String routeName) {
    _lastAdminDashboardRouteName = routeName;
    if (kDebugMode) debugPrint('NavigationContextService: last admin dashboard -> $routeName');
  }

  /// Navigates to the dashboard when the logo is tapped.
  /// Provides consistent behavior across all screens.
  void navigateFromLogo(BuildContext context) {
    try {
      if (kDebugMode) debugPrint('Logo tap -> navigating to dashboard');
      // Navigate to dashboard instead of landing page
      context.go('/dashboard');
    } catch (e, st) {
      debugPrint('NavigationContextService.navigateFromLogo error: $e\n$st');
    }
  }
}
