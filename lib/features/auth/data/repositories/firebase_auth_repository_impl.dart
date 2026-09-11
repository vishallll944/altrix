import 'package:firebase_auth/firebase_auth.dart' hide User;

import '../../../patient/data/models/patient_models.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../models/invite_accept_request.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  const FirebaseAuthRepositoryImpl({
    required FirebaseAuthDataSource firebaseAuthDataSource,
    required AuthRemoteDataSource restAuthDataSource,
  })  : _firebase = firebaseAuthDataSource,
        _rest = restAuthDataSource;

  final FirebaseAuthDataSource _firebase;
  final AuthRemoteDataSource _rest;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) {
    return _firebase.signIn(email: email, password: password);
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String name = '',
    String phone = '',
  }) {
    return _firebase.signUp(
      email: email,
      password: password,
      name: name,
      phone: phone,
    );
  }

  @override
  Future<InvitePreviewModel> previewInvite(String token) {
    return _rest.previewInvite(token);
  }

  @override
  Future<User> getProfile() => _firebase.getProfile();

  @override
  Future<User> updateProfile({
    String? email,
    String? phone,
    String? addressLine1,
    String? city,
    String? state,
    String? postalCode,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) {
    return _firebase.updateProfile(
      email: email ?? '',
      phone: phone ?? '',
    );
  }

  @override
  Future<void> forgotPassword({required String email}) {
    return _rest.forgotPassword(email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) {
    return _rest.resetPassword(token: token, password: password);
  }

  @override
  Future<void> acceptInvite({
    required String token,
    required String password,
  }) {
    return _rest.acceptInvite(
      InviteAcceptRequest(token: token, password: password),
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _rest.logout();
    } catch (_) {}
    await _firebase.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    await _rest.deleteAccount();
  }

  @override
  Future<String?> uploadAvatar(String filePath) {
    return _rest.uploadAvatar(filePath);
  }

  Future<String?> getIdToken({bool forceRefresh = false}) {
    return _firebase.getIdToken(forceRefresh: forceRefresh);
  }
}

AuthException toAuthException(Object error) {
  if (error is FirebaseAuthException) {
    return AuthException(mapFirebaseAuthError(error));
  }
  return AuthException('Something went wrong. Please try again.');
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
