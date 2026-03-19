import 'dart:async';
import 'dart:typed_data';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart';

import 'shared.dart';

const String _nativeUnsupportedMessage =
    "Your program is running on the web, so it can only use web functionality!";

/* + Reading + */
sealed class CrossReadHandle<Data extends CrossFilesystemData> {
  Future<CrossFilesystemItem<Data>> read();
}

class NativeReadHandle extends CrossReadHandle<CrossFilesystemData> {
  static Future<NativeReadHandle> fromPath(CrossPath path) {
    throw UnsupportedError(_nativeUnsupportedMessage);
  }

  @override
  Future<CrossFilesystemItem<CrossFilesystemData>> read() {
    throw UnsupportedError(_nativeUnsupportedMessage);
  }
}

extension on FileSystemDirectoryHandle {
  Future<FileSystemHandle> traverse(CrossPath path) async {
    final pathString = path.asString();

    final pathElements = path.pathElements;
    final pathElementsLastIndex = pathElements.length - 1;

    var currentDirectory = this;

    for (int i = 0; i < pathElementsLastIndex; i++) {
      try {
        currentDirectory = await currentDirectory
            .getDirectoryHandle(pathElements[i])
            .toDart;
      } on DOMException catch (e) {
        if (e.name == "NotFoundError") {
          throw JunctionException("Path not found: $pathString");
        }
      }
    }

    final lastPathPart = pathElements[pathElementsLastIndex];

    try {
      return await currentDirectory.getFileHandle(lastPathPart).toDart;
    } on DOMException catch (e) {
      if (e.name == "NotFoundError") {
        throw JunctionException("Path not found: ${path.asString()}");
      }
    }

    try {
      return await currentDirectory.getDirectoryHandle(lastPathPart).toDart;
    } on DOMException catch (e) {
      if (e.name == "NotFoundError") {
        throw JunctionException("Path not found: ${path.asString()}");
      }
    }

    throw JunctionException(
      "Unsupported file system entity type at: $pathString",
    );
  }
}

class WebOpfsReadHandle extends CrossReadHandle<CrossFilesystemData> {
  final FileSystemHandle _filesystemEntity;

  WebOpfsReadHandle._({required FileSystemHandle filesystemEntity})
    : _filesystemEntity = filesystemEntity;

  static Future<WebOpfsReadHandle> fromPath(CrossPath path) async {
    return WebOpfsReadHandle._(
      filesystemEntity:
          await (await window.navigator.storage.getDirectory().toDart).traverse(
            path,
          ),
    );
  }

  @override
  Future<CrossFilesystemItem<CrossFilesystemData>> read() async {
    return await _readFilesystemItem(_filesystemEntity);
  }

  static Future<CrossFilesystemItem<CrossFilesystemData>> _readFilesystemItem(
    FileSystemHandle filesystemEntity,
  ) async {
    final filename = CrossFilesystemName(filesystemEntity.name);

    if (filesystemEntity.kind == "file") {
      final fileHandle = filesystemEntity as FileSystemFileHandle;

      return CrossInMemoryFile(
        name: filename,
        data: CrossFileData(
          bytes:
              (await (await fileHandle.getFile().toDart).arrayBuffer().toDart)
                  .toDart
                  .asUint8List(),
        ),
      );
    }

    if (filesystemEntity.kind == "directory") {
      final directoryHandle = filesystemEntity as FileSystemDirectoryHandle;

      return CrossInMemoryFolder(
        name: filename,
        data: CrossFolderData(
          children: CrossFolderChildren.fromEntries(
            await Future.wait(
              await directoryHandle
                  .list() // We don't handle links yet!
                  .map(_readFilesystemItem)
                  .toList(),
            ),
          ),
        ),
      );
    }

    final rootDirectory = await window.navigator.storage.getDirectory().toDart;

    final path = (await rootDirectory.resolve(filesystemEntity).toDart)?.toDart
        .map((pathPart) => pathPart.toDart);

    var exceptionMessage = "Unsupported file system entity type";

    if (path != null) {
      exceptionMessage += " at: ${CrossPath.fromStrings(path).asString()}";
    }

    throw JunctionException(exceptionMessage);
  }
}

