import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'My Profile',
          subtitle: 'Your vendor account details',
          actions: [
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(myProfileProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('Could not load profile. $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (p) => p == null
                ? const Center(child: Text('No profile found.'))
                : SingleChildScrollView(child: _detail(p)),
          ),
        ),
      ],
    );
  }

  Widget _detail(VendorProfile p) {
    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: LayoutBuilder(
            builder: (context, c) {
              final labelWidget = Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontWeight: FontWeight.w500));
              final valueWidget =
                  Text(value, style: const TextStyle(color: AppColors.text));

              // On narrow screens stack the label above the value.
              if (c.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelWidget,
                    const SizedBox(height: 2),
                    valueWidget,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 180, child: labelWidget),
                  Expanded(child: valueWidget),
                ],
              );
            },
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: Text(p.businessName,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.text)),
                ),
                StatusBadge(p.isApproved ? 'Approved' : 'Pending'),
              ],
            ),
            const Divider(height: 32),
            row('Owner', p.ownerName),
            row('Phone', p.phone),
            row('Business address', p.businessAddress),
            row('Commission rate', '${p.commissionRate.toStringAsFixed(1)}%'),
            row('Products listed', '${p.productCount}'),
            row('Member since', p.createdAt.split('T').first),
            const SizedBox(height: 12),
            const Text(
              'To change your business details, contact an admin.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
