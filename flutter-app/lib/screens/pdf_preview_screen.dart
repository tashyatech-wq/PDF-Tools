import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../services/save_file.dart';
import '../widgets/ad_mob_banner.dart';

class PdfPreviewScreen extends StatefulWidget {
  const PdfPreviewScreen({super.key, required this.file});

  final SavedPdfFile file;

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  late final PdfController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PdfController(
      document: PdfDocument.openFile(widget.file.path),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () => shareSavedPdf(widget.file),
          ),
        ],
      ),
      body: PdfView(controller: _controller),
      bottomNavigationBar: const AdMobBanner(),
    );
  }
}
