export "platforms/shared.dart";
export 'platforms/stub.dart'
    if (dart.library.js_interop) 'platforms/web.dart'
    if (dart.library.io) 'platforms/native.dart';
