import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/dio_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/auth_session_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'SharedPreferences must be initialized in main() before runApp.',
  );
});

final authSessionStorageProvider = Provider<AuthSessionStorage>((ref) {
  return PersistentAuthSessionStorage(
    secure: const SecureAuthSessionStorage(
      FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    ),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(ref.watch(dioProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Patient accounts authenticate against the Altrix API.
  // Firebase is used for push notifications once configured, not for sign-in yet.
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});
