import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for project `altrixs-3d917`.
///
/// Run after Firebase login:
/// `dart pub global activate flutterfire_cli`
/// `flutterfire configure --project=altrixs-3d917 --platforms=android`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web Firebase options are not configured yet. Run flutterfire configure.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBnZI_NG3DI2AKUAEhiNT4kUA-AbiiwKbk',
    appId: '1:814395010183:ios:14a216f2d5302e56c89c22',
    messagingSenderId: '814395010183',
    projectId: 'altrixs-31959',
    storageBucket: 'altrixs-31959.firebasestorage.app',
    iosBundleId: 'com.example.altrix',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-0kA8yuDgpd0LyAjsmWjlAxs71FP6-28',
    appId: '1:814395010183:android:ded937c60db61e78c89c22',
    messagingSenderId: '814395010183',
    projectId: 'altrixs-31959',
    storageBucket: 'altrixs-31959.firebasestorage.app',
  );
}
