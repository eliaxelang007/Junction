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


# Usage

```dart
/* + Paths + */
class CrossPath { /* ... */ }

extension CrossPathExtension on CrossPath {
    Future<CrossReadHandle> toReadHandle();
    Future<CrossWriteHandle> toWriteHandle();
}
```

```dart
/* Reading */
sealed class CrossReadHandle {
    Future<AnyCrossFilesystemItem> read();
}

/* Details */
class NativeReadHandle extends CrossReadHandle {
    static Future<NativeReadHandle> fromPath(CrossPath path);
    /* ... */
}

class WebReadHandle extends CrossReadHandle {
    /* ... */
}

class WebOpfsReadHandle extends CrossReadHandle {
    /* ... */
}
```

```dart
/* Writing */
sealed class CrossWriteHandle {
    Future<void> write(AnyCrossFilesystemItem item);
}

/* Details */
class NativeWriteHandle extends CrossWriteHandle {
    static Future<NativeWriteHandle> fromPath(CrossPath path);
    /* ... */
}

class WebWriteHandle extends CrossWriteHandle {
    /* ... */
}

class WebOpfsReadHandle extends CrossWriteHandle {
    /* ... */
}
```