import 'package:flutter/material.dart';

import '../services/save_file.dart';
import 'result_cards.dart';

/// Lets the user pick one or more of their own previously saved PDFs.
///
/// Saved PDFs live in this app's private storage (invisible to the system
/// file picker by Android's own sandboxing, not a bug), so this is the only
/// way to reuse one of them as input to another tool.
Future<List<SavedPdfFile>?> pickFromSavedFiles(
  BuildContext context, {
  required bool allowMultiple,
}) {
  return showModalBottomSheet<List<SavedPdfFile>>(
    context: context,
    isScrollControlled: true,
    builder: (context) =>
        _SavedFilesPickerSheet(allowMultiple: allowMultiple),
  );
}

class _SavedFilesPickerSheet extends StatefulWidget {
  const _SavedFilesPickerSheet({required this.allowMultiple});

  final bool allowMultiple;

  @override
  State<_SavedFilesPickerSheet> createState() =>
      _SavedFilesPickerSheetState();
}

class _SavedFilesPickerSheetState extends State<_SavedFilesPickerSheet> {
  late final Future<List<SavedPdfFile>> _files = savedPdfFiles();
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Choose from Saved Files',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<SavedPdfFile>>(
                  future: _files,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final files = snapshot.data ?? const [];
                    if (files.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No saved files yet.'),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                      itemCount: files.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final file = files[index];
                        final selected = _selectedIds.contains(file.id);
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(
                                context,
                              ).dividerColor.withValues(alpha: 0.5),
                            ),
                          ),
                          leading: const Icon(Icons.picture_as_pdf_rounded),
                          title: Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(formatBytes(file.size)),
                          trailing: widget.allowMultiple
                              ? Checkbox(
                                  value: selected,
                                  onChanged: (_) => setState(() {
                                    if (selected) {
                                      _selectedIds.remove(file.id);
                                    } else {
                                      _selectedIds.add(file.id);
                                    }
                                  }),
                                )
                              : null,
                          onTap: () {
                            if (widget.allowMultiple) {
                              setState(() {
                                if (selected) {
                                  _selectedIds.remove(file.id);
                                } else {
                                  _selectedIds.add(file.id);
                                }
                              });
                            } else {
                              Navigator.of(context).pop([file]);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (widget.allowMultiple)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                  child: FilledButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () async {
                            final files = await _files;
                            if (!context.mounted) return;
                            Navigator.of(context).pop(
                              files
                                  .where((f) => _selectedIds.contains(f.id))
                                  .toList(),
                            );
                          },
                    child: Text(
                      _selectedIds.isEmpty
                          ? 'Select files'
                          : 'Add ${_selectedIds.length} file${_selectedIds.length == 1 ? '' : 's'}',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
