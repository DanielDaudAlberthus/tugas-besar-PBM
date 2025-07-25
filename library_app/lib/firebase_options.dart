// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC91JJl5c56J2E1PPI2SsrxxIkD6YUYEKM',
    appId: '1:510549445306:web:e1b7554aa3e0d68a6c9083',
    messagingSenderId: '510549445306',
    projectId: 'library-app-1944a',
    authDomain: 'library-app-1944a.firebaseapp.com',
    storageBucket: 'library-app-1944a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCWFk2lzJbVNO2S_xeorYM11jNc-yRCoVI',
    appId: '1:510549445306:android:6659781d781c02046c9083',
    messagingSenderId: '510549445306',
    projectId: 'library-app-1944a',
    storageBucket: 'library-app-1944a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCllQVeF6NBJTAOihRDuZljOKppCFeCvm8',
    appId: '1:510549445306:ios:120dc7dbd895f8206c9083',
    messagingSenderId: '510549445306',
    projectId: 'library-app-1944a',
    storageBucket: 'library-app-1944a.firebasestorage.app',
    iosBundleId: 'com.example.libraryApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCllQVeF6NBJTAOihRDuZljOKppCFeCvm8',
    appId: '1:510549445306:ios:120dc7dbd895f8206c9083',
    messagingSenderId: '510549445306',
    projectId: 'library-app-1944a',
    storageBucket: 'library-app-1944a.firebasestorage.app',
    iosBundleId: 'com.example.libraryApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC91JJl5c56J2E1PPI2SsrxxIkD6YUYEKM',
    appId: '1:510549445306:web:49c5752a20ec3e006c9083',
    messagingSenderId: '510549445306',
    projectId: 'library-app-1944a',
    authDomain: 'library-app-1944a.firebaseapp.com',
    storageBucket: 'library-app-1944a.firebasestorage.app',
  );
}
