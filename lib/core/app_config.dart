import 'package:flutter/material.dart';

class AppConfig {
  static const String baseUrl = 'https://api.sabmero.com';
  static const String apiPrefix = '/api';
}

// Vendor panel uses a blue-leaning accent to visually distinguish it from the
// admin panel (green). Same neutral surfaces.
class AppColors {
  static const Color primary = Color(0xFF14467A); // deep blue
  static const Color primaryLight = Color(0xFF2F77C0);
  static const Color bg = Color(0xFFF4F6F9);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE1E6EC);
  static const Color text = Color(0xFF1F2933);
  static const Color textMuted = Color(0xFF6B7280);

  static const Color success = Color(0xFF2F8F6F);
  static const Color warning = Color(0xFFB8881D);
  static const Color danger = Color(0xFFC0392B);
  static const Color info = Color(0xFF1D6FB8);
}

Color statusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'approved':
    case 'delivered':
    case 'completed':
    case 'verified':
    case 'paid':
    case 'active':
      return AppColors.success;
    case 'pending':
    case 'processing':
    case 'submitted':
    case 'dispatched':
      return AppColors.warning;
    case 'rejected':
    case 'cancelled':
    case 'inactive':
      return AppColors.danger;
    default:
      return AppColors.info;
  }
}
