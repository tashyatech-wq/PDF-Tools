import 'dart:typed_data';
import 'dart:ui' show Offset, Rect, Size, instantiateImageCodec;

import 'package:flutter/foundation.dart' show compute;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// All PDF work happens here, from bytes to bytes. Nothing in this file
/// touches the network — that's the whole point of the app. Every method
/// takes raw file bytes and returns raw output bytes; the UI layer is the
/// only thing that knows about file pickers or sharing.
///
/// Syncfusion's PDF engine is pure Dart with zero native/platform-channel
/// code (verified against its own package source, no FFI, no
/// MethodChannel, no android/ios folders at all) -- it's just CPU-bound,
/// and its own `async`/`await` never actually suspends. Left on the main
/// isolate that means it blocks the UI thread solid for as long as it
/// runs: no frame can be painted, so even an already-visible "working"
/// spinner freezes mid-rotation instead of looking busy. The methods below
/// that don't need pdfx's native PDF renderer (merge/split/unlock, and the
/// two plain-Syncfusion compression passes) run via `compute()` on a
/// background isolate instead, specifically so the UI isolate -- and
/// whatever progress dialog is showing -- stays alive and animating the
/// whole time. `_rasterizeVisiblePages` is the one exception: it calls
/// pdfx's native renderer over a real platform channel, which is a
/// genuine suspension point already (so it doesn't freeze anything), and
/// moving platform-channel calls to a background isolate needs explicit
/// `BackgroundIsolateBinaryMessenger` wiring this app doesn't have, so it
/// stays on the main isolate on purpose.
class PdfService {
  /// Combines several PDFs, in the given order, into one document.
  static Future<Uint8List> merge(List<Uint8List> files) =>
      compute(_mergeIsolate, files);

