import 'package:result_type/result_type.dart';
import "dart:typed_data";
import "dart:convert";

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

typedef CrossFolder = MapEntry<CrossFilesystemName, CrossFolderData>;

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
  static Result<Null, CrossPathError> _validate(
    List<CrossFilesystemName> path,
  ) {
    if (path.isEmpty) {
      return Failure(CrossPathError.empty);
    }

    return Success(null);
  }

  static Result<CrossPath, CrossPathError> create(
    List<CrossFilesystemName> path,
  ) {
    return _validate(path).map((_) => CrossPath._(path));
  }
}

sealed class CrossFilesystemHandle {
  final CrossPath path;

  CrossFilesystemHandle({required this.path});
}

class CrossFileHandle extends CrossFilesystemHandle {
  CrossFileHandle({required super.path});

  Future<Result<CrossFile>> loadAsync() async {
    return null; // TODO!
  }
}

class CrossFolderHandle extends CrossFilesystemHandle {
  CrossFolderHandle({required super.path});

  Future<Result<CrossFolder>> loadAsync() async {
    return null; // TODO!
  }
}

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
  static Result<Null, CrossFilesystemNameError> _validate(String fullFilename) {
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

    return Success(null);
  }

  static Result<CrossFilesystemName, CrossFilesystemNameError> create(
    String fullFilename,
  ) {
    return _validate(
      fullFilename,
    ).map((_) => CrossFilesystemName._(fullFilename));
  }
}
