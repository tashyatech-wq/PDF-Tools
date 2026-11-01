import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/app_open_ad_service.dart';
import '../services/pdf_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/save_file.dart';
import '../widgets/native_tool_ad.dart';
import '../widgets/result_cards.dart';

class CompressScreen extends StatefulWidget {
  const CompressScreen({super.key});

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  String? _name;
  Uint8List? _bytes;
  PdfCompressionMode _mode = PdfCompressionMode.recommended;
  bool _working = false;
  int? _donePages;
  int? _totalPages;
  String? _workStep;
  String? _error;
  String? _successMessage;

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
    if (_bytes == null) return;
    setState(() {
      _working = true;
      _donePages = null;
      _totalPages = null;
      _workStep = 'Preparing compression';
      _error = null;
      _successMessage = null;
    });
    try {
      final result = await PdfService.compress(
        _bytes!,
        mode: _mode,
        onProgress: (done, total, step) {
          if (!mounted) return;
          setState(() {
            _donePages = done;
            _totalPages = total;
            _workStep = step;
          });
        },
      );
      final baseName = (_name ?? 'file.pdf').replaceAll(
        RegExp(r'\.pdf$', caseSensitive: false),
        '',
      );
      final outName = '$baseName-compressed.pdf';
      if (result.isSmaller) {
        await saveAndShare(result.bytes, outName);
        final msg =
            '${formatBytes(result.originalSize)} → ${formatBytes(result.compressedSize)} — ${result.savedPercent.toStringAsFixed(1)}% smaller (${result.method}). Saved in Saved.';
        setState(() => _successMessage = msg);
        InterstitialAdService.instance.showAfterExport();
      } else {
        final modeLabel = switch (_mode) {
          PdfCompressionMode.highQuality =>
            'High Quality cleaned streams and metadata',
          PdfCompressionMode.recommended =>
            'Recommended tried clean rebuild and image compression',
          PdfCompressionMode.extreme =>
            'Extreme created a lower-quality scanned copy too',
        };
        setState(
          () => _successMessage =
              '$modeLabel, but every output was larger than the original. This PDF is already optimized.',
        );
      }
    } catch (e) {
      setState(() => _error = 'Could not compress this file: $e');
    } finally {
      setState(() {
        _working = false;
        _donePages = null;
        _totalPages = null;
        _workStep = null;
      });
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
            icon: Icons.compress_rounded,
            label: _name ?? 'Choose a PDF',
            sublabel: _bytes == null
                ? 'One file at a time'
                : formatBytes(_bytes!.length),
            onTap: _pick,
          ),
          if (_bytes != null) ...[
            const SizedBox(height: 18),
            SegmentedButton<PdfCompressionMode>(
              segments: const [
                ButtonSegment(
                  value: PdfCompressionMode.highQuality,
                  label: Text('High'),
                  icon: Icon(Icons.tune_rounded),
                ),
                ButtonSegment(
                  value: PdfCompressionMode.recommended,
                  label: Text('Best'),
                  icon: Icon(Icons.verified_rounded),
                ),
                ButtonSegment(
                  value: PdfCompressionMode.extreme,
                  label: Text('Extreme'),
                  icon: Icon(Icons.auto_fix_high_rounded),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: _working
                  ? null
                  : (selection) => setState(() => _mode = selection.first),
            ),
            const SizedBox(height: 10),
            Text(
              _modeDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).hintColor,
              ),
            ),
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
                  : const Text('Compress'),
            ),
            if (_working && _workStep != null) ...[
              const SizedBox(height: 10),
              Text(
                _progressText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ],
          if (_successMessage != null) SuccessCard(message: _successMessage!),
          if (_error != null) ErrorCard(message: _error!),
          const SizedBox(height: 18),
          const NativeToolAd(),
        ],
      ),
    );
  }

  String get _modeDescription => switch (_mode) {
    PdfCompressionMode.highQuality =>
      'Safely cleans the PDF without reducing visual quality.',
    PdfCompressionMode.recommended =>
      'Best everyday choice. Tries clean rebuild plus image compression.',
    PdfCompressionMode.extreme =>
      'Smallest file. Creates a scanned copy, so text may look softer.',
  };

  String get _progressText {
    final total = _totalPages;
    final done = _donePages;
    if (done != null && total != null) {
      return '$_workStep $done of $total';
    }
    return _workStep ?? 'Compressing';
  }
}
