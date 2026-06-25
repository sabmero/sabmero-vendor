import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  void _refresh(WidgetRef ref) => ref.invalidate(pendingPaymentsProvider);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingPaymentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Payments',
          subtitle: 'QR payments awaiting your verification',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _refresh(ref),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: AsyncListView<PendingPayment>(
            value: async,
            onRetry: () => _refresh(ref),
            emptyText: 'No payments waiting for verification.',
            builder: (rows) => SingleChildScrollView(
              child: TableCard(
                columns: const [
                  DataColumn(label: Text('Ref')),
                  DataColumn(label: Text('Customer')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Method')),
                  DataColumn(label: Text('Proof')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: rows.map((p) => _row(context, ref, p)).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _row(BuildContext context, WidgetRef ref, PendingPayment p) {
    return DataRow(cells: [
      DataCell(Text('#${p.reference}')),
      DataCell(Text(p.customerName ?? '—')),
      DataCell(Text('Rs ${p.amount.toStringAsFixed(0)}')),
      DataCell(Text(p.method)),
      DataCell((p.screenshotPath == null || p.screenshotPath!.isEmpty)
          ? const Text('—')
          : TextButton.icon(
              icon: const Icon(Icons.image, size: 16),
              label: const Text('View'),
              onPressed: () => _viewProof(context, p.screenshotPath!),
            )),
      DataCell(StatusBadge(p.status)),
      DataCell(Row(children: [
        _btn('Approve', AppColors.success, () => _verify(context, ref, p, true)),
        const SizedBox(width: 6),
        _btn('Reject', AppColors.danger, () => _verify(context, ref, p, false)),
      ])),
    ]);
  }

  Widget _btn(String label, Color color, VoidCallback onTap) => OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withAlpha(120)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: const Size(0, 32),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );

  void _viewProof(BuildContext context, String path) {
    final url = path.startsWith('http') ? path : '${AppConfig.baseUrl}$path';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment proof'),
        content: SizedBox(
          width: 400,
          child: Image.network(url,
              errorBuilder: (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Could not load image.'),
                  )),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _verify(BuildContext context, WidgetRef ref, PendingPayment p, bool approve) async {
    final ok = await confirm(
      context,
      approve ? 'Approve payment?' : 'Reject payment?',
      'Reference #${p.reference} • Rs ${p.amount.toStringAsFixed(0)}',
    );
    if (!ok) return;
    final res = await ref.read(vendorServiceProvider).verifyPayment(p.id, approve);
    if (!context.mounted) return;
    toast(context, res.ok ? (approve ? 'Approved' : 'Rejected') : (res.message ?? 'Failed'),
        error: !res.ok);
    if (res.ok) _refresh(ref);
  }
}
