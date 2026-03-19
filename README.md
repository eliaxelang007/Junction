## Junction

Junction is a Dart library that provides an API for working with the native filesystem, the web filesystem, and web origin private file filesystem (OPFS)!

## Usage

> WARNING: These snippets are still untested!

### Platform Detection

```dart
detectedPlatform // Depending on where you're running your code, this constant could be [Platform.web], [Platform.native], or [null].

// If you try to use functionality that doesn't work on the platform you're running on, 
// `junction` throws an error.
```

### Web Write

```dart
final newFile = CrossInMemoryFile(
    name: CrossFilesystemName("settings.json"),
    // This line is convenience for CrossFileData(bytes: utf8.encode(jsonEncode(json)))
    data: CrossFileData.fromJson({"theme": "dark", "version": "1.0.0"}),
);

await WebWriteHandle.showSaveFileDialog(newFile);
```

### Web Read

```dart
final readHandles = await WebReadHandle.showOpenFileDialog(
    multiple: false,
    accept: [
        XTypeGroup(extensions: ['json']),
    ],
);

if (readHandles.isEmpty) {
    return; // The file dialog was exited.
}

final fileItem = await readHandles.first.read();

final filename = fileItem.key;
final fileBytes = fileItem.value;

// This line is a convenience method for jsonDecode(utf8.decode(fileBytes.bytes))
final settings = fileBytes
    .toJson(); // ex. {"theme": "dark", "version": "1.0.0"}
```

### Native Write

```dart
final appFolder = CrossPath.fromString("C:/Example/Folder/Path");

final mySettings = CrossInMemoryFile(
    name: CrossFilesystemName("settings.json"),
    // This line is convenience for CrossFileData(bytes: utf8.encode(jsonEncode(json)))
    data: CrossFileData.fromJson({"theme": "dark", "version": "1.0.0"}),
);

// This line will get a handle to the directory that you want to write to.
final writeHandle = await NativeWriteHandle.fromPath(appFolder);

// This line will create `C:/Example/Folder/Path/settings.json` with
// `{"theme": "dark", "version": "1.0.0"}` as its content.
await writeHandle.write(mySettings);
```

### Native Write

```dart
final settingsFilePath = CrossPath.fromString(
    "C:/Example/Folder/Path/settings.json",
);

final readHandle = await NativeReadHandle.fromPath(settingsFilePath);

final fileItem = await readHandle.read();
final fileBytes = fileItem.value as CrossFileData;

// This line is a convenience method for jsonDecode(utf8.decode(fileBytes.bytes))
final settings = fileBytes
    .toJson(); // ex. {"theme": "dark", "version": "1.0.0"}
```


### Web OPFS Write

```dart
final appFolder = CrossPath.fromStrings(["Example", "Folder", "Path"]);

final mySettings = CrossInMemoryFile(
    name: CrossFilesystemName("settings.json"),
    // This line is convenience for CrossFileData(bytes: utf8.encode(jsonEncode(json)))
    data: CrossFileData.fromJson({"theme": "dark", "version": "1.0.0"}),
);

// This line will get a handle to the directory that you want to write to.
final writeHandle = await WebOpfsWriteHandle.fromPath(appFolder);

// This line will create `C:/Example/Folder/Path/settings.json` with
// `{"theme": "dark", "version": "1.0.0"}` as its content.
await writeHandle.write(mySettings);
```

### Web OPFS Read

```dart
final settingsFilePath = CrossPath.fromStrings([
    "Example",
    "Folder",
    "Path",
    "settings.json",
]);

final readHandle = await WebOpfsReadHandle.fromPath(settingsFilePath);

final fileItem = await readHandle.read();
final fileBytes = fileItem.value as CrossFileData;

// This line is a convenience method for jsonDecode(utf8.decode(fileBytes.bytes))
final settings = fileBytes
    .toJson(); // ex. {"theme": "dark", "version": "1.0.0"}
```

## Getting started

To get started, install this package by writing

```bash
dart pub add junction
```

In the terminal.
That's all you need to do!