  static Future<Uint8List> _mergeIsolate(List<Uint8List> files) async {
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    for (final bytes in files) {
      final PdfDocument source = PdfDocument(inputBytes: bytes);
      for (int i = 0; i < source.pages.count; i++) {
        _copyPage(source.pages[i], output);
      }
      source.dispose();
    }

    final bytes = await output.save();
    output.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Extracts pages [from]..[to] (1-based, inclusive) into a new PDF.
  static Future<Uint8List> extractRange(
    Uint8List fileBytes, {
    required int from,
    required int to,
  }) => compute(_extractRangeIsolate, (fileBytes, from, to));

  static Future<Uint8List> _extractRangeIsolate(
    (Uint8List, int, int) args,
  ) async {
    final (fileBytes, from, to) = args;
    final PdfDocument source = PdfDocument(inputBytes: fileBytes);
    final PdfDocument output = PdfDocument();
    output.pageSettings.margins.all = 0;

    final start = from.clamp(1, source.pages.count);
    final end = to.clamp(start, source.pages.count);
    for (int i = start - 1; i <= end - 1; i++) {
      _copyPage(source.pages[i], output);
    }

    final bytes = await output.save();
    source.dispose();
    output.dispose();
    return Uint8List.fromList(bytes);
  }

  /// Splits every page of [fileBytes] into its own single-page PDF. Runs on
  /// a background isolate (see class doc), so there's no per-page progress
  /// callback -- a callback can't cross the isolate boundary, and a
  /// continuously-animating "Splitting..." spinner for the whole operation
  /// reads better than one that freezes between page-done updates anyway.
  static Future<List<Uint8List>> splitEveryPage(Uint8List fileBytes) =>
      compute(_splitEveryPageIsolate, fileBytes);

  static Future<List<Uint8List>> _splitEveryPageIsolate(
    Uint8List fileBytes,
  ) async {
    final PdfDocument source = PdfDocument(inputBytes: fileBytes);
    final List<Uint8List> out = [];
    final total = source.pages.count;

    for (int i = 0; i < total; i++) {
      final PdfDocument single = PdfDocument();
      single.pageSettings.margins.all = 0;
      _copyPage(source.pages[i], single);
      final bytes = await single.save();
      single.dispose();
      out.add(Uint8List.fromList(bytes));
    }

    source.dispose();
    return out;
  }

  static int pageCount(Uint8List fileBytes) {
    final PdfDocument doc = PdfDocument(inputBytes: fileBytes);
    final count = doc.pages.count;
    doc.dispose();
    return count;
  }

  /// Builds a PDF from scanned page images. This keeps scan-to-PDF reliable
  /// even on devices whose native scanner cannot export a PDF directly.
  static Future<Uint8List> imagesToPdf(List<Uint8List> images) async {
    if (images.isEmpty) {
      throw StateError('No scanned pages were returned.');
    }

    final PdfDocument output = PdfDocument();
    output.compressionLevel = PdfCompressionLevel.best;
    output.pageSettings.margins.all = 0;
    _clearDocumentInfo(output);

    try {
      for (final imageBytes in images) {
        final size = await _imageSize(imageBytes);
        output.pageSettings.size = size;
        final page = output.pages.add();
        page.graphics.drawImage(
          PdfBitmap(imageBytes),
          Rect.fromLTWH(0, 0, size.width, size.height),
        );
      }

      final bytes = await output.save();
      return Uint8List.fromList(bytes);
    } finally {
      output.dispose();
    }
  }

  /// Re-saves the document with maximum stream compression and no metadata.
  ///
  /// [PdfCompressionMode.recommended] also rebuilds pages and tries a moderate
  /// image-based pass. [PdfCompressionMode.extreme] rasterizes every page at a
  /// lower resolution/quality and rebuilds a scanned-copy PDF. That matches the
  /// behavior users expect from aggressive online compressors, but it can reduce
  /// text sharpness and removes selectable text/forms.
  static Future<PdfCompressionResult> compress(
    Uint8List fileBytes, {
    PdfCompressionMode mode = PdfCompressionMode.recommended,
    void Function(int done, int total, String step)? onProgress,
  }) async {
    // Both of these are plain Syncfusion work, so they run together on one
    // background isolate (see class doc) -- the UI isolate, and any
    // "working" dialog it's showing, stays free and animating for this
    // whole stretch instead of freezing solid. There's no real page count
    // yet at this point (this pass isn't page-by-page), so this reports
    // `total: 0` as a "just show the label, no count" marker rather than
    // claiming a fake "0 of 1"/"1 of 1".
    onProgress?.call(0, 0, 'Preparing compression…');
    final syncResults = await compute(_syncCompressIsolate, (
      fileBytes,
      mode,
    ));

    final candidates = <_CompressionCandidate>[
      _CompressionCandidate(label: 'Clean save', bytes: syncResults[0]),
      if (syncResults.length > 1)
        _CompressionCandidate(label: 'Clean rebuild', bytes: syncResults[1]),
    ];

    if (mode == PdfCompressionMode.recommended) {
      candidates.add(
        _CompressionCandidate(
          label: 'Recommended image compression',
          bytes: await _rasterizeVisiblePages(
            fileBytes,
            dpi: 120,
            jpegQuality: 72,
            onProgress: (done, total) =>
                onProgress?.call(done, total, 'Compressing page'),
          ),
        ),
      );
    }

    if (mode == PdfCompressionMode.extreme) {
      candidates.add(
        _CompressionCandidate(
          label: 'Extreme image compression',
          bytes: await _rasterizeVisiblePages(
            fileBytes,
            dpi: 92,
            jpegQuality: 52,
            onProgress: (done, total) =>
                onProgress?.call(done, total, 'Compressing page'),
          ),
        ),
      );
    }

    candidates.sort((a, b) => a.bytes.length.compareTo(b.bytes.length));
    final best = candidates.first;
    return PdfCompressionResult(
      bytes: Uint8List.fromList(best.bytes),
      originalSize: fileBytes.length,
      compressedSize: best.bytes.length,
      method: best.label,
      mode: mode,
    );
  }

  /// Runs on the background isolate `compress()` spawns: index 0 is always
  /// "Clean save", index 1 (when present) is "Clean rebuild".
  static Future<List<Uint8List>> _syncCompressIsolate(
    (Uint8List, PdfCompressionMode) args,
  ) async {
    final (fileBytes, mode) = args;
    final results = <Uint8List>[
      Uint8List.fromList(await _compressExisting(fileBytes)),
    ];
    if (mode != PdfCompressionMode.highQuality) {
      results.add(Uint8List.fromList(await _rebuildVisiblePages(fileBytes)));
    }
    return results;
  }

  static Future<List<int>> _compressExisting(Uint8List fileBytes) async {
    final PdfDocument doc = PdfDocument(inputBytes: fileBytes);
    doc.compressionLevel = PdfCompressionLevel.best;
    _clearDocumentInfo(doc);
    final bytes = await doc.save();
    doc.dispose();
    return bytes;
  }

  static Future<List<int>> _rasterizeVisiblePages(
    Uint8List fileBytes, {
    required double dpi,
    required int jpegQuality,
    void Function(int done, int total)? onProgress,
  }) async {
    final PdfDocument source = PdfDocument(inputBytes: fileBytes);
    final PdfDocument output = PdfDocument();
    output.compressionLevel = PdfCompressionLevel.best;
    output.pageSettings.margins.all = 0;
    _clearDocumentInfo(output);

    final pdfx.PdfDocument renderDoc = await pdfx.PdfDocument.openData(
      fileBytes,
    );

    try {
      final total = source.pages.count < renderDoc.pagesCount
          ? source.pages.count
          : renderDoc.pagesCount;

      for (int i = 1; i <= total; i++) {
        final PdfPage sourcePage = source.pages[i - 1];
        final pdfx.PdfPage renderPage = await renderDoc.getPage(i);
        try {
          final renderScale = dpi / 72;
          final pageImage = await renderPage.render(
            width: renderPage.width * renderScale,
            height: renderPage.height * renderScale,
            format: pdfx.PdfPageImageFormat.jpeg,
            quality: jpegQuality,
            backgroundColor: '#FFFFFF',
          );

          if (pageImage == null) {
            throw StateError('Page $i could not be rendered.');
          }

          output.pageSettings.size = sourcePage.size;
          final PdfPage outputPage = output.pages.add();
          outputPage.graphics.drawImage(
            PdfBitmap(pageImage.bytes),
            Rect.fromLTWH(0, 0, sourcePage.size.width, sourcePage.size.height),
          );
          onProgress?.call(i, total);
        } finally {
          await renderPage.close();
        }
      }

      final bytes = await output.save();
      return bytes;
    } finally {
      await renderDoc.close();
      source.dispose();
      output.dispose();
    }
  }

  static Future<List<int>> _rebuildVisiblePages(Uint8List fileBytes) async {
    final PdfDocument source = PdfDocument(inputBytes: fileBytes);
    final PdfDocument output = PdfDocument();
    output.compressionLevel = PdfCompressionLevel.best;
    output.pageSettings.margins.all = 0;
    _clearDocumentInfo(output);

    for (int i = 0; i < source.pages.count; i++) {
      _copyPage(source.pages[i], output);
    }

    final bytes = await output.save();
    source.dispose();
    output.dispose();
    return bytes;
  }

  static void _clearDocumentInfo(PdfDocument doc) {
    doc.documentInformation.author = '';
    doc.documentInformation.creator = '';
    doc.documentInformation.producer = '';
    doc.documentInformation.subject = '';
    doc.documentInformation.keywords = '';
    doc.documentInformation.title = '';
  }

  static Future<Size> _imageSize(Uint8List bytes) async {
    final codec = await instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        return Size(image.width.toDouble(), image.height.toDouble());
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  /// Removes password protection from a PDF the caller already has the
  /// password for. Throws [PdfUnlockException] on a wrong password or a
  /// format this build can't read.
  static Future<Uint8List> removePassword(
    Uint8List fileBytes,
    String password,
  ) => compute(_removePasswordIsolate, (fileBytes, password));

  static Future<Uint8List> _removePasswordIsolate(
    (Uint8List, String) args,
  ) async {
    final (fileBytes, password) = args;
    late final PdfDocument doc;
    try {
      doc = PdfDocument(inputBytes: fileBytes, password: password);
    } catch (e) {
      throw PdfUnlockException('That password did not open this PDF.');
    }
    try {
      doc.security.userPassword = '';
      doc.security.ownerPassword = '';
      final bytes = await doc.save();
      doc.dispose();
      return Uint8List.fromList(bytes);
    } catch (e) {
      doc.dispose();
      throw PdfUnlockException(
        'The password worked, but this PDF\'s protection could not be removed.',
      );
    }
  }

  /// Draws [source]'s content onto a new page of [into], preserving the
  /// source page's own size. This is Syncfusion's documented way to copy a
  /// page between documents (PdfPage.createTemplate -> PdfGraphics.drawPdfTemplate);
  /// it carries over the page's visible content, not interactive form fields
  /// or annotations on that page.
  static void _copyPage(PdfPage source, PdfDocument into) {
    into.pageSettings.size = source.size;
    final PdfPage page = into.pages.add();
    final PdfTemplate template = source.createTemplate();
    page.graphics.drawPdfTemplate(template, const Offset(0, 0));
  }
}

enum PdfCompressionMode { highQuality, recommended, extreme }

class PdfCompressionResult {
  const PdfCompressionResult({
    required this.bytes,
    required this.originalSize,
    required this.compressedSize,
    required this.method,
    required this.mode,
  });

  final Uint8List bytes;
  final int originalSize;
  final int compressedSize;
  final String method;
  final PdfCompressionMode mode;

  int get savedBytes => originalSize - compressedSize;
  bool get isSmaller => savedBytes > 0;
  double get savedPercent =>
      originalSize == 0 ? 0 : savedBytes / originalSize * 100;
}

class _CompressionCandidate {
  const _CompressionCandidate({required this.label, required this.bytes});

  final String label;
  final List<int> bytes;
}

class PdfUnlockException implements Exception {
  PdfUnlockException(this.message);
  final String message;
  @override
  String toString() => message;
}
