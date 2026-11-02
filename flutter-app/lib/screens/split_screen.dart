import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/app_open_ad_service.dart';
import '../services/pdf_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/save_file.dart';
import '../widgets/busy_dialog.dart';
import '../widgets/native_tool_ad.dart';
import '../widgets/result_cards.dart';
import '../widgets/saved_files_picker.dart';

enum _SplitMode { range, every }

class SplitScreen extends StatefulWidget {
  const SplitScreen({super.key});

  @override
  State<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends State<SplitScreen> {
  String? _name;
  Uint8List? _bytes;
  int _pageCount = 0;
  _SplitMode _mode = _SplitMode.range;
  final _fromCtrl = TextEditingController(text: '1');
  final _toCtrl = TextEditingController(text: '1');

  bool _working = false;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
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
    _applyPicked(file.name, bytes);
  }

  Future<void> _pickFromSaved() async {
    final picked = await pickFromSavedFiles(context, allowMultiple: false);
    if (picked == null || picked.isEmpty || !mounted) return;
    final file = picked.first;
    final bytes = await File(file.path).readAsBytes();
    _applyPicked(file.name, bytes);
  }

  void _applyPicked(String name, Uint8List bytes) {
    final count = PdfService.pageCount(bytes);
    setState(() {
      _name = name;
      _bytes = bytes;
      _pageCount = count;
      _fromCtrl.text = '1';
      _toCtrl.text = '$count';
      _error = null;
      _successMessage = null;
    });
  }

  Future<void> _run() async {
    if (_bytes == null) return;
    setState(() {
      _working = true;
      _error = null;
      _successMessage = null;
    });
    try {
      if (_mode == _SplitMode.range) {
        final from = int.tryParse(_fromCtrl.text) ?? 1;
        final to = int.tryParse(_toCtrl.text) ?? _pageCount;
        final bytes = await runBusy<Uint8List>(
          context,
          message: 'Extracting pages…',
          action: (_) => PdfService.extractRange(_bytes!, from: from, to: to),
        );
        if (!mounted) return;
        await runBusy<void>(
          context,
          message: 'Saving…',
          action: (_) => saveAndExport(bytes, 'pages-$from-$to.pdf'),
        );
        setState(
          () => _successMessage =
              'Pages extracted — ${formatBytes(bytes.length)}. Saved in Saved.',
        );
        InterstitialAdService.instance.showAfterExport();
      } else {
        final pages = await runBusy<List<Uint8List>>(
          context,
          message: 'Splitting pages…',
          action: (_) => PdfService.splitEveryPage(_bytes!),
        );
        // One "Save As" dialog per page would mean N confirmations in a
        // row for an N-page PDF -- these stay in the app's own library
        // instead; the Saved tab's Share button covers sending them on.
        if (!mounted) return;
        await runBusy<void>(
          context,
          message: 'Saving pages…',
          action: (busy) async {
            for (int i = 0; i < pages.length; i++) {
              busy.value = 'Saving page ${i + 1} of ${pages.length}';
              await savePdfFile(pages[i], 'page-${i + 1}.pdf');
            }
          },
        );
        setState(
          () => _successMessage =
              '${pages.length} pages saved as separate files in Saved.',
        );
        InterstitialAdService.instance.showAfterExport();
      }
    } catch (e) {
      setState(() => _error = 'Could not split this file: $e');
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
            icon: Icons.call_split_rounded,
            label: _name ?? 'Choose a PDF',
            sublabel: _name == null
                ? 'One file at a time'
                : '$_pageCount pages',
            onTap: _pick,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickFromSaved,
            icon: const Icon(Icons.folder_rounded, size: 18),
            label: const Text('Choose from Saved Files'),
          ),
          if (_bytes != null) ...[
            const SizedBox(height: 18),
            SegmentedButton<_SplitMode>(
              segments: const [
                ButtonSegment(
                  value: _SplitMode.range,
                  label: Text('Page range'),
                ),
                ButtonSegment(
                  value: _SplitMode.every,
                  label: Text('Every page'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            if (_mode == _SplitMode.range) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'From page',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _toCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'To page',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
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
                  : Text(
                      _mode == _SplitMode.range
                          ? 'Extract pages'
                          : 'Split every page',
                    ),
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
