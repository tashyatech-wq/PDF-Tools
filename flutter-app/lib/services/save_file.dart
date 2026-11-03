import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart'
    show MethodChannel, MissingPluginException, PlatformException;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

const _filesChannel = MethodChannel('pdf_tools/files');

class SavedPdfFile {
  const SavedPdfFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
    this.exportUri,
  });

  final String id;
  final String name;
  final String path;
  final int size;
  final DateTime createdAt;

  /// The content:// Uri this file was also exported to (Downloads, Drive,
  /// wherever the user picked in the Save As dialog), if any -- kept so
  /// Delete can remove that copy too, not just this app's own private one.
  /// Null for files that only ever lived in the private library (e.g. the
  /// per-page outputs of "Split -> every page", which are never exported).
  final String? exportUri;

  /// Only the file's own name is persisted -- [path] is rebuilt from the
  /// *current* saved-pdfs directory every time instead. The sandbox
  /// container this app lives in (which an absolute path bakes in) isn't
  /// guaranteed stable across a reinstall, an offload-and-reinstall, or a
  /// backup restore; storing the old absolute path verbatim would make
  /// `File(item.path).existsSync()` in [savedPdfFiles] false for every
  /// entry after that happens, silently dropping the whole library from
  /// the Saved tab even though the files are still on disk.
  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'createdAt': createdAt.toIso8601String(),
    if (exportUri != null) 'exportUri': exportUri!,
  };

  static SavedPdfFile fromJson(Map<String, Object?> json, String dirPath) {
    final name = json['name'] as String;
    return SavedPdfFile(
      id: json['id'] as String,
      name: name,
      path: '$dirPath/$name',
      size: json['size'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      exportUri: json['exportUri'] as String?,
    );
  }
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
  final dir = await _savedPdfDirectory();
  final index = await _indexFile();
  if (!await index.exists()) return [];

  final raw = await index.readAsString();
  if (raw.trim().isEmpty) return [];

  final decoded = jsonDecode(raw) as List<dynamic>;
  final files =
      decoded
          .map(
            (item) =>
                SavedPdfFile.fromJson(item as Map<String, Object?>, dir.path),
          )
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

Future<SavedPdfFile> savePdfFile(
  Uint8List bytes,
  String filename, {
  String? exportUri,
}) async {
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
    exportUri: exportUri,
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

/// Lets the user put a copy of [bytes] wherever they choose on their device
/// (Downloads, Documents, Drive, etc.) via Android/iOS's own "Save As"
/// picker -- the standard way a document-producing app hands off its
/// output, and the only way the file ends up somewhere the system Files
/// app and other apps can see it. (This app's own "Saved Files" library
/// uses private app storage instead, by design -- see [_savedPdfDirectory]
/// -- so it can't be seen from there either.)
///
/// Returns the destination [Uri], or `null` if the user cancelled.
///
/// On Android this runs our own ACTION_CREATE_DOCUMENT flow (see
/// MainActivity.kt) instead of file_picker's: file_picker's native code
/// only ever hands Dart the chosen Uri's bare path (e.g. "/document/249"),
/// not its scheme and authority, which makes it impossible to later
/// reconstruct a working reference to that file -- so [deleteSavedPdf]
/// could never actually delete the exported copy, only the private one.
Future<Uri?> exportPdfToDevice(Uint8List bytes, String filename) async {
  final safeName = _safeFilename(filename);
  if (Platform.isAndroid) {
    try {
      final result = await _filesChannel.invokeMethod<String>('saveAs', {
        'fileName': safeName,
        'mimeType': 'application/pdf',
        'bytes': bytes,
      });
      return result == null ? null : Uri.parse(result);
    } on PlatformException {
      // Fall through to file_picker below.
    } on MissingPluginException {
      // Fall through to file_picker below.
    }
  }
  return FilePicker.saveFile(
    fileName: safeName,
    bytes: bytes,
    mimeType: 'application/pdf',
  );
}

/// Best-effort filename the user actually chose in the Save As dialog.
///
/// Local storage providers (Downloads, primary storage) expose it as the
/// final path segment of the returned content URI, e.g.
/// `.../document/primary:Download/m1new.pdf` -- not guaranteed for every
/// provider (a cloud provider can return an opaque document ID instead of
/// a readable name), but it covers the common case.
String? _displayNameFromUri(Uri uri) {
  if (uri.pathSegments.isEmpty) return null;
  final decoded = Uri.decodeComponent(uri.pathSegments.last);
  final name = decoded.substring(decoded.lastIndexOf('/') + 1);
  return name.toLowerCase().endsWith('.pdf') ? name : null;
}

/// Deletes [uri] (a content:// Uri this app previously exported a file to)
/// via Android's DocumentsContract, using the persistable permission grant
/// [_persistExportUri] took when the file was first saved. Best-effort:
/// false just means that copy is left where it is (permission revoked,
/// provider doesn't support deletion, already gone, or this isn't Android),
/// never an error the caller needs to react to.
Future<bool> _deleteExportUri(String uri) async {
  try {
    return await _filesChannel.invokeMethod<bool>('deleteUri', {
          'uri': uri,
        }) ??
        false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}

/// Best-effort: lets a later [_deleteExportUri] call actually delete this
/// Uri even after the app has restarted. See the comment on
/// [SavedPdfFile.exportUri] for why this is needed at all -- file_picker's
/// own Save As flow doesn't do this itself.
Future<void> _persistExportUri(Uri uri) async {
  try {
    await _filesChannel.invokeMethod<bool>('persistUri', {
      'uri': uri.toString(),
    });
  } on PlatformException {
    // Fine -- deletion later just won't reach this particular copy.
  } on MissingPluginException {
    // Not Android; nothing to persist.
  }
}

/// Deletes the app's own private copy of [file], plus the copy it was
/// exported to (Downloads, Drive, wherever) when there is one. Returns
/// null if there was no exported copy to begin with, or whether deleting
/// that copy succeeded -- the private copy is always removed either way,
/// since that's the one this app can always guarantee.
Future<bool?> deleteSavedPdf(SavedPdfFile file) async {
  final diskFile = File(file.path);
  if (await diskFile.exists()) {
    await diskFile.delete();
  }
  final exportUri = file.exportUri;
  final exportDeleted = exportUri == null
      ? null
      : await _deleteExportUri(exportUri);
  final files = await savedPdfFiles();
  await _writeSavedIndex(files.where((item) => item.id != file.id).toList());
  return exportDeleted;
}

/// Lets the user save a copy to a standard location of their choice --
/// Downloads, Documents, or wherever else -- via the system's own "Save As"
/// dialog, then saves the PDF inside the app's own library too (so it shows
/// up in the Saved tab and can be reused as input elsewhere), under
/// whichever name the user actually chose in that dialog when it can be
/// determined, so the two copies don't end up confusingly named differently.
Future<SavedPdfFile> saveAndExport(Uint8List bytes, String filename) async {
  String? chosenName;
  String? exportUri;
  try {
    final uri = await exportPdfToDevice(bytes, filename);
    if (uri != null) {
      chosenName = _displayNameFromUri(uri);
      exportUri = uri.toString();
      await _persistExportUri(uri);
    }
  } catch (_) {
    // The private copy below is the fallback if the system Save As dialog
    // itself fails; the user's work should never be lost over it.
  }
  return savePdfFile(bytes, chosenName ?? filename, exportUri: exportUri);
}
