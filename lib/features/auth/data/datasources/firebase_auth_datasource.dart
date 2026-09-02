import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart' as app_user;

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => auth.authStateChanges();

  User? get currentUser => auth.currentUser;

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return auth.currentUser?.getIdToken(forceRefresh);
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Unable to sign in.',
      );
    }

    final token = await firebaseUser.getIdToken();
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Unable to obtain an auth token.',
      );
    }

    final profile = await _loadOrCreateProfile(firebaseUser);
    return AuthResult(token: token, user: profile);
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String name = '',
    String phone = '',
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Unable to create account.',
      );
    }

    final token = await firebaseUser.getIdToken();
    if (token == null || token.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-credential',
        message: 'Unable to obtain an auth token.',
      );
    }

    final profile = await _createProfile(
      firebaseUser: firebaseUser,
      name: name,
      phone: phone,
    );

    return AuthResult(token: token, user: profile);
  }

  Future<app_user.User> getProfile() async {
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user.',
      );
    }

    return _loadOrCreateProfile(firebaseUser);
  }

  Future<app_user.User> updateProfile({
    required String email,
    required String phone,
    String? name,
  }) async {
    final firebaseUser = auth.currentUser;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No signed-in user.',
      );
    }

    final docRef = firestore.collection('users').doc(firebaseUser.uid);
    final existing = await docRef.get();
    final currentName = existing.data()?['name'] as String? ?? '';

    await docRef.set(
      {
        'email': email.trim(),
        'phone': phone.trim(),
        'name': name ?? currentName,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    if (email.trim().isNotEmpty && firebaseUser.email != email.trim()) {
      await firebaseUser.verifyBeforeUpdateEmail(email.trim());
    }

    return app_user.User(
      id: firebaseUser.uid,
      name: name ?? currentName,
      email: email.trim(),
      phone: phone.trim(),
    );
  }

  Future<void> signOut() => auth.signOut();

  Future<app_user.User> _loadOrCreateProfile(User firebaseUser) async {
    final docRef = firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      final data = snapshot.data() ?? {};
      return app_user.User(
        id: firebaseUser.uid,
        name: (data['name'] as String?)?.trim() ?? '',
        email: (data['email'] as String?)?.trim() ??
            firebaseUser.email ??
            '',
        phone: (data['phone'] as String?)?.trim() ?? '',
      );
    }

    return _createProfile(firebaseUser: firebaseUser);
  }

  Future<app_user.User> _createProfile({
    required User firebaseUser,
    String name = '',
    String phone = '',
  }) async {
    final profile = app_user.User(
      id: firebaseUser.uid,
      name: name.trim().isNotEmpty
          ? name.trim()
          : (firebaseUser.displayName ?? '').trim(),
      email: firebaseUser.email?.trim() ?? '',
      phone: phone.trim(),
    );

    await firestore.collection('users').doc(firebaseUser.uid).set(
      {
        'name': profile.name,
        'email': profile.email,
        'phone': profile.phone,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return profile;
  }
}

String mapFirebaseAuthError(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Invalid email or password.';
    case 'email-already-in-use':
      return 'An account already exists for this email.';
    case 'weak-password':
      return 'Password must be at least 6 characters.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    default:
      return error.message ?? 'Authentication failed. Please try again.';
  }
}
