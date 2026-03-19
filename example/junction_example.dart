import 'package:junction/junction.dart';

Future<void> webWrite() async {
  final newFile = CrossInMemoryFile(
    name: CrossFilesystemName("settings.json"),
    // This line is convenience for CrossFileData(bytes: utf8.encode(jsonEncode(json)))
    data: CrossFileData.fromJson({"theme": "dark", "version": "1.0.0"}),
  );

  await WebWriteHandle.showSaveFileDialog(newFile);
}

Future<void> webRead() async {
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
}

Future<void> nativeWrite() async {
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
}

Future<void> nativeRead() async {
  final settingsFilePath = CrossPath.fromString(
    "C:/Example/Folder/Path/settings.json",
  );

  final readHandle = await NativeReadHandle.fromPath(settingsFilePath);

  final fileItem = await readHandle.read();
  final fileBytes = fileItem.value as CrossFileData;

  // This line is a convenience method for jsonDecode(utf8.decode(fileBytes.bytes))
  final settings = fileBytes
      .toJson(); // ex. {"theme": "dark", "version": "1.0.0"}
}

Future<void> opfsWrite() async {
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
}

Future<void> opfsRead() async {
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
}
