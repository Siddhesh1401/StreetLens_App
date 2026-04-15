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
    apiKey: 'AIzaSyAW2m7x8iVTnDKr-7z791ZTs9emQ9tOX00',
    appId: '1:238699114278:android:7a7fafb61d3153cbd9dbe7',
    messagingSenderId: '238699114278',
    projectId: 'streetlens-8a15c',
    storageBucket: 'streetlens-8a15c.firebasestorage.app',
  );

  // TODO: Fill in iOS values if you add iOS app in Firebase console
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAW2m7x8iVTnDKr-7z791ZTs9emQ9tOX00',
    appId: '1:238699114278:ios:placeholder',
    messagingSenderId: '238699114278',
    projectId: 'streetlens-8a15c',
    storageBucket: 'streetlens-8a15c.firebasestorage.app',
    iosBundleId: 'com.streetlens.streetlensApp',
  );

  // TODO: Fill in web values from Firebase console (Step 6 config you copied)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAW2m7x8iVTnDKr-7z791ZTs9emQ9tOX00',
    appId: '1:238699114278:web:placeholder',
    messagingSenderId: '238699114278',
    projectId: 'streetlens-8a15c',
    storageBucket: 'streetlens-8a15c.firebasestorage.app',
    authDomain: 'streetlens-8a15c.firebaseapp.com',
  );
}
