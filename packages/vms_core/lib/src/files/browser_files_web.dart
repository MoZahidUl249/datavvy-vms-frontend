import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'browser_files.dart';

Future<PickedFile?> pickFile({String accept = ''}) {
  final completer = Completer<PickedFile?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = accept;

  void finish(PickedFile? file) {
    if (!completer.isCompleted) completer.complete(file);
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final file = input.files?.item(0);
      if (file == null) {
        finish(null);
        return;
      }
      file.arrayBuffer().toDart.then(
            (buffer) => finish(PickedFile(name: file.name, bytes: buffer.toDart.asUint8List())),
            onError: (Object _) => finish(null),
          );
    }).toJS,
  );
  input.addEventListener('cancel', ((web.Event _) => finish(null)).toJS);
  input.click();
  return completer.future;
}

web.Blob _blob(Uint8List bytes, String contentType) =>
    web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: contentType));

void saveBytes(Uint8List bytes, {required String fileName, required String contentType}) {
  final url = web.URL.createObjectURL(_blob(bytes, contentType));
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
}

void openBytes(Uint8List bytes, {required String contentType}) {
  final url = web.URL.createObjectURL(_blob(bytes, contentType));
  web.window.open(url, '_blank');
  Timer(const Duration(minutes: 5), () => web.URL.revokeObjectURL(url));
}
