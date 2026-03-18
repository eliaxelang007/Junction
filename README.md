Junction is a library that provides a unified API for working with the filesystem in both web and native environments!

## Features

This library provides

* file name and file path validation,
* file and folder handles,
* file and folder reading, and
* file and folder writing

with a unified API that limits you to the web platform but provides
"slots" where you can use the more robust native functionality!

## Getting started

To get started, install this package by writing

```bash
dart pub add junction
```

And that's all you need to do!


# Explanation

```dart
class CrossPath {}

extension CrossPathExtension on CrossPath {
    // Future<CrossReadHandle> toReadHandle()
    // Future<CrossReadHandle> toWriteHandle()
}

/* + Reading + */

sealed class CrossReadHandle {
    Future<AnyCrossFilesystemItem> read();
}

class NativeReadHandle extends CrossReadHandle {
    // static Future<NativeReadHandle> fromPath(CrossPath path)
}

class WebReadHandle extends CrossReadHandle {}

/* - Reading - */

/* + Writing + */

sealed class CrossWriteHandle {
    // Future<void> write(AnyCrossFilesystemItem item)
}

class NativeWriteHandle extends CrossWriteHandle {
    // static Future<NativeWriteHandle> fromPath(CrossPath path)
}

class WebWriteHandle extends CrossWriteHandle {}

/* - Writing - */
```

## Innards explanation



### Reading A File

* First, you have to create a request for a read handle to a file. 
    * You can do this by instantiating a variant of [CrossReadHandleRequest](https://pub.dev/documentation/junction/latest/junction/CrossReadHandleRequest-class.html), namely
        * [NativeReadHandleRequest](https://pub.dev/documentation/junction/latest/junction/NativeReadHandleRequest-class.html) and
        * [WebReadHandleRequest](https://pub.dev/documentation/junction/latest/junction/WebReadHandleRequest-class.html).

> On native, a [NativeReadHandleRequest](https://pub.dev/documentation/junction/latest/junction/NativeReadHandleRequest-class.html) really just contains a filesystem path!

> On web, you can't just read the filesystem willy nilly. The user needs to allow you to read a file, and browsers do this by opening a file dialog to let them choose what you can have access to.

> I would have loved to write junction to use the filesystem access api's [showOpenFilePicker](https://developer.mozilla.org/en-US/docs/Web/API/Window/showOpenFilePicker) (not junction's one), which gives you a file handle. Alas, [showOpenFilePicker](https://developer.mozilla.org/en-US/docs/Web/API/Window/showOpenFilePicker) is not supported on Firefox, so junction uses the more limited [File API](https://developer.mozilla.org/en-US/docs/Web/API/File_API) instead. 

> In any case a [WebReadHandleRequest](https://pub.dev/documentation/junction/latest/junction/WebReadHandleRequest-class.html) already contains the raw js handle itself wrapped in a [WebReadHandle](https://pub.dev/documentation/junction/latest/junction/WebReadHandle-class.html). 

> If you try to instantiate a handle request on an unsupported platform, an exception is thrown.

* Next, you have to get a read handle from the read handle request.
    * [CrossReadHandleRequest.handle()](https://pub.dev/documentation/junction/latest/junction/CrossReadHandleRequest-class.html) is just for that! 
    * It gives you a [CrossReadHandle](https://pub.dev/documentation/junction/latest/junction/CrossReadHandle-class.html) whose variants are 
        * [NativeReadHandle](https://pub.dev/documentation/junction/latest/junction/NativeReadHandle-class.html) and 
        * [WebReadHandle](https://pub.dev/documentation/junction/latest/junction/WebReadHandle-class.html).

> On native, junction just uses "dart:io" to create a file handle from the path inside [NativeReadHandleRequest](https://pub.dev/documentation/junction/latest/junction/NativeReadHandleRequest-class.html). This file handle is wrapped in [NativeReadHandle](https://pub.dev/documentation/junction/latest/junction/NativeReadHandle-class.html).

> On web, [WebReadHandleRequest](https://pub.dev/documentation/junction/latest/junction/WebReadHandleRequest-class.html) just gives you the [WebReadHandle](https://pub.dev/documentation/junction/latest/junction/WebReadHandle-class.html) inside of it.
* Finally, you can call [CrossReadHandle.read](https://pub.dev/documentation/junction/latest/junction/CrossReadHandle/read.html) that gives you an [AnyCrossFilesystemItem](https://pub.dev/documentation/junction/latest/junction/AnyCrossFilesystemItem.html) that's basically a file ([CrossFile](https://pub.dev/documentation/junction/latest/junction/CrossFile-extension-type.html)) or a folder ([CrossFolder](https://pub.dev/documentation/junction/latest/junction/CrossFolder.html)) loaded into memory!

### Writing A File

Writing a file follows mostly the same pattern as reading a file.

* First, you have to create a request for a write handle to a file. 
    * To do that, create an instance of [CrossWriteHandleRequest](https://pub.dev/documentation/junction/latest/junction/CrossWriteHandleRequest-class.html) whose variants are
        * [NativeWriteHandleRequest](https://pub.dev/documentation/junction/latest/junction/NativeWriteHandleRequest-class.html) and
        * [WebWriteHandleRequest](https://pub.dev/documentation/junction/latest/junction/WebWriteHandleRequest-class.html).

> On native, a [NativeWriteHandleRequest](https://pub.dev/documentation/junction/latest/junction/NativeWriteHandleRequest-class.html) really just contains a filesystem path!

> On web, because this library uses the old [File API](https://developer.mozilla.org/en-US/docs/Web/API/File_API), a [WebWriteHandleRequest](https://pub.dev/documentation/junction/latest/junction/WebWriteHandleRequest-class.html) is just an empty class.

* Next, you have to get a write handle from the handle request. 
    * To do that, call [CrossWriteHandleRequest.handle()](https://pub.dev/documentation/junction/latest/junction/CrossWriteHandleRequest/handle.html).
    * This gives you a [CrossWriteHandle](https://pub.dev/documentation/junction/latest/junction/CrossWriteHandle-class.html) whose variants are
        * [NativeWriteHandle](https://pub.dev/documentation/junction/latest/junction/NativeWriteHandle-class.html) and
        * [WebWriteHandle](https://pub.dev/documentation/junction/latest/junction/WebWriteHandle-class.html).

> On native, junction just uses "dart:io" to create a file handle from the path inside [NativeWriteHandleRequest](https://pub.dev/documentation/junction/latest/junction/NativeReadHandleRequest-class.html). This file handle is wrapped in [NativeReadHandle](https://pub.dev/documentation/junction/latest/junction/NativeReadHandle-class.html).

For more, check out [this documentation page](https://pub.dev/documentation/junction/latest/)!