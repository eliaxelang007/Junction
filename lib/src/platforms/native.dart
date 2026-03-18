import 'dart:io';

import 'shared.dart';

const String _webUnsupportedMessage =
    "Your app is running on a native platform, so it can only use native functionality!";

/* + Reading + */
sealed class CrossReadHandle<Data extends CrossFilesystemData> {
  Future<CrossFilesystemItem<Data>> read();
}

class NativeReadHandle extends CrossReadHandle<CrossFilesystemData> {
  final FileSystemEntity filesystemEntity;

  NativeReadHandle._({required this.filesystemEntity});

  static Future<NativeReadHandle> fromPath(CrossPath readLocation) async {
    final readPath = readLocation.asString();
    final type = await FileSystemEntity.type(readPath);

    final filesystemEntity = switch (type) {
      FileSystemEntityType.notFound => throw JunctionException(
        "Path not found: $readPath",
      ),
      FileSystemEntityType.file => File(readPath),
      FileSystemEntityType.directory => Directory(readPath),
      _ => throw JunctionException(
        "Unsupported file system entity type at: $readPath",
      ),
    };

    return NativeReadHandle._(filesystemEntity: filesystemEntity);
  }

  @override
  Future<CrossFilesystemItem<CrossFilesystemData>> read() async {
    return await readFilesystemItem(filesystemEntity);
  }

  static Future<CrossFilesystemItem<CrossFilesystemData>> readFilesystemItem(
    FileSystemEntity filesystemEntity,
  ) async {
    final ioPath = filesystemEntity.path;
    final filename = CrossPath.fromString(ioPath).basename();

    if (filesystemEntity is File) {
      return CrossInMemoryFile(
        name: filename,
        data: CrossFileData(bytes: await filesystemEntity.readAsBytes()),
      );
    }

    if (filesystemEntity is Directory) {
      return CrossInMemoryFolder(
        name: filename,
        data: CrossFolderData(
          children: CrossFolderChildren.fromEntries(
            await Future.wait(
              await filesystemEntity
                  .list(followLinks: false) // We don't handle links yet!
                  .map(readFilesystemItem)
                  .toList(),
            ),
          ),
        ),
      );
    }

    throw JunctionException("Unsupported file system entity type at: $ioPath");
  }
}

class WebOpfsReadHandle extends CrossReadHandle<CrossFilesystemData> {
  static Future<WebOpfsReadHandle> fromPath(CrossPath path) {
    throw UnsupportedError(_webUnsupportedMessage);
  }

  @override
  Future<CrossFilesystemItem<CrossFilesystemData>> read() {
    throw UnsupportedError(_webUnsupportedMessage);
  }
}

class WebReadHandle extends CrossReadHandle<CrossFileData> {
  factory WebReadHandle() {
    throw UnsupportedError(_webUnsupportedMessage);
  }

  @override
  Future<CrossFilesystemItem<CrossFileData>> read() {
    throw UnsupportedError(_webUnsupportedMessage);
  }
}
/* - Reading - */

/* + Writing + */
sealed class CrossWriteHandle<Data extends CrossFilesystemData> {
  Future<void> write(CrossFilesystemItem<Data> item);
}

class NativeWriteHandle extends CrossWriteHandle<CrossFilesystemData> {
  final CrossPath destinationFolder;

  // Private constructor so it can only be instantiated via fromPath
  NativeWriteHandle._({required this.destinationFolder});

  static Future<NativeWriteHandle> fromPath(CrossPath destinationFolder) async {
    if ((await FileSystemEntity.type(destinationFolder.asString())) !=
        FileSystemEntityType.directory) {
      throw JunctionException(
        "[destinationFolder] must be a folder because it's what [CrossWriteHandle.write] will make the parent of what it's asked to write.",
      );
    }

    return NativeWriteHandle._(destinationFolder: destinationFolder);
  }

  //
  @override
  Future<void> write(CrossFilesystemItem<CrossFilesystemData> item) async {
    writeFilesystemItem(destinationFolder, item);
  }

  static Future<void> writeFilesystemItem(
    CrossPath folderParent,
    CrossFilesystemItem<CrossFilesystemData> inMemoryItem,
  ) async {
    final childPath = CrossPath([...folderParent, inMemoryItem.key]);
    final childPathString = childPath.asString();
    final data = inMemoryItem.value;

    if (data is CrossFileData) {
      final file = await File(childPathString).create(recursive: true);

      await file.writeAsBytes(data.bytes);

      return;
    }

    if (data is CrossFolderData) {
      await Directory(childPathString).create(recursive: true);

      for (final child in data.children.entries) {
        await writeFilesystemItem(childPath, child);
      }

      return;
    }

    throw JunctionException(
      "Unsupported file system entity type at: $childPathString",
    );
  }
}

class WebOpfsWriteHandle extends CrossWriteHandle<CrossFilesystemData> {
  static Future<WebOpfsWriteHandle> fromPath(CrossPath path) {
    throw UnsupportedError(_webUnsupportedMessage);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFilesystemData> item) {
    throw UnsupportedError(_webUnsupportedMessage);
  }
}

class WebWriteHandle extends CrossWriteHandle<CrossFileData> {
  factory WebWriteHandle() {
    throw UnsupportedError(_webUnsupportedMessage);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFileData> item) {
    throw UnsupportedError(_webUnsupportedMessage);
  }
}
/* - Writing - */