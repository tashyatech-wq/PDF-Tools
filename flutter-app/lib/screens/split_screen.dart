import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/pdf_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/save_file.dart';
import '../widgets/result_cards.dart';

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
  double _progress = 0;
  String? _error;
  String? _successMessage;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final count = PdfService.pageCount(bytes);
    setState(() {
      _name = file.name;
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
      _progress = 0;
      _error = null;
      _successMessage = null;
    });
    try {
      if (_mode == _SplitMode.range) {
        final from = int.tryParse(_fromCtrl.text) ?? 1;
        final to = int.tryParse(_toCtrl.text) ?? _pageCount;
        final bytes = await PdfService.extractRange(
          _bytes!,
          from: from,
          to: to,
        );
        await saveAndShare(bytes, 'pages-$from-$to.pdf');
        setState(
          () => _successMessage =
              'Pages extracted — ${formatBytes(bytes.length)}',
        );
        InterstitialAdService.instance.showAfterExport();
      } else {
        final pages = await PdfService.splitEveryPage(
          _bytes!,
          onPage: (done, total) => setState(() => _progress = done / total),
        );
        for (int i = 0; i < pages.length; i++) {
          await saveAndShare(pages[i], 'page-${i + 1}.pdf');
        }
        setState(
          () =>
              _successMessage = '${pages.length} pages saved as separate files',
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
            if (_working && _mode == _SplitMode.every) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(99),
              ),
            ],
          ],
          if (_successMessage != null) SuccessCard(message: _successMessage!),
          if (_error != null) ErrorCard(message: _error!),
        ],
      ),
    );
  }
}