extension on FileSystemDirectoryHandle {
  Stream<FileSystemHandle> list() async* {
    final iterator = callMethod<JSObject>('values'.toJS);

    while (true) {
      final nextPromise = iterator.callMethod<JSPromise<JSObject>>('next'.toJS);

      final next = await nextPromise.toDart;

      final isDone = next.getProperty<JSBoolean>('done'.toJS).toDart;

      if (isDone) {
        break;
      }

      yield next.getProperty<FileSystemHandle>('value'.toJS);
    }
  }
}

class WebReadHandle extends CrossReadHandle<CrossFileData> {
  final File _filesystemEntity;

  WebReadHandle._({required File filesystemEntity})
    : _filesystemEntity = filesystemEntity;

  static Future<List<WebReadHandle>> showOpenFileDialog({
    List<XTypeGroup>? accept,
    bool multiple = false,
  }) async {
    return (await showOpenFilePicker(accept: accept, multiple: multiple))
        .map(
          (filesystemEntity) =>
              WebReadHandle._(filesystemEntity: filesystemEntity),
        )
        .toList();
  }

  @override
  Future<CrossFilesystemItem<CrossFileData>> read() async {
    final completer = Completer<Uint8List>();
    final reader = FileReader();

    reader.onLoadEnd.listen((_) {
      final buffer = reader.result as JSArrayBuffer;
      completer.complete(buffer.toDart.asUint8List());
    });

    reader.readAsArrayBuffer(_filesystemEntity);
    final bytes = await completer.future;

    return CrossInMemoryFile(
      name: CrossFilesystemName(_filesystemEntity.name),
      data: CrossFileData(bytes: bytes),
    );
  }
}

/* + Writing + */
sealed class CrossWriteHandle<Data extends CrossFilesystemData> {
  Future<void> write(CrossFilesystemItem<Data> item);
}

class NativeWriteHandle extends CrossWriteHandle<CrossFilesystemData> {
  static Future<NativeWriteHandle> fromPath(CrossPath path) {
    throw UnsupportedError(_nativeUnsupportedMessage);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFilesystemData> item) {
    throw UnsupportedError(_nativeUnsupportedMessage);
  }
}

class WebOpfsWriteHandle extends CrossWriteHandle<CrossFilesystemData> {
  final FileSystemDirectoryHandle _destinationFolder;

  WebOpfsWriteHandle._({required FileSystemDirectoryHandle destinationFolder})
    : _destinationFolder = destinationFolder;

  static Future<WebOpfsWriteHandle> fromPath(
    CrossPath destinationFolder,
  ) async {
    final maybeDestinationFolder =
        await (await window.navigator.storage.getDirectory().toDart).traverse(
          destinationFolder,
        );

    if (maybeDestinationFolder.kind != "directory") {
      throw JunctionException(
        "[destinationFolder] must be a folder because it's what [CrossWriteHandle.write] will make the parent of what it's asked to write.",
      );
    }

    return WebOpfsWriteHandle._(
      destinationFolder: maybeDestinationFolder as FileSystemDirectoryHandle,
    );
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFilesystemData> item) async {
    await _writeFilesystemItem(_destinationFolder, item);
  }

  static Future<void> _writeFilesystemItem(
    FileSystemDirectoryHandle folderParent,
    CrossFilesystemItem<CrossFilesystemData> item,
  ) async {
    final name = item.key;
    final data = item.value;

    switch (data) {
      case CrossFileData(bytes: final bytes):
        {
          final fileHandle = await folderParent
              .getFileHandle(name, FileSystemGetFileOptions(create: true))
              .toDart;

          final writable = await fileHandle.createWritable().toDart;
          await writable.write(bytes.toJS).toDart;
          await writable.close().toDart;

          break;
        }

      case CrossFolderData(children: final children):
        {
          final newDirectory = await folderParent
              .getDirectoryHandle(
                name,
                FileSystemGetDirectoryOptions(create: true),
              )
              .toDart;

          await Future.wait(
            children.entries.map(
              (child) => _writeFilesystemItem(newDirectory, child),
            ),
          );

          break;
        }
    }
  }
}

