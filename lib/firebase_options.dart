// Firebase configuration for the shared KIT305 project (test-minh-tute-5).
//
// These values come from the same Firebase project used by my Assignment 2/3
// apps, so this Flutter client reads/writes the same Firestore database.
//
// NOTE FOR MARKER: if you want to point the app at your own Firebase project,
// run `flutterfire configure` to regenerate this file, or swap the values below
// with the ones from your own project's GoogleService-Info.plist / google-services.json.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDUotyaZE7UCEzsM7F3XZZ6PtfUWx4oWzk',
    appId: '1:502315951774:ios:867988432d6f0c486f7d8f',
    messagingSenderId: '502315951774',
    projectId: 'test-minh-tute-5',
    storageBucket: 'test-minh-tute-5.firebasestorage.app',
    iosBundleId: 'au.edu.utas.kit305.A3',
  );

  // Android / web reuse the same project. If the marker tests on Android and
  // Firebase fails to initialise, run `flutterfire configure` to generate an
  // android app id for this project.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDUotyaZE7UCEzsM7F3XZZ6PtfUWx4oWzk',
    appId: '1:502315951774:android:867988432d6f0c486f7d8f',
    messagingSenderId: '502315951774',
    projectId: 'test-minh-tute-5',
    storageBucket: 'test-minh-tute-5.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUotyaZE7UCEzsM7F3XZZ6PtfUWx4oWzk',
    appId: '1:502315951774:web:867988432d6f0c486f7d8f',
    messagingSenderId: '502315951774',
    projectId: 'test-minh-tute-5',
    storageBucket: 'test-minh-tute-5.firebasestorage.app',
    authDomain: 'test-minh-tute-5.firebaseapp.com',
  );
}

