import 'package:firebase_auth/firebase_auth.dart' hide User;

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
  Future<User> getProfile() => _firebase.getProfile();

  @override
  Future<User> updateProfile({
    required String email,
    required String phone,
  }) {
    return _firebase.updateProfile(email: email, phone: phone);
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

  Future<void> signOut() => _firebase.signOut();

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