class WebWriteHandle extends CrossWriteHandle<CrossFileData> {
  static Future<void> showSaveFileDialog(
    CrossFilesystemItem<CrossFileData> item,
  ) async {
    await WebWriteHandle().write(item);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFileData> item) async {
    final data = item.value;
    final filename = item.key.toString();

    final blob = Blob([data.bytes.toJS].toJS);
    final url = URL.createObjectURL(blob);

    final anchor = document.createElement('a') as HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;

    document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    URL.revokeObjectURL(url);
  }
}
/* - Writing - */

/* + file_selector_web + */

/* https://github.com/flutter/packages/blob/main/packages/file_selector/file_selector_web/lib/src/utils.dart */

// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Convert list of XTypeGroups to a comma-separated string
String acceptedTypesToString(List<XTypeGroup>? acceptedTypes) {
  if (acceptedTypes == null) {
    return '';
  }
  final allTypes = <String>[];
  for (final XTypeGroup group in acceptedTypes) {
    // If any group allows everything, no filtering should be done.
    if (group.allowsAny) {
      return '';
    }
    _validateTypeGroup(group);
    if (group.extensions != null) {
      allTypes.addAll(group.extensions!.map(_normalizeExtension));
    }
    if (group.mimeTypes != null) {
      allTypes.addAll(group.mimeTypes!);
    }
    if (group.webWildCards != null) {
      allTypes.addAll(group.webWildCards!);
    }
  }
  return allTypes.join(',');
}

/// Make sure that at least one of the supported fields is populated.
void _validateTypeGroup(XTypeGroup group) {
  if ((group.extensions?.isEmpty ?? true) &&
      (group.mimeTypes?.isEmpty ?? true) &&
      (group.webWildCards?.isEmpty ?? true)) {
    throw ArgumentError(
      'Provided type group $group does not allow '
      'all files, but does not set any of the web-supported filter '
      'categories. At least one of "extensions", "mimeTypes", or '
      '"webWildCards" must be non-empty for web if anything is '
      'non-empty.',
    );
  }
}

/// Append a dot at the beggining if it is not there png -> .png
String _normalizeExtension(String ext) {
  return ext.isNotEmpty && ext[0] != '.' ? '.$ext' : ext;
}

// https://github.com/flutter/packages/blob/main/packages/file_selector/file_selector_web/lib/src/dom_helper.dart

Future<List<File>> showOpenFilePicker({
  List<XTypeGroup>? accept,
  bool multiple = false,
}) {
  final completer = Completer<List<File>>();
  final fileInput = (document.createElement('input') as HTMLInputElement)
    ..style.display = "none"
    ..type = "file"
    ..multiple = multiple
    ..accept = acceptedTypesToString(accept);

  document.body!.appendChild(fileInput);

  fileInput.onChange.first.then((_) {
    final files = fileInput.files!;

    completer.complete(
      List.generate(files.length, (int index) => files.item(index)!),
    );

    fileInput.remove();
  });

  fileInput.addEventListener(
    'cancel',
    (Event event) {
      fileInput.remove();
      completer.complete([]);
    }.toJS,
  );

  fileInput.onError.first.then((Event event) {
    final error = event as ErrorEvent;

    fileInput.remove();
    completer.completeError(JunctionException(error.message));
  });

  // Don't reimplement this with the new Filesystem Access API like suggested in the link below!
  // https://github.com/flutter/flutter/issues/130365
  // I want to keep compatibility with Firefox.
  fileInput.click();

  return completer.future;
}

/* - file_selector_web - */
