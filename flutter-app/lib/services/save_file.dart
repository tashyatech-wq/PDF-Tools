import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [bytes] to a temp file and opens the native share sheet, so the
/// person can save it to Files/Drive/WhatsApp/etc. There is no "download"
/// concept on mobile the way there is on the web prototype — the share sheet
/// is the native equivalent, and it still never touches a server of ours.
Future<void> saveAndShare(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], fileNameOverrides: [filename]),
  );
}
