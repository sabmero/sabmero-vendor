import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  bool _busy = false;
  String? _pickedName;
  List<int>? _pickedBytes;
  String? _uploadedPath; // path returned by the upload endpoint, before submit

  void _refresh() => ref.invalidate(kycStatusProvider);

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // needed on web to get bytes
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) {
      if (mounted) toast(context, 'Could not read the file.', error: true);
      return;
    }
    setState(() {
      _pickedName = f.name;
      _pickedBytes = f.bytes;
      _uploadedPath = null;
    });
  }

  Future<void> _uploadAndSubmit() async {
    if (_pickedBytes == null || _pickedName == null) {
      toast(context, 'Pick a document first.', error: true);
      return;
    }
    setState(() => _busy = true);
    final svc = ref.read(vendorServiceProvider);

    // 1) upload the file → path
    final up = await svc.uploadKycFile(_pickedBytes!, _pickedName!);
    if (!up.ok || up.path == null) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, up.message, error: true);
      return;
    }

    // 2) submit the path for review
    final res = await svc.submitKyc(up.path!);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _uploadedPath = up.path;
      _pickedBytes = null;
      _pickedName = null;
    });
    toast(context, res.ok ? (res.message ?? 'KYC submitted') : (res.message ?? 'Failed'),
        error: !res.ok);
    if (res.ok) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(kycStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'KYC Verification',
          subtitle: 'Verify your identity to start selling',
          actions: [
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('Could not load KYC status. $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (k) => SingleChildScrollView(child: _body(k)),
          ),
        ),
      ],
    );
  }

  Widget _body(KycStatus? k) {
    final status = k?.status ?? 'NotSubmitted';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statusCard(k, status),
        const SizedBox(height: 16),
        // Upload UI: shown unless already approved.
        if (status != 'Approved') _uploadCard(status),
      ],
    );
  }

  Widget _statusCard(KycStatus? k, String status) {
    String headline;
    String detail;
    IconData icon;
    switch (status) {
      case 'Approved':
        headline = 'Verified';
        detail = 'Your KYC is approved. You can sell on the platform.';
        icon = Icons.verified;
        break;
      case 'Pending':
        headline = 'Under review';
        detail = 'Your document was submitted and is waiting for admin review.';
        icon = Icons.hourglass_top;
        break;
      case 'Rejected':
        headline = 'Rejected';
        detail = (k?.rejectionReason == null || k!.rejectionReason!.isEmpty)
            ? 'Your KYC was rejected. Please re-submit a clearer document.'
            : 'Reason: ${k.rejectionReason}';
        icon = Icons.cancel;
        break;
      default:
        headline = 'Not submitted';
        detail = 'Upload a government ID or business document to get verified.';
        icon = Icons.badge_outlined;
    }
    final c = statusColor(status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(color: c.withAlpha(28), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: c, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(headline,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
                    const SizedBox(width: 12),
                    StatusBadge(status),
                  ]),
                  const SizedBox(height: 6),
                  Text(detail, style: const TextStyle(color: AppColors.textMuted)),
                  if (k?.documentPath != null && k!.documentPath!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.description, size: 16),
                      label: const Text('View submitted document'),
                      onPressed: () => _viewDoc(k.documentPath!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadCard(String status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status == 'Rejected' ? 'Re-submit your document' : 'Submit your document',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.text)),
            const SizedBox(height: 4),
            const Text('Accepted: JPG, PNG, or PDF.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Choose file'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _pickedName ?? (_uploadedPath != null ? 'Submitted ✓' : 'No file chosen'),
                    style: const TextStyle(color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: (_busy || _pickedBytes == null) ? null : _uploadAndSubmit,
              icon: _busy
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload),
              label: Text(_busy ? 'Submitting…' : 'Upload & submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewDoc(String path) {
    final url = path.startsWith('http') ? path : '${AppConfig.baseUrl}$path';
    final isPdf = url.toLowerCase().endsWith('.pdf');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submitted document'),
        content: SizedBox(
          width: 420,
          child: isPdf
              ? Text('PDF document:\n$url')
              : Image.network(url,
                  errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Could not load image.'),
                      )),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }
}
