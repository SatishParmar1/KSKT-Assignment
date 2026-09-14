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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: '«reda...…»',
    appId: '1:834397379612:web:456fdf946d9f0f95f113d9',
    messagingSenderId: '834397379612',
    projectId: 'assignment-kskt',
    authDomain: 'assignment-kskt.firebaseapp.com',
    storageBucket: 'assignment-kskt.firebasestorage.app',
    measurementId: 'G-DR4PMJ3XP3',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: '«reda...…»',
    appId: '1:834397379612:android:14b2d1280a760c75f113d9',
    messagingSenderId: '834397379612',
    projectId: 'assignment-kskt',
    storageBucket: 'assignment-kskt.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: '«reda...…»',
    appId: '1:834397379612:ios:fc76b463e0e9dabef113d9',
    messagingSenderId: '834397379612',
    projectId: 'assignment-kskt',
    storageBucket: 'assignment-kskt.firebasestorage.app',
    iosBundleId: 'com.example.ksktAgromate',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: '«reda...…»',
    appId: '1:834397379612:ios:fc76b463e0e9dabef113d9',
    messagingSenderId: '834397379612',
    projectId: 'assignment-kskt',
    storageBucket: 'assignment-kskt.firebasestorage.app',
    iosBundleId: 'com.example.ksktAgromate',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: '«reda...…»',
    appId: '1:834397379612:web:2f1d813ec82daca7f113d9',
    messagingSenderId: '834397379612',
    projectId: 'assignment-kskt',
    authDomain: 'assignment-kskt.firebaseapp.com',
    storageBucket: 'assignment-kskt.firebasestorage.app',
    measurementId: 'G-NL59JL2J3W',
  );
}
