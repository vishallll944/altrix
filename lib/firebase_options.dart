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
        throw UnsupportedError(
          'iOS/macOS Firebase options are not configured yet. Run flutterfire configure.',
        );
      default:
        throw UnsupportedError(
          'Firebase is not supported for this platform.',
        );
    }
  }

  // Replace these values by running `flutterfire configure`.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    appId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    messagingSenderId: 'REPLACE_WITH_FLUTTERFIRE_CONFIGURE',
    projectId: 'altrixs-3d917',
    storageBucket: 'altrixs-3d917.firebasestorage.app',
  );
}
