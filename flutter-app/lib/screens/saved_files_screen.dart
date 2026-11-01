import 'package:flutter/material.dart';

import '../services/save_file.dart';
import '../widgets/result_cards.dart';

class SavedFilesScreen extends StatefulWidget {
  const SavedFilesScreen({super.key});

  @override
  State<SavedFilesScreen> createState() => _SavedFilesScreenState();
}

class _SavedFilesScreenState extends State<SavedFilesScreen> {
  late Future<List<SavedPdfFile>> _files;

  @override
  void initState() {
    super.initState();
    _files = savedPdfFiles();
  }

  void _reload() {
    setState(() => _files = savedPdfFiles());
  }

  Future<void> _delete(SavedPdfFile file) async {
    await deleteSavedPdf(file);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SavedPdfFile>>(
      future: _files,
      builder: (context, snapshot) {
        final files = snapshot.data ?? [];
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (files.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 36, 18, 26),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).dividerColor
                          .withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary
                              .withValues(alpha: 0.12),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
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
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 26),
            itemCount: files.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = files[index];
              return _SavedFileTile(
                file: file,
                onShare: () => shareSavedPdf(file),
                onDelete: () => _delete(file),
              );
            },
          ),
        );
      },
    );
  }
}

class _SavedFileTile extends StatelessWidget {
  const _SavedFileTile({
    required this.file,
    required this.onShare,
    required this.onDelete,
  });

  final SavedPdfFile file;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
            child: Icon(Icons.picture_as_pdf_rounded, color: color, size: 22),
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
            tooltip: 'Delete',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
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
