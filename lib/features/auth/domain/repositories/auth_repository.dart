import '../entities/auth_result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  Future<User> getProfile();

  Future<User> updateProfile({
    required String email,
    required String phone,
  });

  Future<void> acceptInvite({
    required String token,
    required String password,
  });
}
