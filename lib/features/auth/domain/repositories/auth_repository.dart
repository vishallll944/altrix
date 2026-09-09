import '../entities/auth_result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> signIn({
    required String email,
    required String password,
  });

  Future<User> getProfile();

  Future<User> updateProfile({
    String? email,
    String? phone,
    String? addressLine1,
    String? city,
    String? state,
    String? postalCode,
    String? emergencyContactName,
    String? emergencyContactPhone,
  });

  Future<void> acceptInvite({
    required String token,
    required String password,
  });

  Future<void> forgotPassword({
    required String email,
  });

  Future<void> resetPassword({
    required String token,
    required String password,
  });
}
