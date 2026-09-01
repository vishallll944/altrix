import 'package:altrix/features/auth/domain/entities/auth_result.dart';
import 'package:altrix/features/auth/domain/entities/user.dart';
import 'package:altrix/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return AuthResult(
      accessToken: 'test-token',
      user: User(
        id: 'test-user',
        email: email,
        name: 'Maya Patel',
      ),
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> sendOtp({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<AuthResult> verifyOtp({
    required String email,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return AuthResult(
      accessToken: 'test-token',
      user: User(
        id: 'test-user',
        email: email,
        name: 'Maya Patel',
      ),
    );
  }
}
