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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD3WzX-eysgGXOWQZjKOg1pbmsjtb7552o',
    appId: '1:1033958829518:android:9f4c6e2a8b1d5f7e3a9c',
    messagingSenderId: '1033958829518',
    projectId: 'streetlens-555',
    storageBucket: 'streetlens-555.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD3WzX-eysgGXOWQZjKOg1pbmsjtb7552o',
    appId: '1:1033958829518:ios:1666576165f442b1c40f9f',
    messagingSenderId: '1033958829518',
    projectId: 'streetlens-555',
    storageBucket: 'streetlens-555.firebasestorage.app',
    iosBundleId: 'com.streetlens.streetlensApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD3WzX-eysgGXOWQZjKOg1pbmsjtb7552o',
    appId: '1:1033958829518:web:1666576165f442b1c40f9f',
    messagingSenderId: '1033958829518',
    projectId: 'streetlens-555',
    storageBucket: 'streetlens-555.firebasestorage.app',
    authDomain: 'streetlens-555.firebaseapp.com',
  );
}
