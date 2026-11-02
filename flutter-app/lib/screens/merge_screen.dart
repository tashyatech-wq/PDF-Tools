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

class _PickedFile {
  _PickedFile(this.name, this.size, this.bytes);
  final String name;
  final int size;
  final Uint8List bytes;
}

class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key});

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  final List<_PickedFile> _files = [];
  bool _working = false;
  String? _error;
  String? _successMessage;

  Future<void> _addFiles() async {
    // The file picker is a separate activity, so returning from it takes
    // the app through a pause/resume cycle indistinguishable, to
    // AppOpenAdService, from the user returning from somewhere else. Left
    // unsuppressed, the resume fires a full-screen app-open ad that bumps
    // the user off this screen right as they come back.
    AppOpenAdService.instance.suppressNextResume();
    final List<PlatformFile> picked;
    try {
      // file_picker 13.x: pickFiles() always multi-selects and returns the
      // list directly (empty, never null, if the user cancels).
      picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } finally {
      AppOpenAdService.instance.clearSuppression();
    }
    if (picked.isEmpty) return;
    final loaded = <_PickedFile>[];
    for (final f in picked) {
      final bytes = await f.readAsBytes();
      loaded.add(_PickedFile(f.name, bytes.length, bytes));
    }
    setState(() {
      _error = null;
      _successMessage = null;
      _files.addAll(loaded);
    });
  }

  Future<void> _addFromSaved() async {
    final picked = await pickFromSavedFiles(context, allowMultiple: true);
    if (picked == null || picked.isEmpty || !mounted) return;
    final loaded = <_PickedFile>[];
    for (final f in picked) {
      final bytes = await File(f.path).readAsBytes();
      loaded.add(_PickedFile(f.name, bytes.length, bytes));
    }
    setState(() {
      _error = null;
      _successMessage = null;
      _files.addAll(loaded);
    });
  }

  void _move(int index, int delta) {
    final j = index + delta;
    if (j < 0 || j >= _files.length) return;
    setState(() {
      final tmp = _files[index];
      _files[index] = _files[j];
      _files[j] = tmp;
    });
  }

  Future<void> _merge() async {
    setState(() {
      _working = true;
      _error = null;
      _successMessage = null;
    });
    try {
      final bytes = await runBusy<Uint8List>(
        context,
        message: 'Merging files…',
        action: (_) => PdfService.merge(_files.map((f) => f.bytes).toList()),
      );
      if (!mounted) return;
      await runBusy<void>(
        context,
        message: 'Saving…',
        action: (_) => saveAndExport(bytes, 'merged.pdf'),
      );
      setState(
        () => _successMessage =
            'Merged into one PDF — ${formatBytes(bytes.length)}. Saved in Saved.',
      );
      InterstitialAdService.instance.showAfterExport();
    } catch (e) {
      setState(() => _error = 'Could not merge these files: $e');
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
            icon: Icons.content_copy_rounded,
            label: 'Add PDFs',
            sublabel: 'PDF only',
            onTap: _addFiles,
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _addFromSaved,
            icon: const Icon(Icons.folder_rounded, size: 18),
            label: const Text('Choose from Saved Files'),
          ),
          if (_files.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...List.generate(_files.length, (i) {
              final f = _files[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                  title: Text(
                    f.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(formatBytes(f.size)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        onPressed: i == 0 ? null : () => _move(i, -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        onPressed: i == _files.length - 1
                            ? null
                            : () => _move(i, 1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _files.removeAt(i)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: (_files.length >= 2 && !_working) ? _merge : null,
            child: _working
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Merge files'),
          ),
          if (_files.length == 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Add one more file to merge.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
          if (_successMessage != null) SuccessCard(message: _successMessage!),
          if (_error != null) ErrorCard(message: _error!),
          const SizedBox(height: 18),
          const NativeToolAd(),
        ],
      ),
    );
  }
}
