import 'dart:typed_data';
import 'junction_data.dart';

Future<Object?> pickWebFile() => throw UnsupportedError('Stub');
Future<Object?> pickWebSaveFile(String? suggestedName) =>
    throw UnsupportedError('Stub');

Future<AnyCrossFilesystemItem> webRead(Object opaqueHandle) =>
    throw UnsupportedError('Stub');
Future<void> webWrite(Object opaqueHandle, Uint8List bytes) =>
    throw UnsupportedError('Stub');

Future<AnyCrossFilesystemItem> nativeRead(CrossPath path) =>
    throw UnsupportedError('Stub');
Future<void> nativeWrite(CrossPath path, Uint8List bytes) =>
    throw UnsupportedError('Stub');
