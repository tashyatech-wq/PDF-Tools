import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';

import '../services/interstitial_ad_service.dart';
import '../services/save_file.dart';
import '../widgets/native_tool_ad.dart';
import '../widgets/result_cards.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _working = false;
  String? _error;
  SavedPdfFile? _saved;

  Future<void> _scan() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
      _saved = null;
    });

    try {
      final paths = await CunningDocumentScanner.getPictures(
        asPdf: true,
        scannerSource: ScannerSource.cameraAndGallery,
        androidScannerMode: AndroidScannerMode.full,
        noOfPages: 50,
      );
      if (!mounted) return;

      if (paths == null || paths.isEmpty) {
        setState(() {
          _working = false;
          _error = null;
        });
        return;
      }

      final scannedPdf = File(paths.first);
      final bytes = await scannedPdf.readAsBytes();
      if (bytes.isEmpty) {
        throw const CunningDocumentScannerException(
          'The scanner returned an empty PDF.',
        );
      }

      final saved = await savePdfFile(
        Uint8List.fromList(bytes),
        'scan-${_timestamp()}.pdf',
      );
      await _cleanScannerCache();

      if (!mounted) return;
      setState(() {
        _saved = saved;
        _working = false;
      });
      InterstitialAdService.instance.showAfterExport();
    } on CunningDocumentScannerException catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _scannerErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = 'The scanner could not create a PDF. Please try again.';
      });
    }
  }

  Future<void> _shareSaved() async {
    final saved = _saved;
    if (saved == null) return;
    await shareSavedPdf(saved);
  }

  Future<void> _cleanScannerCache() async {
    try {
      await CunningDocumentScanner.cleanCache();
    } on CunningDocumentScannerException {
      // The PDF has already been copied into app storage, so cache cleanup can
      // fail without blocking the user's saved scan.
    }
  }

  String _timestamp() {
    final raw = DateTime.now().toIso8601String();
    return raw.replaceAll(RegExp(r'[:.]'), '-');
  }

  String _scannerErrorMessage(CunningDocumentScannerException e) {
    final message = e.message.trim();
    return switch (e.code) {
      'permission_denied' => 'Camera permission is needed. Open app settings, allow Camera, then try again.',
      'ALREADY_ACTIVE' =>
        'A scan is already open. Close the scanner and try again.',
      'NO_ACTIVITY' || 'NO_CONTEXT' => 'The scanner was interrupted. Close and reopen the app, then try again.',
      'ERROR' when message.isNotEmpty => 'Scanner error: $message',
      _ when message.isNotEmpty => 'Scanner error: $message',
      _ => 'The scanner could not create a PDF. Please try again.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickFileTile(
            icon: Icons.document_scanner_rounded,
            label: _working ? 'Opening scanner...' : 'Scan documents',
            sublabel: 'Camera or gallery to PDF',
            onTap: _scan,
          ),
          const NativeToolAd(),
          const InfoCard(
            title: 'Scan to PDF',
            body: 'Capture pages, crop edges, and save one PDF in Saved files.',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _working ? null : _scan,
            icon: _working
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.camera_alt_rounded),
            label: Text(_working ? 'Opening scanner...' : 'Start scan'),
          ),
          if (saved != null) ...[
            SuccessCard(
              message:
                  'Saved ${saved.name} (${formatBytes(saved.size)}) in Saved.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _shareSaved,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share PDF'),
            ),
          ],
          if (_error != null) ErrorCard(message: _error!),
        ],
      ),
    );
  }
}
