## Junction

Junction is a library that provides an API for working with the filesystem in both web and native environments!

> Check out the package `junction_selector` too! It's a library that gives you file selectors for Flutter that integrates well with `junction`.

## Usage

> WARNING: These snippets are still untested!

### Web Write

```dart
final newFile = CrossInMemoryFile(
    name: CrossFilesystemName("settings.json"),
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