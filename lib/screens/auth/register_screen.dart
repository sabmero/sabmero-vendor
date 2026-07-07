import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_config.dart';
import '../../providers/providers.dart';
import '../../widgets/common.dart';

// Public vendor sign-up: account details + business + 3 documents
// (citizenship, NID, business). Creates a Pending request for admin review.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _DocPick {
  String? name;
  List<int>? bytes;
  String? uploadedPath;
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _address = TextEditingController();
  final _bizName = TextEditingController();
  final _bizAddress = TextEditingController();

  final _citizenship = _DocPick();
  final _nid = _DocPick();
  final _bizDoc = _DocPick();

  bool _busy = false;

  Future<void> _pick(_DocPick slot) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) {
      if (mounted) toast(context, 'Could not read the file.', error: true);
      return;
    }
    setState(() {
      slot.name = f.name;
      slot.bytes = f.bytes;
      slot.uploadedPath = null;
    });
  }

  Future<void> _submit() async {
    // Validate text fields.
    if (_fullName.text.trim().isEmpty ||
        _phone.text.trim().length != 10 ||
        _password.text.length < 6 ||
        _bizName.text.trim().isEmpty ||
        _bizAddress.text.trim().isEmpty) {
      toast(context,
          'Fill name, 10-digit phone, password (6+), business name and address.',
          error: true);
      return;
    }
    if (_citizenship.bytes == null || _nid.bytes == null || _bizDoc.bytes == null) {
      toast(context, 'All three documents are required.', error: true);
      return;
    }

    setState(() => _busy = true);
    final svc = ref.read(vendorServiceProvider);

    // Upload the three docs first.
    try {
      for (final slot in [_citizenship, _nid, _bizDoc]) {
        if (slot.uploadedPath != null) continue;
        final up = await svc.uploadDocument(slot.bytes!, slot.name!);
        if (!up.ok || up.path == null) {
          if (!mounted) return;
          setState(() => _busy = false);
          toast(context, 'Document upload failed: ${up.message}', error: true);
          return;
        }
        slot.uploadedPath = up.path;
      }

      // Register.
      final res = await svc.registerVendor(
        fullName: _fullName.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
        address: _address.text.trim(),
        businessName: _bizName.text.trim(),
        businessAddress: _bizAddress.text.trim(),
        citizenshipPath: _citizenship.uploadedPath!,
        nidPath: _nid.uploadedPath!,
        businessDocPath: _bizDoc.uploadedPath!,
      );
      if (!mounted) return;
      setState(() => _busy = false);

      if (res.ok) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Registration submitted'),
            content: const Text(
                'Your account and documents were submitted. An admin will review '
                'and approve your vendor account. You can log in once approved.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context); // back to login
      } else {
        toast(context, res.message, error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, 'Something went wrong: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Become a Vendor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 520,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Vendor registration',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.text)),
                const SizedBox(height: 4),
                const Text('Create your account and submit documents for verification.',
                    style: TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 20),

                _sectionLabel('Account'),
                _field(_fullName, 'Full name'),
                _field(_phone, 'Phone (10 digits)', keyboard: TextInputType.phone),
                _field(_email, 'Email (optional)', keyboard: TextInputType.emailAddress),
                _field(_password, 'Password (min 6)', obscure: true),
                _field(_address, 'Address'),

                const SizedBox(height: 12),
                _sectionLabel('Business'),
                _field(_bizName, 'Business name'),
                _field(_bizAddress, 'Business address'),

                const SizedBox(height: 12),
                _sectionLabel('Documents (all required — JPG, PNG or PDF)'),
                _docRow('Citizenship', _citizenship),
                _docRow('NID card', _nid),
                _docRow('Business document', _bizDoc),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Submit registration'),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Already have an account? Sign in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
      );

  Widget _field(TextEditingController c, String label,
      {bool obscure = false, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _docRow(String label, _DocPick slot) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: const TextStyle(color: AppColors.text)),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _pick(slot),
            icon: const Icon(Icons.attach_file, size: 18),
            label: const Text('Choose'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              slot.name ?? 'No file chosen',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: slot.name == null ? AppColors.textMuted : AppColors.success),
            ),
          ),
        ],
      ),
    );
  }
}
