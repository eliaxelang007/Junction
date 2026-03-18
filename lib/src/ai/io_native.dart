import 'dart:io';
import 'dart:typed_data';
import 'junction_data.dart';

Future<Object?> pickWebFile() => throw UnsupportedError('Web only');
Future<Object?> pickWebSaveFile(String? suggestedName) =>
    throw UnsupportedError('Web only');
Future<AnyCrossFilesystemItem> webRead(Object opaqueHandle) =>
    throw UnsupportedError('Web only');
Future<void> webWrite(Object opaqueHandle, Uint8List bytes, String filename) =>
    throw UnsupportedError('Web only');

Future<AnyCrossFilesystemItem> nativeRead(CrossPath path) async {
  final file = File(path.asString());
  if (!await file.exists()) throw Exception("File not found");

  final bytes = await file.readAsBytes();
  return CrossFile(
    name: CrossFilesystemName(path.pathElements.last.toString()),
    data: CrossFileData(bytes: bytes),
  );
}

Future<void> nativeWrite(CrossPath path, Uint8List bytes) async {
  final file = File(path.asString());
  await file.writeAsBytes(bytes);
}
