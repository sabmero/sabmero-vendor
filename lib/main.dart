import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'screens/auth_gate.dart';

void main() {
  runApp(const ProviderScope(child: SabmeroVendorApp()));
}

class SabmeroVendorApp extends StatelessWidget {
  const SabmeroVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabmero Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
