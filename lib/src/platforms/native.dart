import 'dart:io';
import 'shared.dart';

const String _webUnsupportedMessage =
    "Your program is running on a native platform, so it can only use native functionality!";

/* + Reading + */
sealed class CrossReadHandle<Data extends CrossFilesystemData> {
  Future<CrossFilesystemItem<Data>> read();
}

class NativeReadHandle extends CrossReadHandle<CrossFilesystemData> {
  final FileSystemEntity _filesystemEntity;

  NativeReadHandle._({required FileSystemEntity filesystemEntity})
    : _filesystemEntity = filesystemEntity;

  static Future<NativeReadHandle> fromPath(CrossPath path) async {
    final pathString = path.asString();
    final type = await FileSystemEntity.type(pathString);

    final filesystemEntity = switch (type) {
      FileSystemEntityType.notFound => throw JunctionException(
        "Path not found: $pathString",
      ),
      FileSystemEntityType.file => File(pathString),
      FileSystemEntityType.directory => Directory(pathString),
      _ => throw JunctionException(
        "Unsupported file system entity type at: $pathString",
      ),
    };

    return NativeReadHandle._(filesystemEntity: filesystemEntity);
  }

  @override
  Future<CrossFilesystemItem<CrossFilesystemData>> read() async {
    return await _readFilesystemItem(_filesystemEntity);
  }

  static Future<CrossFilesystemItem<CrossFilesystemData>> _readFilesystemItem(
    FileSystemEntity filesystemEntity,
  ) async {
    final path = filesystemEntity.path;
    final filename = CrossPath.fromString(path).basename();

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
                  .map(_readFilesystemItem)
                  .toList(),
            ),
          ),
        ),
      );
    }

    throw JunctionException("Unsupported file system entity type at: $path");
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
  static Future<List<WebReadHandle>> showOpenFileDialog({
    List<XTypeGroup>? accept,
    bool multiple = false,
  }) async {
    throw UnimplementedError(_webUnsupportedMessage);
  }

  @override
  Future<CrossFilesystemItem<CrossFileData>> read() {
    throw UnimplementedError(_webUnsupportedMessage);
  }
}
/* - Reading - */

/* + Writing + */
sealed class CrossWriteHandle<Data extends CrossFilesystemData> {
  Future<void> write(CrossFilesystemItem<Data> item);
}

class NativeWriteHandle extends CrossWriteHandle<CrossFilesystemData> {
  final CrossPath _destinationFolder;

  NativeWriteHandle._({required CrossPath destinationFolder})
    : _destinationFolder = destinationFolder;

  static Future<NativeWriteHandle> fromPath(CrossPath destinationFolder) async {
    if ((await FileSystemEntity.type(destinationFolder.asString())) !=
        FileSystemEntityType.directory) {
      throw JunctionException(
        "[destinationFolder] must be a folder because it's what [CrossWriteHandle.write] will make the parent of what it's asked to write.",
      );
    }

    return NativeWriteHandle._(destinationFolder: destinationFolder);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFilesystemData> item) async {
    await _writeFilesystemItem(_destinationFolder, item);
  }

  static Future<void> _writeFilesystemItem(
    CrossPath folderParent,
    CrossFilesystemItem<CrossFilesystemData> item,
  ) async {
    final childPath = CrossPath([...folderParent, item.key]);
    final childPathString = childPath.asString();
    final data = item.value;

    switch (data) {
      case CrossFileData(bytes: final bytes):
        {
          final file = await File(childPathString).create(recursive: true);
          await file.writeAsBytes(bytes);

          break;
        }

      case CrossFolderData(children: final children):
        {
          await Directory(childPathString).create(recursive: true);

          await Future.wait(
            children.entries.map(
              (child) => _writeFilesystemItem(childPath, child),
            ),
          );

          break;
        }
    }
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
  static Future<WebWriteHandle> showSaveFileDialog() {
    throw UnimplementedError(_webUnsupportedMessage);
  }

  @override
  Future<void> write(CrossFilesystemItem<CrossFileData> item) {
    throw UnimplementedError(_webUnsupportedMessage);
  }
}
/* - Writing - */