import "shared.dart";
import "package:flutter/foundation.dart" show kIsWeb;

sealed class CrossReadHandle {
  Future<AnyCrossFilesystemItem> read();
}

/// Normally, the user will only interact with [CrossReadHandleRequest] through [showOpenFilePicker].
/// However, if you just wanted to get a file path from [showOpenFilePicker] on a native platform,
/// You can just write
///
/// ```
/// CrossReadHandleRequest request = showOpenFilePicker();
///
/// if (request is NativeHandleRequest) {
///   // Do something with [request.path]
/// }
/// ```
///
/// Which abstracts away the platform most of the time but still allows for specific platform handling!
sealed class CrossReadHandleRequest {
  /// See [NativeReadHandleRequest.handle]'s documentation for why this needs to be async.
  Future<CrossReadHandle> handle();
}

class WebReadHandleRequest extends CrossReadHandleRequest {
  /// The web's [showOpenFilePicker](https://developer.mozilla.org/en-US/docs/Web/API/Window/showOpenFilePicker) function already gives us a file handle!
  /// When [WebReadHandle] isn't just a wrapper for [XFile] anymore, [WebReadHandleRequest] should just store the file handle for later.
  final WebReadHandle webHandle;

  WebReadHandleRequest({required this.webHandle}) {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  /// See [NativeReadHandleRequest.handle]'s documentation for why this needs to be async.
  @override
  Future<CrossReadHandle> handle() async {
    return webHandle;
  }
}

class NativeReadHandleRequest extends CrossReadHandleRequest {
  /// An object that you can use to request for a read handle to a file? That's a file path!
  /// Right now, it still contains a [NativeReadHandle] (which is an [XFile] internally), but later on,
  /// this should just be a newtype wrapper for [CrossPath].
  final NativeReadHandle path;

  NativeReadHandleRequest({required this.path}) {
    enforce(
      !kIsWeb,
      "You can only instantiate this type from a native environment!",
    );
  }

  /// Later on, this function should give a file handle to the file path.
  /// This involves [FileSystemEntity.type], which is why it has to be sync even though it's async.
  @override
  Future<CrossReadHandle> handle() async {
    return path;
  }
}

Future<CrossReadHandleRequest?> showOpenFilePicker({
  String? label,
  List<String>? allowedExtensions,
  List<String>? uniformTypeIdentifiers,
  List<String>? webWildCards,
}) async {
  final handle = await openFile(
    acceptedTypeGroups: <XTypeGroup>[
      XTypeGroup(
        label: label,
        extensions: allowedExtensions,
        uniformTypeIdentifiers: uniformTypeIdentifiers,
        webWildCards: webWildCards,
      ),
    ],
  );

  if (handle == null) return null;

  return (kIsWeb)
      ? WebReadHandleRequest(webHandle: WebReadHandle(webHandle: handle))
      : NativeReadHandleRequest(path: NativeReadHandle(nativeHandle: handle));
} // TODO

class WebReadHandle extends CrossReadHandle {
  /// This is supposed to be a [FileSystemFileHandle](https://developer.mozilla.org/en-US/docs/Web/API/FileSystemFileHandle)!
  /// But for now, it's an [XFile].
  final XFile webHandle;

  WebReadHandle({required this.webHandle}) {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  /// Because of cross_file's design philosophy, [AnyCrossFilesystemItem] will never be a directory.
  /// Later on, it should be able to support that use case!
  @override
  Future<AnyCrossFilesystemItem> read() async {
    return CrossFile(
      name: CrossFilesystemName(webHandle.name),
      data: CrossFileData(bytes: await webHandle.readAsBytes()),
    );
  }
}

class NativeReadHandle extends CrossReadHandle {
  /// This is supposed to be a [FileSystemEntity]!
  /// But for now, it's an [XFile].
  final XFile nativeHandle;

  NativeReadHandle({required this.nativeHandle}) {
    enforce(
      !kIsWeb,
      "You can only instantiate this type from a native environment!",
    );
  }

