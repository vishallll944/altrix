import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/user.dart';
import 'auth_providers.dart';
import 'auth_token_provider.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  final User? user;
  final bool isLoading;
  final String? error;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      ref.read(authTokenProvider.notifier).state = result.token;

      final profile = await ref.read(authRepositoryProvider).getProfile();
      state = AuthState(user: profile);
      return true;
    } on ApiException catch (error) {
      ref.read(authTokenProvider.notifier).state = null;
      state = state.copyWith(isLoading: false, error: error.message, clearUser: true);
      return false;
    } catch (_) {
      ref.read(authTokenProvider.notifier).state = null;
      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        error: 'Something went wrong. Please try again.',
      );
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

  void signOut() {
    ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
