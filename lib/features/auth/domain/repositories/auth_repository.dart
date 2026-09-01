import '../entities/auth_result.dart';

abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset({required String email});

  Future<void> sendOtp({required String email});

  Future<AuthResult> verifyOtp({
    required String email,
    required String code,
  });
}
