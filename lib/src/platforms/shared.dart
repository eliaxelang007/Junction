import "dart:convert";
import "dart:typed_data";
import "package:path/path.dart" as p;

/* + Filesystem Names + */
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

/// This is a String extension type that validates it according to [CrossFilesystemName._validate].
/// It holds up the invariants listed in [CrossFilesystemNameError].
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
/* - Filesystem Names - */

/* + Filesystem Data + */
/// This represents either a [CrossFileData], which is just a newtype for bytes, or
/// a [CrossFolderData] which is just a newtype for [Map<CrossFilesystemName, CrossFilesystemData>].
sealed class CrossFilesystemData {}

typedef CrossFilesystemItem<Data extends CrossFilesystemData> =
    MapEntry<CrossFilesystemName, Data>;
// typedef AnyCrossFilesystemItem = CrossFilesystemItem<CrossFilesystemData>;

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

class CrossFolderData extends CrossFilesystemData {
  final CrossFolderChildren children;

  CrossFolderData({required this.children});
}

extension type CrossFolderChildren._(
  Map<CrossFilesystemName, CrossFilesystemData> _children
)
    implements Map<CrossFilesystemName, CrossFilesystemData> {
  static CrossFolderChildren fromEntries(
    Iterable<CrossFilesystemItem<CrossFilesystemData>> children,
  ) {
    return CrossFolderChildren._(Map.fromEntries(children));
  }
}
/* - Filesystem Data - */

/* + In Memory + */
extension type CrossInMemoryFile._(CrossFilesystemItem<CrossFileData> _file)
    implements CrossFilesystemItem<CrossFileData> {
  factory CrossInMemoryFile({
    required CrossFilesystemName name,
    required CrossFileData data,
  }) {
    return CrossInMemoryFile._(CrossFilesystemItem<CrossFileData>(name, data));
  }
}

extension type CrossInMemoryFolder._(
  CrossFilesystemItem<CrossFolderData> _folder
)
    implements CrossFilesystemItem<CrossFolderData> {
  factory CrossInMemoryFolder({
    required CrossFilesystemName name,
    required CrossFolderData data,
  }) {
    return CrossInMemoryFolder._(
      CrossFilesystemItem<CrossFolderData>(name, data),
    );
  }
}
/* - In Memory - */

/* + Paths + */
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

  CrossFilesystemName basename() {
    return pathElements.last;
  }

  CrossPath operator +(CrossPath trailing) {
    return CrossPath._(pathElements + trailing.pathElements);
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
/* - Paths - */

/* + Error Handling */
class JunctionException implements Exception {
  final String? message;

  JunctionException(this.message);

  @override
  String toString() {
    return (message != null)
        ? "JunctionException($message)"
        : "JunctionException";
  }
}

/// This is a version of assert that doesn't get disabled in production.
/// See https://dart.dev/language/error-handling#assert
void enforce(bool condition, [String? message]) {
  if (condition) {
    return;
  }
  throw JunctionException(message);
}

/* - Error Handling - */
