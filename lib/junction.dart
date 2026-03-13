import 'package:result_type/result_type.dart';
import "package:path/path.dart" as p;
import "dart:typed_data";
import "dart:convert";
import "dart:io";
import "package:cross_file/cross_file.dart";
import "package:file_selector/file_selector.dart";

sealed class CrossFilesystemData {}

typedef CrossFilesystemItem<Data extends CrossFilesystemData> =
    MapEntry<CrossFilesystemName, Data>;

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
  static Result<(), CrossPathError> _validate(List<CrossFilesystemName> path) {
    if (path.isEmpty) {
      return Failure(CrossPathError.empty);
    }

    return Success(());
  }

  static Result<CrossPath, CrossPathError> create(
    List<CrossFilesystemName> path,
  ) {
    return _validate(path).map((_) => CrossPath._(path));
  }

  String asString() {
    return p.joinAll(pathElements);
  }
}

/* + Main API + */

enum CrossReadError implements Exception {} // TODO

sealed class CrossReadHandle {
  Future<Result<CrossFilesystemItem, CrossReadError>> read();
}

// enum CrossReadHandleError implements Exception {} // TODO

/// Normally, the user will only interact with [CrossReadHandleRequest] through [showOpenFilePicker].
/// However, if a native user just wanted to get a file path from [showOpenFilePicker],
/// They could just write
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
  Future<CrossReadHandle> handle();
}

/// [showOpenFilePicker](https://developer.mozilla.org/en-US/docs/Web/API/Window/showOpenFilePicker)
/// already gives you a file handle on web, so a [WebHandleRequest] is just a newtype wrapper for it
/// that implements [CrossReadHandleRequest].
class WebHandleRequest extends CrossReadHandleRequest {
  final WebReadHandle
  webHandle; // The web's [showOpenFilePicker] function already gives us a file handle, so the request object just stores it for later.

  WebHandleRequest({required this.webHandle});

  @override
  Future<CrossReadHandle> handle() {
    return Future.syncValue(webHandle);
  }
}

class NativeHandleRequest extends CrossReadHandleRequest {
  final CrossPath path;

  NativeHandleRequest({required this.path});

  @override
  Future<CrossReadHandle> handle() async {
    final stringPath = path.asString();
    final type = await FileSystemEntity.type(stringPath);

    final filesystemEntity = switch (type) {
      FileSystemEntityType.file => File(stringPath),
      FileSystemEntityType.directory => Directory(stringPath),
      FileSystemEntityType.notFound => throw FileSystemException(
        'Entity not found',
        stringPath,
      ),
      _ => throw UnsupportedError('Unsupported file system entity type'),
    };

    return NativeReadHandle(entity: filesystemEntity);
  }
}

Future<CrossReadHandleRequest> showOpenFilePicker({
    String? label,
    List<String>? allowedExtensions,
    List<String>? uniformTypeIdentifiers,
    List<String>? webWildCards,
  }) {
  XTypeGroup typeGroup = XTypeGroup(
    label: label,
    extensions: allowedExtensions,
    uniformTypeIdentifiers: uniformTypeIdentifiers,
    webWildCards: webWildCards
  );

  if (kIsWeb)
  
  await openFile(
    acceptedTypeGroups: <XTypeGroup>[typeGroup],
  );
} // TODO

class WebReadHandle extends CrossReadHandle {
  @override
  Future<Result<CrossFilesystemItem<CrossFilesystemData>, CrossReadError>>
  read() {
    // TODO: implement read
    throw UnimplementedError();
  }
}

class NativeReadHandle extends CrossReadHandle {
  final FileSystemEntity entity;

  NativeReadHandle({required this.entity});

  @override
  Future<Result<CrossFilesystemItem<CrossFilesystemData>, CrossReadError>>
  read() {
    // TODO: implement read
    throw UnimplementedError();
  }
}

sealed class CrossWriteHandleRequest {
  Future<Result<CrossWriteHandle>> handle();
}

class WebWriteHandleRequest extends CrossWriteHandleRequest {}

class NativeWriteHandleRequest extends CrossWriteHandleRequest {
  final CrossPath writeTo;
}

CrossWriteHandleRequest showSaveFilePicker() {}

enum CrossWriteError implements Exception {}

sealed class CrossWriteHandle {
  Future<Result<(), CrossWriteError>> write(CrossFilesystemItem item);
}

class WebWriteHandle extends CrossWriteHandle {
  @override
  Future<Result<(), CrossWriteError>> write(
    CrossFilesystemItem<CrossFilesystemData> item,
  ) {
    // TODO: implement write
    throw UnimplementedError();
  }
}

/// If someone wants to write a file to a specific folder on native, they can just
/// [NativeWriteHandle(Path.fromString("./some/file/location").unwrap()).write(file);]
/// Which would throw an unsupported error on web.
class NativeWriteHandle extends CrossWriteHandle {
  @override
  Future<Result<(), CrossWriteError>> write(
    CrossFilesystemItem<CrossFilesystemData> item,
  ) {
    // TODO: implement write
    throw UnimplementedError();
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
  static Result<(), CrossFilesystemNameError> _validate(String fullFilename) {
    if (fullFilename.isEmpty) {
      return Failure(CrossFilesystemNameError.empty);
    }

    if (fullFilename.length > maxPath) {
      return Failure(CrossFilesystemNameError.exceedingLength);
    }

    if (fullFilename.endsWith('.')) {
      return Failure(CrossFilesystemNameError.endingPeriod);
    }

    // if (fullFilename.codeUnits.any((c) => c < 32 || c > 126)) {
    //   return Failure(CrossFilesystemNameError.nonAscii);
    // }

    if (fullFilename.contains(RegExp(r'[<>:"/\\|?*]'))) {
      return Failure(CrossFilesystemNameError.forbiddenCharacters);
    }

    // if (fullFilename != fullFilename.toLowerCase()) {
    //   return Failure(CrossFilesystemNameError.nonLowercase);
    // }

    if (fullFilename.trim().length != fullFilename.length) {
      return Failure(CrossFilesystemNameError.beginningOrEndingWithWhitespace);
    }

    return Success(());
  }

  static Result<CrossFilesystemName, CrossFilesystemNameError> create(
    String fullFilename,
  ) {
    return _validate(
      fullFilename,
    ).map((_) => CrossFilesystemName._(fullFilename));
  }
}
