import 'package:flutter/foundation.dart';
import 'package:file_selector/file_selector.dart';

import 'junction_data.dart';
import 'io_stub.dart'
    if (dart.library.io) 'platform/io_native.dart'
    if (dart.library.js_interop) 'platform/io_web.dart'
    as platform;

sealed class CrossReadHandle {
  Future<AnyCrossFilesystemItem> read();
}

sealed class CrossReadHandleRequest {
  Future<CrossReadHandle> handle();
}

class WebReadHandleRequest extends CrossReadHandleRequest {
  final Object opaqueWebHandle;

  WebReadHandleRequest(this.opaqueWebHandle) {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  @override
  Future<CrossReadHandle> handle() async {
    return WebReadHandle(opaqueWebHandle);
  }
}

class NativeReadHandleRequest extends CrossReadHandleRequest {
  final CrossPath path;

  NativeReadHandleRequest({required this.path}) {
    enforce(
      !kIsWeb,
      "You can only instantiate this type from a native environment!",
    );
  }

  @override
  Future<CrossReadHandle> handle() async {
    return NativeReadHandle(path: path);
  }
}

class WebReadHandle extends CrossReadHandle {
  final Object opaqueWebHandle;

  WebReadHandle(this.opaqueWebHandle) {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  @override
  Future<AnyCrossFilesystemItem> read() async {
    return platform.webRead(opaqueWebHandle);
  }
}

class NativeReadHandle extends CrossReadHandle {
  final CrossPath path;

  NativeReadHandle({required this.path}) {
    enforce(
      !kIsWeb,
      "You can only instantiate this type from a native environment!",
    );
  }

  @override
  Future<AnyCrossFilesystemItem> read() async {
    return platform.nativeRead(path);
  }
}

sealed class CrossWriteHandle {
  Future<void> write(AnyCrossFilesystemItem item);
}

sealed class CrossWriteHandleRequest {
  Future<CrossWriteHandle> handle();
}

class WebWriteHandleRequest extends CrossWriteHandleRequest {
  final Object opaqueWebHandle;

  WebWriteHandleRequest(this.opaqueWebHandle) {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  @override
  Future<CrossWriteHandle> handle() async {
    return WebWriteHandle(opaqueWebHandle);
  }
}

class NativeWriteHandleRequest extends CrossWriteHandleRequest {
  final CrossPath writeTo;

  NativeWriteHandleRequest({required this.writeTo}) {
    enforce(
      !kIsWeb,
      "You can only instantiate this type from a native environment!",
    );
  }

  @override
  Future<CrossWriteHandle> handle() async {
    return NativeWriteHandle(writeTo: writeTo);
  }
}

class WebWriteHandle extends CrossWriteHandle {
  final Object opaqueWebHandle;

  WebWriteHandle(this.opaqueWebHandle) {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  @override
  Future<void> write(AnyCrossFilesystemItem item) async {
    final data = item.value;
    if (data is! CrossFileData) {
      enforce(false, "Can only write CrossFiles for now.");
      return;
    }
    await platform.webWrite(opaqueWebHandle, data.bytes, item.key.toString());
  }
}

class NativeWriteHandle extends CrossWriteHandle {
  final CrossPath writeTo;

  NativeWriteHandle({required this.writeTo}) {
    enforce(
      !kIsWeb,
      "You can only instantiate this type from a native environment!",
    );
  }

  @override
  Future<void> write(AnyCrossFilesystemItem item) async {
    final data = item.value;
    if (data is! CrossFileData) {
      enforce(false, "Can only write CrossFiles for now.");
      return;
    }
    await platform.nativeWrite(writeTo, data.bytes);
  }
}

Future<CrossReadHandleRequest?> showOpenFilePicker({
  String? label,
  List<String>? allowedExtensions,
}) async {
  if (kIsWeb) {
    final handle = await platform.pickWebFile();
    if (handle == null) return null;
    return WebReadHandleRequest(handle);
  } else {
    final handle = await openFile(
      acceptedTypeGroups: <XTypeGroup>[
        XTypeGroup(label: label, extensions: allowedExtensions),
      ],
    );
    if (handle == null) return null;
    return NativeReadHandleRequest(path: CrossPath.fromString(handle.path));
  }
}

Future<CrossWriteHandleRequest?> showSaveFilePicker({
  String? suggestedName,
}) async {
  if (kIsWeb) {
    final handle = await platform.pickWebSaveFile(suggestedName);
    if (handle == null) return null;
    return WebWriteHandleRequest(handle);
  } else {
    final saveLocation = await getSaveLocation(suggestedName: suggestedName);
    if (saveLocation == null) return null;
    return NativeWriteHandleRequest(
      writeTo: CrossPath.fromString(saveLocation.path),
    );
  }
}
