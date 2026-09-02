import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/user.dart';
import '../../../notifications/presentation/providers/push_notification_provider.dart';
import 'auth_providers.dart';
import 'auth_token_provider.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isRestoringSession = true,
    this.error,
  });

  final User? user;
  final bool isLoading;
  final bool isRestoringSession;
  final String? error;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isRestoringSession,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      isRestoringSession: isRestoringSession ?? this.isRestoringSession,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> restoreSession() async {
    final existingToken = ref.read(authTokenProvider);
    if (existingToken != null && state.user != null) {
      state = state.copyWith(isRestoringSession: false);
      return;
    }

    state = state.copyWith(isRestoringSession: true, clearError: true);

    try {
      final token = await ref.read(authSessionStorageProvider).readToken();
      if (token == null || token.isEmpty) {
        state = state.copyWith(isRestoringSession: false);
        return;
      }

      ref.read(authTokenProvider.notifier).state = token;

      try {
        final profile = await ref.read(authRepositoryProvider).getProfile();
        state = AuthState(user: profile, isRestoringSession: false);
      } on ApiException catch (error) {
        if (error.statusCode == 401) {
          await _clearSession();
        } else {
          state = state.copyWith(isRestoringSession: false);
        }
      }
    } catch (_) {
      state = state.copyWith(isRestoringSession: false);
    }
  }

  Future<void> _saveSession(String token) async {
    ref.read(authTokenProvider.notifier).state = token;
    await ref.read(authSessionStorageProvider).saveToken(token);
  }

  Future<void> _clearSession({bool clearStorage = true}) async {
    if (clearStorage) {
      await ref.read(authSessionStorageProvider).clearToken();
    }
    ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState(isRestoringSession: false);
  }

  void _resetSignInAttempt({String? error}) {
    ref.read(authTokenProvider.notifier).state = null;
    state = state.copyWith(
      isLoading: false,
      error: error,
      clearUser: true,
    );
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    var sessionSaved = false;

    try {
      final result = await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      await _saveSession(result.token);
      sessionSaved = true;
      state = AuthState(user: result.user, isRestoringSession: false);
      await ref.read(pushNotificationServiceProvider).syncTokenForCurrentUser();
      return true;
    } on ApiException catch (error) {
      if (sessionSaved) {
        await _clearSession();
      } else {
        _resetSignInAttempt(error: error.message);
      }
      return false;
    } catch (_) {
      if (sessionSaved) {
        await _clearSession();
        state = state.copyWith(
          isLoading: false,
          clearUser: true,
          error: 'Something went wrong. Please try again.',
        );
      } else {
        _resetSignInAttempt(
          error: 'Something went wrong. Please try again.',
        );
      }
      return false;
    }
  }

  Future<bool> acceptInvite({
    required String token,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).acceptInvite(
            token: token,
            password: password,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(isLoading: false, error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (ref.read(authTokenProvider) == null) return;

    try {
      final profile = await ref.read(authRepositoryProvider).getProfile();
      state = state.copyWith(user: profile, clearError: true);
    } on ApiException catch (error) {
      state = state.copyWith(error: error.message);
    }
  }

  Future<bool> updateProfile({
    required String email,
    required String phone,
  }) async {
    try {
      final profile = await ref.read(authRepositoryProvider).updateProfile(
            email: email,
            phone: phone,
          );
      state = state.copyWith(user: profile, clearError: true);
      return true;
    } on ApiException catch (error) {
      state = state.copyWith(error: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        error: 'Something went wrong. Please try again.',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _clearSession();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
