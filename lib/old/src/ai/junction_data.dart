import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'dart:convert';

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
    if (path.isEmpty) return CrossPathError.empty;
    return null;
  }

  factory CrossPath(List<CrossFilesystemName> path) {
    final error = _validate(path);
    if (error != null) throw error;
    return CrossPath._(path);
  }

  String asString() => p.joinAll(pathElements);

  static CrossPath fromString(String maybePath) {
    return CrossPath(
      p
          .split(maybePath)
          .map((maybePart) => CrossFilesystemName(maybePart))
          .toList(),
    );
  }
}

const int maxPath = 255;

enum CrossFilesystemNameError implements Exception {
  empty("A filename can't be empty!"),
  exceedingLength("A filename can't be longer than $maxPath characters!"),
  forbiddenCharacters(
    "A filename can't contain '<', '>', ':', '\"', '/', '\\', '|', '?', or '*'!",
  ),
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
    if (fullFilename.isEmpty) return CrossFilesystemNameError.empty;
    if (fullFilename.length > maxPath)
      return CrossFilesystemNameError.exceedingLength;
    if (fullFilename.endsWith('.'))
      return CrossFilesystemNameError.endingPeriod;
    if (fullFilename.contains(RegExp(r'[<>:"/\\|?*]')))
      return CrossFilesystemNameError.forbiddenCharacters;
    if (fullFilename.trim().length != fullFilename.length)
      return CrossFilesystemNameError.beginningOrEndingWithWhitespace;
    return null;
  }

  factory CrossFilesystemName(String fullFilename) {
    final error = _validate(fullFilename);
    if (error != null) throw error;
    return CrossFilesystemName._(fullFilename);
  }
}

void enforce(bool condition, [String? message]) {
  if (!condition) throw AssertionError(message);
}
