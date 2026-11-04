import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/app_config.dart';
import '../../widgets/common.dart';

// ── Models ───────────────────────────────────────────────────────────────────
double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
int _i(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

class EarningPayment {
  final int id;
  final double amount;
  final String status, createdAt;
  final String? note, screenshotPath;
  EarningPayment.fromJson(Map<String, dynamic> j)
      : id = _i(j['id']),
        amount = _d(j['amount']),
        status = '${j['status'] ?? 'Paid'}',
        createdAt = '${j['createdAt'] ?? ''}',
        note = j['note']?.toString(),
        screenshotPath = j['screenshotPath']?.toString();
}

class Earnings {
  final double totalReceived;
  final String? qrPath;
  final List<EarningPayment> payments;
  Earnings(this.totalReceived, this.qrPath, this.payments);
  int get pending => payments.where((p) => p.status == 'Paid').length;
}

final earningsProvider = FutureProvider.autoDispose<Earnings>((ref) async {
  final res = await ApiClient.instance.get('/vendor-payments/mine');
  final m = res.data is Map
      ? Map<String, dynamic>.from(res.data as Map)
      : <String, dynamic>{};
  final list = (m['payments'] is List ? m['payments'] as List : const [])
      .whereType<Map>()
      .map((e) => EarningPayment.fromJson(Map<String, dynamic>.from(e)))
      .toList();
  final qr = m['paymentQrPath']?.toString();
  return Earnings(_d(m['totalReceived']),
      (qr == null || qr.isEmpty) ? null : qr, list);
});

String _full(String p) => p.startsWith('http') ? p : '${AppConfig.baseUrl}$p';

String _date(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return iso;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

/// What SabMero paid this vendor: total, history, "Confirm received",
/// and the vendor's own payout QR.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  void _refresh(WidgetRef ref) => ref.invalidate(earningsProvider);

  Future<void> _confirm(BuildContext context, WidgetRef ref, EarningPayment p) async {
    final res = await ApiClient.instance.post('/vendor-payments/${p.id}/acknowledge');
    if (!context.mounted) return;
    toast(context, res.message ?? (res.ok ? 'Confirmed' : 'Failed'), error: !res.ok);
    _refresh(ref);
  }

  Future<void> _setQr(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final file = picked?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    final up = await ApiClient.instance.uploadBytes('/Uploads/payment', file.bytes!, file.name);
    final path = up.data is Map ? (up.data as Map)['path']?.toString() : null;
    if (!up.ok || path == null || path.isEmpty) {
      if (context.mounted) toast(context, up.message ?? 'Upload failed.', error: true);
      return;
    }
    final res = await ApiClient.instance.put('/vendor-payments/my-qr', body: {'qrImagePath': path});
    if (!context.mounted) return;
    toast(context, res.message ?? (res.ok ? 'QR saved' : 'Failed'), error: !res.ok);
    _refresh(ref);
  }

  void _view(BuildContext context, String path) => showDialog(
        context: context,
        builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(_full(path)))),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(earningsProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            'My Earnings',
            subtitle: 'Payments SabMero sent you, and your payout QR',
            actions: [
              OutlinedButton.icon(
                onPressed: () => _refresh(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          async.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Text('Failed to load: $e'),
            data: (e) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(spacing: 12, runSpacing: 12, children: [
                  _stat('Total received', 'Rs ${e.totalReceived.toStringAsFixed(0)}', AppColors.success),
                  if (e.pending > 0)
                    _stat('Waiting for your confirmation', '${e.pending}', AppColors.warning),
                ]),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('My payout QR',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        const Text('SabMero pays you by scanning this QR.',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        if (e.qrPath != null)
                          Image.network(_full(e.qrPath!), height: 180,
                              errorBuilder: (_, __, ___) => const Text('QR image could not be loaded.'))
                        else
                          const Text('No QR added yet.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _setQr(context, ref),
                          icon: const Icon(Icons.qr_code_2),
                          label: Text(e.qrPath == null ? 'Add my QR' : 'Change my QR'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                e.payments.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No payments yet.')),
                        ),
                      )
                    : TableCard(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Amount')),
                          DataColumn(label: Text('Note')),
                          DataColumn(label: Text('Proof')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Action')),
                        ],
                        rows: e.payments
                            .map((p) => DataRow(cells: [
                                  DataCell(Text(_date(p.createdAt))),
                                  DataCell(Text('Rs ${p.amount.toStringAsFixed(0)}')),
                                  DataCell(SizedBox(
                                      width: 180,
                                      child: Text(p.note ?? '—', overflow: TextOverflow.ellipsis))),
                                  DataCell((p.screenshotPath == null || p.screenshotPath!.isEmpty)
                                      ? const Text('—')
                                      : TextButton.icon(
                                          icon: const Icon(Icons.image, size: 16),
                                          label: const Text('View'),
                                          onPressed: () => _view(context, p.screenshotPath!),
                                        )),
                                  DataCell(StatusBadge(p.status)),
                                  DataCell(p.status == 'Acknowledged'
                                      ? const Text('Received ✓')
                                      : FilledButton(
                                          onPressed: () => _confirm(context, ref, p),
                                          child: const Text('Confirm received'),
                                        )),
                                ]))
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: color)),
          ],
        ),
      );
}
