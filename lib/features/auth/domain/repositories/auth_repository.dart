import '../entities/auth_result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  Future<User> getProfile();

  Future<void> acceptInvite({
    required String token,
    required String password,
  });
}
