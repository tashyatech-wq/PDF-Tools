import 'dart:io';

import 'package:flutter/material.dart';

import '../services/app_open_ad_service.dart';
import '../services/save_file.dart';
import '../widgets/native_tool_ad.dart';
import '../widgets/result_cards.dart';
import 'pdf_preview_screen.dart';

class SavedFilesScreen extends StatefulWidget {
  const SavedFilesScreen({super.key});

  @override
  State<SavedFilesScreen> createState() => _SavedFilesScreenState();
}

class _SavedFilesScreenState extends State<SavedFilesScreen> {
  List<SavedPdfFile>? _files;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final files = await savedPdfFiles();
    if (!mounted) return;
    setState(() => _files = files);
  }

  // Removes [file] from the visible list immediately, rather than waiting
  // on a full re-fetch (and the loading spinner that would briefly replace
  // the *whole* list while it ran): that made a successful delete look like
  // it had done nothing, and tapping delete on a different row during that
  // window -- once the list had reflowed under it -- could remove the
  // wrong file entirely. A SnackBar confirms which file is actually gone.
  Future<void> _delete(SavedPdfFile file) async {
    setState(() => _files?.removeWhere((f) => f.id == file.id));
    final exportDeleted = await deleteSavedPdf(file);
    if (!mounted) return;
    final message = switch (exportDeleted) {
      null => 'Deleted ${file.name}',
      true => 'Deleted ${file.name} (and your saved copy of it)',
      false => 'Deleted ${file.name} from Saved — couldn\'t remove your '
          'saved copy of it, that one needs deleting by hand',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // See the matching comment on _open below: the native Save As picker is
  // a separate activity too, so returning from it would otherwise be
  // mistaken for the user coming back from elsewhere and get a full-screen
  // ad thrown over the picker -- which was also swallowing the save itself.
  Future<void> _export(SavedPdfFile file) async {
    AppOpenAdService.instance.suppressNextResume();
    try {
      final bytes = await File(file.path).readAsBytes();
      await exportPdfToDevice(bytes, file.name);
    } finally {
      AppOpenAdService.instance.clearSuppression();
    }
  }

  // pdfx's native PDF renderer briefly pauses/resumes the activity on some
  // devices when it opens, which AppOpenAdService otherwise reads as the
  // user returning from elsewhere and covers the preview with a full-screen
  // ad right as it appears. Same suppression used around the file picker
  // and scanner in the other screens.
  Future<void> _open(BuildContext context, SavedPdfFile file) async {
    AppOpenAdService.instance.suppressNextResume();
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PdfPreviewScreen(file: file)),
      );
    } finally {
      AppOpenAdService.instance.clearSuppression();
    }
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    if (files == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (files.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 36, 18, 26),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.7),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.folder_open_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No saved files yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Finished PDFs will appear here after merge, split, compress, or unlock.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const NativeSavedFilesAd(),
          ],
        ),
      );
    }

    final adIndex = files.length > 1 ? 1 : files.length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
        itemCount: files.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == adIndex) {
            return const NativeSavedFilesAd();
          }
          final fileIndex = index > adIndex ? index - 1 : index;
          final file = files[fileIndex];
          return _SavedFileTile(
            key: ValueKey(file.id),
            file: file,
            onOpen: () => _open(context, file),
            onShare: () => shareSavedPdf(file),
            onExport: () => _export(file),
            onDelete: () => _delete(file),
          );
        },
      ),
    );
  }
}

class _SavedFileTile extends StatelessWidget {
  const _SavedFileTile({
    super.key,
    required this.file,
    required this.onOpen,
    required this.onShare,
    required this.onExport,
    required this.onDelete,
  });

  final SavedPdfFile file;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.16)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${formatBytes(file.size)} • ${_dateLabel(file.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.2,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Share',
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded),
              ),
              IconButton(
                tooltip: 'Save PDF',
                onPressed: onExport,
                icon: const Icon(Icons.save_alt_rounded),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fileDay = DateTime(date.year, date.month, date.day);
    if (fileDay == today) {
      final minute = date.minute.toString().padLeft(2, '0');
      return '${date.hour}:$minute';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
