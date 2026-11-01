import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/app_open_ad_service.dart';
import '../services/pdf_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/save_file.dart';
import '../widgets/native_tool_ad.dart';
import '../widgets/result_cards.dart';

/// Unlike the web prototype (pdf-lib cannot decrypt real PDF encryption),
/// this screen is fully functional: Syncfusion's PdfDocument genuinely
/// supports loading an encrypted PDF with its password and re-saving it
/// without protection. See PdfService.removePassword.
class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  String? _name;
  Uint8List? _bytes;
  final _passwordCtrl = TextEditingController();
  bool _working = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    // See the matching comment in merge_screen.dart: suppress the
    // app-open ad across the file picker round-trip so it doesn't fire
    // over this screen the instant the picker closes.
    AppOpenAdService.instance.suppressNextResume();
    final PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } finally {
      AppOpenAdService.instance.clearSuppression();
    }
    if (picked == null) return;
    final file = picked;
    final bytes = await file.readAsBytes();
    setState(() {
      _name = file.name;
      _bytes = bytes;
      _error = null;
      _successMessage = null;
    });
  }

  Future<void> _run() async {
    if (_bytes == null || _passwordCtrl.text.isEmpty) return;
    setState(() {
      _working = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final out = await PdfService.removePassword(_bytes!, _passwordCtrl.text);
      final baseName = (_name ?? 'file.pdf').replaceAll(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );
      final outName = '$baseName-unlocked.pdf';
      await saveAndShare(out, outName);
      setState(
        () => _successMessage =
            'Password removed — ${formatBytes(out.length)}. Saved in Saved.',
      );
      InterstitialAdService.instance.showAfterExport();
    } on PdfUnlockException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not process this file: $e');
    } finally {
      setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickFileTile(
            icon: Icons.lock_open_rounded,
            label: _name ?? 'Choose a PDF',
            sublabel: _bytes == null
                ? 'One file at a time'
                : formatBytes(_bytes!.length),
            onTap: _pick,
          ),
          if (_bytes != null) ...[
            const SizedBox(height: 18),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Current password",
                hintText: "Enter the PDF's password",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _working ? null : _run,
              child: _working
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Remove password'),
            ),
          ],
          if (_successMessage != null) SuccessCard(message: _successMessage!),
          if (_error != null) ErrorCard(message: _error!),
          const SizedBox(height: 18),
          const NativeToolAd(),
        ],
      ),
    );
  }
}
