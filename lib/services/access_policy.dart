import 'package:flutter/foundation.dart';

/// Centralized access policy for host/email based restrictions.
class AccessPolicy {
  /// Returns the current host for web; empty string on non-web platforms.
  static String currentHost() {
    try {
      return Uri.base.host.toLowerCase();
    } catch (_) {
      return '';
    }
  }

  /// Whether the current host is the restricted admin domain.
  static bool isRestrictedAdminHost() {
    if (!kIsWeb) return false;
    final host = currentHost();
    return host == 'admin.nduproject.com';
  }

  /// Whether the provided email is allowed to access when on the admin host.
  /// Updated: Allow all emails without domain restrictions.
  static bool isEmailAllowedForAdmin(String? email) {
    // Previously restricted to @nduproject.com and a specific Gmail address.
    // Requirement change: include all emails regardless of domain.
    return (email != null && email.isNotEmpty);
  }
}
