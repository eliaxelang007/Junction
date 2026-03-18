import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'junction_data.dart';

Future<AnyCrossFilesystemItem> nativeRead(CrossPath path) =>
    throw UnsupportedError('Native only');
Future<void> nativeWrite(CrossPath path, Uint8List bytes) =>
    throw UnsupportedError('Native only');

Future<Object?> pickWebFile() async {
  final completer = Completer<web.File?>();
  final web.HTMLInputElement input =
      web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';

  input.onChange.listen((web.Event event) {
    final web.FileList? files = input.files;
    if (files != null && files.length > 0) {
      completer.complete(files.item(0));
    } else {
      completer.complete(null);
    }
  });

  input.click();
  return completer.future;
}

Future<Object?> pickWebSaveFile(String? suggestedName) async {
  // On the web fallback, we can't pre-pick a destination.
  // We just return the suggested name as our "handle" token.
  return suggestedName ?? "downloaded_file";
}

Future<AnyCrossFilesystemItem> webRead(Object opaqueHandle) async {
  final web.File file = opaqueHandle as web.File;
  final completer = Completer<Uint8List>();
  final web.FileReader reader = web.FileReader();

  reader.onLoadEnd.listen((web.ProgressEvent e) {
    final JSArrayBuffer arrayBuffer = reader.result as JSArrayBuffer;
    completer.complete(arrayBuffer.toDart.asUint8List());
  });

  reader.readAsArrayBuffer(file);
  final bytes = await completer.future;

  return CrossFile(
    name: CrossFilesystemName(file.name),
    data: CrossFileData(bytes: bytes),
  );
}

Future<void> webWrite(
  Object opaqueHandle,
  Uint8List bytes,
  String filename,
) async {
  final fallbackName = opaqueHandle as String;
  final finalName = filename.isNotEmpty ? filename : fallbackName;

  // Create a Blob from the bytes
  final web.Blob blob = web.Blob([bytes.toJS].toJS);
  final String url = web.URL.createObjectURL(blob);

  // Create a hidden anchor tag to trigger the download
  final web.HTMLAnchorElement anchor =
      web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = finalName;

  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}
