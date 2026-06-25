import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/app_config.dart';
import '../providers/providers.dart';
import 'dashboard/dashboard_screen.dart';
import 'products/products_screen.dart';
import 'orders/orders_screen.dart';
import 'payments/payments_screen.dart';
import 'kyc/kyc_screen.dart';
import 'profile/profile_screen.dart';

class VendorShell extends ConsumerStatefulWidget {
  const VendorShell({super.key});

  @override
  ConsumerState<VendorShell> createState() => _VendorShellState();
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const _NavItem(this.label, this.icon, this.screen);
}

class _VendorShellState extends ConsumerState<VendorShell> {
  int _index = 0;

  static const _items = <_NavItem>[
    _NavItem('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
    _NavItem('My Products', Icons.inventory_2_outlined, ProductsScreen()),
    _NavItem('Orders', Icons.receipt_long_outlined, OrdersScreen()),
    _NavItem('Payments', Icons.payments_outlined, PaymentsScreen()),
    _NavItem('KYC', Icons.verified_user_outlined, KycScreen()),
    _NavItem('My Profile', Icons.store_outlined, ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final nameAsync = ref.watch(vendorNameProvider);

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 230,
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: const [
                      Icon(Icons.storefront_outlined, color: Colors.white, size: 24),
                      SizedBox(width: 10),
                      Text('Sabmero',
                          style: TextStyle(
                              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('VENDOR PANEL',
                      style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      final selected = i == _index;
                      return Material(
                        color: selected ? Colors.white.withAlpha(28) : Colors.transparent,
                        child: ListTile(
                          leading: Icon(item.icon,
                              color: selected ? Colors.white : Colors.white70, size: 20),
                          title: Text(item.label,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.white70,
                                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                  fontSize: 14)),
                          onTap: () => setState(() => _index = i),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70, size: 20),
                  title: const Text('Sign out', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  onTap: () async {
                    await ref.read(authServiceProvider).logout();
                    ref.invalidate(authStateProvider);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 60,
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(_items[_index].label,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
                      const Spacer(),
                      const Icon(Icons.account_circle_outlined, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      nameAsync.maybeWhen(
                        data: (n) => Text(n, style: const TextStyle(color: AppColors.text)),
                        orElse: () => const Text('Vendor'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                Expanded(
                  child: Container(
                    color: AppColors.bg,
                    padding: const EdgeInsets.all(24),
                    child: _items[_index].screen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
