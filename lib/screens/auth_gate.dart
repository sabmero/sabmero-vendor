import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'vendor_shell.dart';
import 'auth/login_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const LoginScreen(),
      data: (loggedIn) => loggedIn ? const VendorShell() : const LoginScreen(),
    );
  }
}
