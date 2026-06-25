import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(myProfileProvider);
    final products = ref.watch(myProductsProvider);
    final orders = ref.watch(myOrdersProvider);
    final kyc = ref.watch(kycStatusProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'Dashboard',
            subtitle: 'Your shop at a glance',
            actions: [
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(myProfileProvider);
                  ref.invalidate(myProductsProvider);
                  ref.invalidate(myOrdersProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          kyc.maybeWhen(
            data: (k) {
              final status = k?.status ?? 'NotSubmitted';
              if (status == 'Approved') return const SizedBox();
              return _kycBanner(status, k?.rejectionReason);
            },
            orElse: () => const SizedBox(),
          ),
          profile.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Could not load profile. $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (p) => p == null ? const SizedBox() : _profileCard(p),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _statCard(
                  'Products',
                  products.maybeWhen(data: (l) => l.length.toString(), orElse: () => '—'),
                  Icons.inventory_2,
                  AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Orders',
                  orders.maybeWhen(data: (l) => l.length.toString(), orElse: () => '—'),
                  Icons.receipt_long,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  'Out of stock',
                  products.maybeWhen(
                      data: (l) => l.where((p) => p.stock == 0).length.toString(),
                      orElse: () => '—'),
                  Icons.warning_amber,
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kycBanner(String status, String? reason) {
    final pending = status == 'Pending';
    final color = pending ? AppColors.warning : AppColors.danger;
    final msg = pending
        ? 'Your KYC is under review. You can set up your shop, but you cannot sell until it is approved.'
        : status == 'Rejected'
            ? 'Your KYC was rejected${(reason != null && reason.isNotEmpty) ? ': $reason' : ''}. Re-submit from the KYC page.'
            : 'You are not verified yet. Submit your KYC to start selling.';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: AppColors.text))),
        ],
      ),
    );
  }

  Widget _profileCard(VendorProfile p) {    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(24),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.store, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.businessName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                  const SizedBox(height: 4),
                  Text('${p.ownerName} • ${p.phone}',
                      style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(p.businessAddress, style: const TextStyle(color: AppColors.textMuted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(p.isApproved ? 'Approved' : 'Pending'),
                const SizedBox(height: 8),
                Text('Commission ${p.commissionRate.toStringAsFixed(1)}%',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration:
                  BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
