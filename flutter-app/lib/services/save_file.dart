import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SavedPdfFile {
  const SavedPdfFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'size': size,
    'createdAt': createdAt.toIso8601String(),
  };

  static SavedPdfFile fromJson(Map<String, Object?> json) => SavedPdfFile(
    id: json['id'] as String,
    name: json['name'] as String,
    path: json['path'] as String,
    size: json['size'] as int,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

Future<Directory> _savedPdfDirectory() async {
  final root = await getApplicationDocumentsDirectory();
  final dir = Directory('${root.path}/saved-pdfs');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

Future<File> _indexFile() async {
  final dir = await _savedPdfDirectory();
  return File('${dir.path}/index.json');
}

String _safeFilename(String filename) {
  final cleaned = filename
      .trim()
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '-')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return 'document.pdf';
  return cleaned.toLowerCase().endsWith('.pdf') ? cleaned : '$cleaned.pdf';
}

Future<String> _uniquePath(Directory dir, String filename) async {
  final safe = _safeFilename(filename);
  final dot = safe.toLowerCase().lastIndexOf('.pdf');
  final base = dot == -1 ? safe : safe.substring(0, dot);
  var candidate = '${dir.path}/$safe';
  var counter = 2;
  while (await File(candidate).exists()) {
    candidate = '${dir.path}/$base-$counter.pdf';
    counter++;
  }
  return candidate;
}

Future<List<SavedPdfFile>> savedPdfFiles() async {
  final index = await _indexFile();
  if (!await index.exists()) return [];

  final raw = await index.readAsString();
  if (raw.trim().isEmpty) return [];

  final decoded = jsonDecode(raw) as List<dynamic>;
  final files =
      decoded
          .map((item) => SavedPdfFile.fromJson(item as Map<String, Object?>))
          .where((item) => File(item.path).existsSync())
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  await _writeSavedIndex(files);
  return files;
}

Future<void> _writeSavedIndex(List<SavedPdfFile> files) async {
  final index = await _indexFile();
  await index.writeAsString(
    const JsonEncoder.withIndent('  ')
        .convert(files.map((file) => file.toJson()).toList()),
    flush: true,
  );
}

Future<SavedPdfFile> savePdfFile(Uint8List bytes, String filename) async {
  final dir = await _savedPdfDirectory();
  final path = await _uniquePath(dir, filename);
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  final saved = SavedPdfFile(
    id: DateTime.now().microsecondsSinceEpoch.toString(),
    name: path.split('/').last,
    path: path,
    size: bytes.length,
    createdAt: DateTime.now(),
  );
  final files = await savedPdfFiles();
  await _writeSavedIndex([saved, ...files]);
  return saved;
}

Future<void> shareSavedPdf(SavedPdfFile file) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], fileNameOverrides: [file.name]),
  );
}

Future<void> deleteSavedPdf(SavedPdfFile file) async {
  final diskFile = File(file.path);
  if (await diskFile.exists()) {
    await diskFile.delete();
  }
  final files = await savedPdfFiles();
  await _writeSavedIndex(files.where((item) => item.id != file.id).toList());
}

/// Saves the PDF inside the app first, then opens the native share sheet.
/// Users can return to the Saved tab later to share or delete the export.
Future<SavedPdfFile> saveAndShare(Uint8List bytes, String filename) async {
  final saved = await savePdfFile(bytes, filename);
  await shareSavedPdf(saved);
  return saved;
}
