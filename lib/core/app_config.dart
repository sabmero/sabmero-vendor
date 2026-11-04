import 'package:flutter/material.dart';

class AppConfig {
  static const String baseUrl = 'https://api.sabmero.com';
  static const String apiPrefix = '/api';
}

// Same look as the admin panel (deep green).
class AppColors {
  static const Color primary = Color(0xFF0B3D2E); // deep green (matches brand)
  static const Color primaryLight = Color(0xFF2F8F6F);
  static const Color bg = Color(0xFFF5F7F6);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE1E8E5);
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
