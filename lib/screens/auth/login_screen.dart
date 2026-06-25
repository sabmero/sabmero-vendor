import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;

  Future<void> _submit() async {
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) {
      toast(context, 'Enter your phone and password.', error: true);
      return;
    }
    setState(() => _busy = true);
    final res = await ref.read(authServiceProvider).login(_phone.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.ok) {
      ref.invalidate(authStateProvider);
    } else {
      toast(context, res.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.storefront_outlined, color: AppColors.primary, size: 30),
                    SizedBox(width: 10),
                    Text('Sabmero Vendor',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Sign in to manage your shop',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 28),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
