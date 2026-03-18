/*
1. 
*/

import "shared.dart";

sealed class CrossReadHandle {
  Future<AnyCrossFilesystemItem> read();
}

sealed class CrossReadHandleRequest {
  Future<CrossReadHandle> handle();
}

class WebReadHandleRequest extends CrossReadHandleRequest {
  final WebReadHandle webHandle;

  WebReadHandleRequest({required this.webHandle}) {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<CrossReadHandle> handle() async {
    throw UnsupportedError("This feature is unsupported!");
  }
}

class NativeReadHandleRequest extends CrossReadHandleRequest {
  final NativeReadHandle path;

  NativeReadHandleRequest({required this.path}) {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<CrossReadHandle> handle() async {
    throw UnsupportedError("This feature is unsupported!");
  }
}

Future<CrossReadHandleRequest?> showOpenFilePicker({
  String? label,
  List<String>? allowedExtensions,
  List<String>? uniformTypeIdentifiers,
  List<String>? webWildCards,
}) async {
  throw UnsupportedError("This feature is unsupported!");
}

class WebReadHandle extends CrossReadHandle {
  final XFile webHandle;

  WebReadHandle({required this.webHandle}) {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<AnyCrossFilesystemItem> read() async {
    throw UnsupportedError("This feature is unsupported!");
  }
}

class NativeReadHandle extends CrossReadHandle {
  final XFile nativeHandle;

  NativeReadHandle({required this.nativeHandle}) {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<AnyCrossFilesystemItem> read() async {
    throw UnsupportedError("This feature is unsupported!");
  }
}

sealed class CrossWriteHandleRequest {
  Future<CrossWriteHandle> handle();
}

class WebWriteHandleRequest extends CrossWriteHandleRequest {
  WebWriteHandleRequest() {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<CrossWriteHandle> handle() async {
    throw UnsupportedError("This feature is unsupported!");
  }
}

class NativeWriteHandleRequest extends CrossWriteHandleRequest {
  final CrossPath writeTo;

  NativeWriteHandleRequest({required this.writeTo}) {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<CrossWriteHandle> handle() async {
    return NativeWriteHandle(writeTo: writeTo);
  }
}

Future<NativeWriteHandleRequest?> showSaveFilePicker({
  String? suggestedName,
}) async {
  throw UnsupportedError("This feature is unsupported!");
}

sealed class CrossWriteHandle {
  Future<void> write(CrossFilesystemItem item);
}

class WebWriteHandle extends CrossWriteHandle {
  WebWriteHandle() {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<void> write(AnyCrossFilesystemItem item) async {
    throw UnsupportedError("This feature is unsupported!");
  }
}

class NativeWriteHandle extends CrossWriteHandle {
  final CrossPath writeTo;

  NativeWriteHandle({required this.writeTo}) {
    throw UnsupportedError("This feature is unsupported!");
  }

  @override
  Future<void> write(AnyCrossFilesystemItem item) async {
    throw UnsupportedError("This feature is unsupported!");
  }
}
