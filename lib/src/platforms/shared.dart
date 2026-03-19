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
    "A filename can't contain '<', '>', '\"', '/', '\\', '|', '?', or '*'!", // ':',
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

    if (fullFilename.contains(RegExp(r'[<>"/\\|?*]'))) {
      // ':' excluded to allow for "C:" in file paths.
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

  static CrossPath fromStrings(Iterable<String> path) {
    return CrossPath(
      path.map((maybePart) => CrossFilesystemName(maybePart)).toList(),
    );
  }

  static CrossPath fromString(String maybePath) {
    return CrossPath.fromStrings(p.split(maybePath));
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

/* - Error Handling - */

/* + file_selector_web + */

/* https://github.com/flutter/packages/blob/main/packages/file_selector/file_selector_platform_interface/lib/src/types/x_type_group.dart */

// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// A set of allowed XTypes.
class XTypeGroup {
  /// Creates a new group with the given label and file extensions.
  ///
  /// A group with none of the type options provided indicates that any type is
  /// allowed.
  const XTypeGroup({
    this.label,
    List<String>? extensions,
    this.mimeTypes,
    List<String>? uniformTypeIdentifiers,
    this.webWildCards,
    @Deprecated('Use uniformTypeIdentifiers instead') List<String>? macUTIs,
  }) : _extensions = extensions,
       assert(
         uniformTypeIdentifiers == null || macUTIs == null,
         'Only one of uniformTypeIdentifiers or macUTIs can be non-null',
       ),
       uniformTypeIdentifiers = uniformTypeIdentifiers ?? macUTIs;

  /// The 'name' or reference to this group of types.
  final String? label;

  /// The MIME types for this group.
  final List<String>? mimeTypes;

  /// The uniform type identifiers for this group
  final List<String>? uniformTypeIdentifiers;

  /// The web wild cards for this group (ex: image/*, video/*).
  final List<String>? webWildCards;

  final List<String>? _extensions;

  /// The extensions for this group.
  List<String>? get extensions {
    return _removeLeadingDots(_extensions);
  }

  /// Converts this object into a JSON formatted object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'label': label,
      'extensions': extensions,
      'mimeTypes': mimeTypes,
      'uniformTypeIdentifiers': uniformTypeIdentifiers,
      'webWildCards': webWildCards,
      // This is kept for backwards compatibility with anything that was
      // relying on it, including implementers of `MethodChannelFileSelector`
      // (since toJSON is used in the method channel parameter serialization).
      'macUTIs': uniformTypeIdentifiers,
    };
  }

  /// True if this type group should allow any file.
  bool get allowsAny {
    return (extensions?.isEmpty ?? true) &&
        (mimeTypes?.isEmpty ?? true) &&
        (uniformTypeIdentifiers?.isEmpty ?? true) &&
        (webWildCards?.isEmpty ?? true);
  }

  /// Returns the list of uniform type identifiers for this group
  @Deprecated('Use uniformTypeIdentifiers instead')
  List<String>? get macUTIs => uniformTypeIdentifiers;

  static List<String>? _removeLeadingDots(List<String>? exts) => exts
      ?.map((String ext) => ext.startsWith('.') ? ext.substring(1) : ext)
      .toList();
}

/* - file_selector_web - */
