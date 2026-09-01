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
  }) {
    return AuthState(
      user: user ?? this.user,
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
      ref.read(authTokenProvider.notifier).state = result.accessToken;
      state = AuthState(user: result.user);
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

  Future<bool> requestPasswordReset({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: email);
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

  Future<bool> sendOtp({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).sendOtp(email: email);
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

  Future<bool> verifyOtp({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(authRepositoryProvider).verifyOtp(
            email: email,
            code: code,
          );
      ref.read(authTokenProvider.notifier).state = result.accessToken;
      state = AuthState(user: result.user);
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

  void signOut() {
    ref.read(authTokenProvider.notifier).state = null;
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
