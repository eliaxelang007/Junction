import "package:flutter/foundation.dart";
import "package:path/path.dart" as p;
import "dart:convert";
import "package:file_selector/file_selector.dart";

sealed class CrossFilesystemData {}

typedef CrossFilesystemItem<Data extends CrossFilesystemData> =
    MapEntry<CrossFilesystemName, Data>;
typedef AnyCrossFilesystemItem = CrossFilesystemItem<CrossFilesystemData>;

class CrossFileData extends CrossFilesystemData {
  final Uint8List bytes;

  CrossFileData({required this.bytes});

  static CrossFileData fromJson(Object? json) {
    return CrossFileData(bytes: utf8.encode(jsonEncode(json)));
  }

  dynamic toJson() {
    return jsonDecode(utf8.decode(bytes));
  }
}

extension type CrossFile._(CrossFilesystemItem<CrossFileData> _file)
    implements CrossFilesystemItem<CrossFileData> {
  factory CrossFile({
    required CrossFilesystemName name,
    required CrossFileData data,
  }) {
    return CrossFile._(CrossFilesystemItem<CrossFileData>(name, data));
  }
}

typedef CrossFolder = CrossFilesystemItem<CrossFolderData>;

class CrossFolderData extends CrossFilesystemData {
  final CrossFolderChildren children;

  CrossFolderData({required this.children});
}

extension type CrossFolderChildren(
  Map<CrossFilesystemName, CrossFilesystemData> _children
)
    implements Map<CrossFilesystemName, CrossFilesystemData> {}

enum CrossPathError implements Exception {
  empty("A filesystem path can't be empty!");

  final String message;

  const CrossPathError(this.message);

  @override
  String toString() => message;
}

extension type CrossPath._(List<CrossFilesystemName> pathElements)
    implements List<CrossFilesystemName> {
  static CrossPathError? _validate(List<CrossFilesystemName> path) {
    if (path.isEmpty) {
      return CrossPathError.empty;
    }

    return null;
  }

  factory CrossPath(List<CrossFilesystemName> path) {
    final error = _validate(path);

    if (error != null) {
      throw error;
    }

    return CrossPath._(path);
  }

  String asString() {
    return p.joinAll(pathElements);
  }

  static CrossPath fromString(String maybePath) {
    return CrossPath(
      p
          .split(maybePath)
          .map((maybePart) => CrossFilesystemName(maybePart))
          .toList(),
    );
  }
}

/* + Main API + */

/// This is a version of assert that doesn't get disabled in production.
/// See https://dart.dev/language/error-handling#assert
void _enforce(bool condition, [String? message]) {
  if (condition) {
    return;
  }
  throw AssertionError(message);
}

sealed class CrossReadHandle {
  Future<AnyCrossFilesystemItem> read();
}

// enum CrossReadHandleError implements Exception {} // TODO

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
    _enforce(
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
    _enforce(
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
    _enforce(
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
    _enforce(
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
    _enforce(
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
    _enforce(
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
    _enforce(
      kIsWeb,
      "You can only instantiate this type from a web environment!",
    );
  }

  @override
  Future<void> write(AnyCrossFilesystemItem item) async {
    final data = item.value;

    if (data is! CrossFileData) {
      _enforce(
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
      _enforce(
        false,
        "Apologies! We can only write [CrossFile]s for now, but we're working towards being able to write [CrossFolder]s in the future, too.",
      );

      return;
    }

    XFile.fromData(data.bytes).saveTo(writeTo.asString());
  }
}

/* - Main API - */

/// Windows's max filesystem item name length is 255 characters.
const int maxPath = 255;

enum CrossFilesystemNameError implements Exception {
  empty("A filename can't be empty!"),
  exceedingLength("A filename can't be longer than $maxPath characters!"),
  // nonAscii("A filename has to be valid ascii!"),
  forbiddenCharacters(
    "A filename can't contain '<', '>', ':', '\"', '/', '\\', '|', '?', or '*'!",
  ),
  // nonLowercase("A filename can't have any case other than lowercase!"),
  beginningOrEndingWithWhitespace(
    "A filename can't start or end with whitespace!",
  ),
  endingPeriod("A filename can't end with a period!");

  final String message;

  const CrossFilesystemNameError(this.message);

  @override
  String toString() => message;
}

extension type const CrossFilesystemName._(String fullFilename)
    implements String {
  static CrossFilesystemNameError? _validate(String fullFilename) {
    if (fullFilename.isEmpty) {
      return CrossFilesystemNameError.empty;
    }

    if (fullFilename.length > maxPath) {
      return CrossFilesystemNameError.exceedingLength;
    }

    if (fullFilename.endsWith('.')) {
      return CrossFilesystemNameError.endingPeriod;
    }

    // if (fullFilename.codeUnits.any((c) => c < 32 || c > 126)) {
    //   return CrossFilesystemNameError.nonAscii;
    // }

    if (fullFilename.contains(RegExp(r'[<>:"/\\|?*]'))) {
      return CrossFilesystemNameError.forbiddenCharacters;
    }

    // if (fullFilename != fullFilename.toLowerCase()) {
    //   return Failure(CrossFilesystemNameError.nonLowercase);
    // }

    if (fullFilename.trim().length != fullFilename.length) {
      return CrossFilesystemNameError.beginningOrEndingWithWhitespace;
    }

    return null;
  }

  factory CrossFilesystemName(String fullFilename) {
    final error = _validate(fullFilename);

    if (error != null) {
      throw error;
    }

    return CrossFilesystemName._(fullFilename);
  }
}
