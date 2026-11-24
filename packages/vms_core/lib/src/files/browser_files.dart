import 'dart:typed_data';

import 'browser_files_stub.dart' if (dart.library.js_interop) 'browser_files_web.dart' as impl;

/// A file the user chose in the browser.
class PickedFile {
  const PickedFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;

  int get size => bytes.length;
}

/// Opens the browser's file chooser. Resolves to null when the user cancels.
/// [accept] is the input's accept list, e.g. `.pdf,image/*`.
Future<PickedFile?> pickFile({String accept = ''}) => impl.pickFile(accept: accept);

/// Saves [bytes] as a download named [fileName].
void saveBytes(Uint8List bytes, {required String fileName, required String contentType}) =>
    impl.saveBytes(bytes, fileName: fileName, contentType: contentType);

/// Shows [bytes] in a new browser tab (PDF / image preview).
void openBytes(Uint8List bytes, {required String contentType}) => impl.openBytes(bytes, contentType: contentType);

/// `1.2 MB`, `640 KB`, `512 B`.
String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}