  @override
  Future<AnyCrossFilesystemItem> read() async {
    return CrossFile(
      name: CrossFilesystemName(nativeHandle.name),
      data: CrossFileData(bytes: await nativeHandle.readAsBytes()),
    );
  }
}

// enum CrossWriteError implements Exception { TODO } // TODO

sealed class CrossWriteHandleRequest {
  /// See [WebWriteHandleRequest.handle]'s documentation for why this needs to be async!
  Future<CrossWriteHandle> handle();
}

/// On the web, you can't choose where to write/download your files, so this is really just a type for show.
class WebWriteHandleRequest extends CrossWriteHandleRequest {
  WebWriteHandleRequest() {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  /// [FileSystemFileHandle.createWritable](https://developer.mozilla.org/en-US/docs/Web/API/FileSystemFileHandle/createWritable) is async.
  /// Therefore, handle needs to be async.
  @override
  Future<CrossWriteHandle> handle() async {
    return WebWriteHandle();
  }
}

class NativeWriteHandleRequest extends CrossWriteHandleRequest {
  /// An object that you can use to request for a write handle to a file? That's a file path!
  final CrossPath writeTo;

  /// Right now, it still contains a [NativeWriteHandle] (which is an [XFile] internally), but later on,
  /// this should just be a newtype wrapper for [CrossPath].

  NativeWriteHandleRequest({required this.writeTo}) {
    enforce(
      !kIsWeb,
      "You can only instantiate this type from a native environment!",
    );
  }

  /// See [WebWriteHandleRequest.handle]'s documentation for why this needs to be async!
  @override
  Future<CrossWriteHandle> handle() async {
    return NativeWriteHandle(writeTo: writeTo);
  }
}

/// Because of the limitations of cross_path, I can only have [showSaveFilePicker] return [NativeWriteHandleRequest]s.
/// Why? Because calling [XFile.saveTo] on a cross_file on the web makes it open the file picker and save at the same time!
/// The step of getting a write handle and then actually writing to it is only separable  on native.
Future<NativeWriteHandleRequest?> showSaveFilePicker({
  String? suggestedName,
}) async {
  final saveLocation = await getSaveLocation(suggestedName: suggestedName);

  if (saveLocation == null) {
    return null;
  }

  return NativeWriteHandleRequest(
    writeTo: CrossPath.fromString(saveLocation.path),
  );
}

sealed class CrossWriteHandle {
  Future<void> write(CrossFilesystemItem item);
}

class WebWriteHandle extends CrossWriteHandle {
  WebWriteHandle() {
    enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  @override
  Future<void> write(AnyCrossFilesystemItem item) async {
    final data = item.value;

    if (data is! CrossFileData) {
      enforce(
        false,
        "Apologies! We can only write [CrossFile]s for now, but we're working towards being able to write [CrossFolder]s in the future, too.",
      );

      return;
    }

    /// The string here is "" because in actuality, you can't control where the file will be saved!
    XFile.fromData(data.bytes).saveTo("");
  }
}

/// If you want to write a file to a specific folder on native, you could write something like:
///
/// ```
/// await (
///   await NativeWriteHandleRequest(writeTo: CrossPath.fromString("./some/file/location")).handle()
/// ).write(file)
/// ```
///
/// Which should throw an error on web because it's unsupported!
///
/// Also, this should just be a write handle to the file itself, but right now,
/// it still stores a [CrossPath] within itself because it relies on cross_file.
/// See [NativeWriteHandleRequest]'s documentation for more.
class NativeWriteHandle extends CrossWriteHandle {
  final CrossPath writeTo;

  NativeWriteHandle({required this.writeTo}) : assert(!kIsWeb);

  @override
  Future<void> write(AnyCrossFilesystemItem item) async {
    final data = item.value;

    if (data is! CrossFileData) {
      enforce(
        false,
        "Apologies! We can only write [CrossFile]s for now, but we're working towards being able to write [CrossFolder]s in the future, too.",
      );

      return;
    }

    XFile.fromData(data.bytes).saveTo(writeTo.asString());
  }
}
