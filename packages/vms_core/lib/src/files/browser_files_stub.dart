import 'dart:typed_data';

import 'browser_files.dart';

// Non-web builds (unit tests on the VM) have no file chooser or downloads.

Future<PickedFile?> pickFile({String accept = ''}) async => null;

void saveBytes(Uint8List bytes, {required String fileName, required String contentType}) {}

void openBytes(Uint8List bytes, {required String contentType}) {}
