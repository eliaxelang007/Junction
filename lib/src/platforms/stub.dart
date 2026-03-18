import "shared.dart";

const String _stubErrorMessage =
    "You're using an implementation from the stub file! This either means that you're on a platform that we don't support or that something has gone wrong.";

/* + Reading + */
sealed class CrossReadHandle<Data extends CrossFilesystemData> {
  Future<CrossFilesystemItem<Data>> read();
}

class NativeReadHandle extends CrossReadHandle<CrossFilesystemData> {
  static Future<NativeReadHandle> fromPath(CrossPath path) {
    throw UnimplementedError(_stubErrorMessage);
  }

  @override
  Future<CrossFilesystemItem<CrossFilesystemData>> read() {
    throw UnimplementedError(_stubErrorMessage);
  }
}

class WebOpfsReadHandle extends CrossReadHandle<CrossFilesystemData> {
  static Future<WebOpfsReadHandle> fromPath(CrossPath path) {
    throw UnimplementedError(_stubErrorMessage);
  }

  @override
  Future<CrossFilesystemItem<CrossFilesystemData>> read() {
    throw UnimplementedError(_stubErrorMessage);
  }
}

class WebReadHandle extends CrossReadHandle<CrossFileData> {
  // This factory is for the public interface only! It'll have a private constructor in the actual implementation.
  factory WebReadHandle() {
    throw UnimplementedError(_stubErrorMessage);
  }

  @override
  Future<CrossFilesystemItem<CrossFileData>> read() {
    throw UnimplementedError(_stubErrorMessage);
  }
}
/* - Reading - */

/* + Writing + */
sealed class CrossWriteHandle<Data extends CrossFilesystemData> {
  Future<void> write(CrossFilesystemItem<Data> item);
}

class NativeWriteHandle extends CrossWriteHandle<CrossFilesystemData> {
  static Future<NativeWriteHandle> fromPath(CrossPath path) {
    throw UnimplementedError(_stubErrorMessage);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFilesystemData> item) {
    throw UnimplementedError(_stubErrorMessage);
  }
}

class WebOpfsWriteHandle extends CrossWriteHandle<CrossFilesystemData> {
  static Future<WebOpfsWriteHandle> fromPath(CrossPath path) {
    throw UnimplementedError(_stubErrorMessage);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFilesystemData> item) {
    throw UnimplementedError(_stubErrorMessage);
  }
}

class WebWriteHandle extends CrossWriteHandle<CrossFileData> {
  // This factory is for the public interface only! It'll have a private constructor in the actual implementation.
  factory WebWriteHandle() {
    throw UnimplementedError(_stubErrorMessage);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFileData> item) {
    throw UnimplementedError(_stubErrorMessage);
  }
}
/* - Writing - */