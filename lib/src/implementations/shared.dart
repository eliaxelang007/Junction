// import "../sealer.dart";

sealed class CrossReadHandle {
	Future<Result<FilesystemItem, /* Some error type */>> read(); // Something like that?
}

sealed class CrossReadHandleRequest {
	/*
	Since the open file dialog already gives you a file handle on web, it should just return that wrapped in [WebReadHandle].
	For native, it should give you `dart:io`'s analog for linux file descriptors, and wrap it in [NativeReadHandle]! 
	*/
	Future<Result<CrossReadHandle, /* Some error type */>> handle() async;
}

/* 
Normally, the user will only interact with CrossReadhandleRequest.
But, if a native user wants to get access to the file's path for example,
the could just go

if (handle is NativeReadRequest) {
	// Do something with [handle.path]
}

Which abstracts away the platform most of the time but still allows for specific platform handling!
*/
class WebHandleRequest extends CrossReadHandleRequest { 
	final WebHandle handle; // The web's [showOpenFilePicker] function already gives us a file handle, so the request object just stores it for later.
	
	/* Can we make it so that this is still available to import even in native environments, but it just throws errors when it's used? */
}
class NativeHandleRequest extends CrossReadHandleRequest {
	final Path path;
	
	/* Can we make it so that this is still available to import even in web environments, but it just throws errors when it's used? */
}
/**/

CrossReadHandleRequest showOpenFilePicker() {}

/* These two types should also be hidden, and users will only normally interact with CrossFilesystemHandle. */
class WebReadHandle extends CrossReadHandle {}
class NativeReadHandle extends CrossReadHandle {}
/**/

CrossReadHandle handle = (await showOpenFilePicker().handle()).unwrap();

// I treat Files like MapEntry<String, Uint8List> where the string is the filename and the Uint8List is the file data;
// I treat folders like MapEntry<String, Map<String, Uint8List>> where the string is the foldername and the Map<String, Folder | File> is its children!

FilesystemItem file = /* await */ handle.read().unwrap();
FilesystemItem folder = /* await */ handle.read().unwrap();

// File and folder are both [FilesystemItem]s

sealed class CrossWriteHandleRequest {
	Future<Result<CrossWriteHandle, /* Some error type */>> handle() async;
}

class WebWriteHandleRequest extends CrossWriteHandleRequest {}
class NativeWriteHandleRequest extends CrossWriteHandleRequest {
	final Path writeTo; 
}

sealed class CrossWriteHandle {
	Future<Result<void, /* Some error type */>> write(FilesystemItem item) async;
}

class WebWriteHandle extends CrossWriteHandle {}
class NativeWriteHandle extends CrossWriteHandle {}

CrossWriteHandleRequest showSaveFilePicker() {}

CrossWriteHandle handle = (await showSaveFilePicker().handle()).unwrap();

handle.write(file); // OR
handle.write(folder);

/*
If someone wants to write a file to a specific folder on native, they can just

NativeWriteRequest(Path.fromString("./some/file/location").unwrap()).write(file);

Which would throw an unsupported error on web.
*/
```