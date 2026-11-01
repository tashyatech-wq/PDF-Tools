import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart'
    as mlkit;

import '../services/app_open_ad_service.dart';
import '../services/interstitial_ad_service.dart';
import '../services/pdf_service.dart';
import '../services/save_file.dart';
import '../widgets/native_tool_ad.dart';
import '../widgets/result_cards.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanResult {
  const _ScanResult(this.bytes, {this.pageCount});

  final Uint8List bytes;
  final int? pageCount;
}

class _ScanScreenState extends State<ScanScreen> {
  static const MethodChannel _permissionChannel = MethodChannel(
    'pdf_tools/permissions',
  );

  bool _working = false;
  String? _error;
  SavedPdfFile? _saved;
  int? _lastPageCount;
  bool _cameraSettingsNeeded = false;

  Future<void> _scan() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
      _saved = null;
      _lastPageCount = null;
      _cameraSettingsNeeded = false;
    });

    try {
      final hasCameraPermission = await _ensureCameraPermission();
      if (!hasCameraPermission) {
        if (!mounted) return;
        setState(() {
          _working = false;
          _cameraSettingsNeeded = true;
          _error = 'Camera permission is off. Allow Camera for PDF Tools, then try Scan to PDF again.';
        });
        return;
      }

      // The scanner is a separate full-screen activity, so closing it takes
      // the app through a pause/resume cycle indistinguishable, to
      // AppOpenAdService, from the user returning from somewhere else. Left
      // unsuppressed, the resume fires a full-screen app-open ad over the
      // save-filename dialog shown right below, corrupting the widget tree.
      AppOpenAdService.instance.suppressNextResume();
      final scan = Platform.isAndroid
          ? await _scanWithAndroidFallback()
          : await _scanWithNativeScanner();
      if (!mounted) return;

      if (scan == null) {
        setState(() {
          _working = false;
          _error = null;
        });
        return;
      }

      // Returning from the scanner activity tears down and reattaches this
      // Activity's own Flutter rendering surface; that reattachment is still
      // in flight for a moment after `await` returns here. Pushing the save
      // dialog (a new Navigator route with its own animation) before it
      // settles corrupts the widget tree (a ChangeNotifier/TextEditingController
      // disposed-use crash). There's no Dart-level signal for "surface fully
      // reattached", so wait out a few real frames plus a safety margin —
      // a fixed single delay measured too short on this device.
      for (var i = 0; i < 3; i++) {
        await WidgetsBinding.instance.endOfFrame;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final filename = await _askFileName('scan-${_timestamp()}.pdf');
      if (!mounted) return;

      if (filename == null) {
        setState(() => _working = false);
        return;
      }

      final saved = await savePdfFile(scan.bytes, filename);
      await _cleanScannerCache();

      if (!mounted) return;
      setState(() {
        _saved = saved;
        _lastPageCount = scan.pageCount;
        _working = false;
      });
      InterstitialAdService.instance.showAfterExport();
    } on CunningDocumentScannerException catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _scannerErrorMessage(e);
        _cameraSettingsNeeded = e.code == 'permission_denied';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = _generalScannerError(e);
        _cameraSettingsNeeded = _isCameraPermissionError(e);
      });
    } finally {
      AppOpenAdService.instance.clearSuppression();
    }
  }

  Future<bool> _ensureCameraPermission() async {
    if (!Platform.isAndroid) return true;

    try {
      return await _permissionChannel.invokeMethod<bool>('requestCamera') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _openAppSettings() async {
    try {
      await _permissionChannel.invokeMethod<bool>('openAppSettings');
    } on PlatformException {
      // Settings is a recovery path. If Android cannot open it, keep the
      // visible error message in place and let the user retry.
    }
  }

  Future<_ScanResult?> _scanWithNativeScanner() async {
    final paths = await CunningDocumentScanner.getPictures(
      asPdf: false,
      scannerSource: ScannerSource.camera,
      androidScannerMode: AndroidScannerMode.full,
      noOfPages: 50,
    );

    if (paths == null || paths.isEmpty) return null;

    final images = <Uint8List>[];
    for (final path in paths) {
      final bytes = await File(path).readAsBytes();
      if (bytes.isNotEmpty) {
        images.add(Uint8List.fromList(bytes));
      }
    }

    if (images.isEmpty) {
      throw const CunningDocumentScannerException(
        'The scanner returned no pages.',
      );
    }

    final pdf = await PdfService.imagesToPdf(images);
    return _ScanResult(pdf, pageCount: images.length);
  }

  Future<_ScanResult?> _scanWithAndroidFallback() async {
    try {
      return await _scanWithAndroidMlKit();
    } catch (e) {
      // The real failure reason from Play Services is otherwise never seen:
      // both this call and the cunning_document_scanner fallback it leads to
      // swallow it before it reaches the UI.
      debugPrint('ML Kit document scanner unavailable, falling back: $e');
      return _scanWithNativeScanner();
    }
  }

  Future<_ScanResult?> _scanWithAndroidMlKit() async {
    final scanner = mlkit.DocumentScanner(
      options: mlkit.DocumentScannerOptions(
        documentFormats: const {
          mlkit.DocumentFormat.jpeg,
          mlkit.DocumentFormat.pdf,
        },
        mode: mlkit.ScannerMode.full,
        pageLimit: 50,
        isGalleryImport: false,
      ),
    );

    try {
      final result = await scanner.scanDocument();
      final pdf = result.pdf;
      if (pdf != null && pdf.uri.isNotEmpty) {
        final bytes = await File(pdf.uri).readAsBytes();
        if (bytes.isNotEmpty) {
          return _ScanResult(
            Uint8List.fromList(bytes),
            pageCount: pdf.pageCount,
          );
        }
      }

      final imagePaths = result.images ?? const <String>[];
      final images = <Uint8List>[];
      for (final path in imagePaths) {
        final bytes = await File(path).readAsBytes();
        if (bytes.isNotEmpty) {
          images.add(Uint8List.fromList(bytes));
        }
      }
      if (images.isEmpty) {
        throw const CunningDocumentScannerException(
          'The scanner returned no pages.',
        );
      }
      final bytes = await PdfService.imagesToPdf(images);
      return _ScanResult(bytes, pageCount: images.length);
    } on PlatformException catch (e) {
      // The native side reports a plain user cancel as an error ("Operation
      // cancelled") rather than an empty result, which would otherwise be
      // mistaken for a scanner failure and silently reopen a second,
      // different scanner (the cunning_document_scanner fallback).
      if (e.message == 'Operation cancelled') return null;
      debugPrint('ML Kit document scanner failed: ${e.code} ${e.message}');
      rethrow;
    } finally {
      await scanner.close();
    }
  }

  Future<String?> _askFileName(String defaultName) async {
    final controller = TextEditingController(text: defaultName);
    final formKey = GlobalKey<FormState>();

    final filename = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save scanned PDF'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'File name',
                hintText: 'scan.pdf',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a file name';
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(context).pop(controller.text.trim());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return filename;
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

  String _generalScannerError(Object error) {
    final message = error.toString();
    if (_isCameraPermissionError(error)) {
      return 'Camera permission is off. Allow Camera for PDF Tools, then try Scan to PDF again.';
    }
    if (Platform.isAndroid &&
        (message.contains('Failed to start document scanner') ||
            message.contains('DocumentScanner'))) {
      return 'The auto scanner is not ready on this phone. Connect to the internet, update Google Play services, then try again.';
    }
    if (message.contains('Operation cancelled')) {
      return 'Scan cancelled.';
    }
    return 'The scanner could not create a PDF. Please try again.';
  }

  bool _isCameraPermissionError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('permission') ||
        message.contains('camera') && message.contains('denied');
  }

  @override
  Widget build(BuildContext context) {
    final saved = _saved;
    final pageCount = _lastPageCount;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PickFileTile(
            icon: Icons.document_scanner_rounded,
            label: _working ? 'Opening scanner...' : 'Scan documents',
            sublabel: 'Auto capture pages to PDF',
            onTap: _scan,
          ),
          const NativeToolAd(),
          const InfoCard(
            title: 'Scan to PDF',
            body: 'Detect pages, review the scan, name the file, and save one PDF.',
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
                  'Saved ${saved.name} (${formatBytes(saved.size)})${pageCount == null ? '' : ' • $pageCount pages'} in Saved.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _shareSaved,
              icon: const Icon(Icons.ios_share_rounded),
              label: const Text('Share PDF'),
            ),
          ],
          if (_error != null) ...[
            ErrorCard(message: _error!),
            if (_cameraSettingsNeeded) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openAppSettings,
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open app settings'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
