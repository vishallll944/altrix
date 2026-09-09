import 'package:altrix/features/auth/domain/entities/auth_result.dart';
import 'package:altrix/features/auth/domain/entities/user.dart';
import 'package:altrix/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository()
      : _user = const User(
          id: 'test-user',
          name: 'Maya Patel',
          email: 'maya@example.com',
          phone: '555-1234',
        );

  late User _user;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _user = User(
      id: 'test-user',
      name: 'Maya Patel',
      email: email,
      phone: '555-1234',
    );
    return AuthResult(token: 'test-token', user: _user);
  }

  @override
  Future<User> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _user;
  }

  @override
  Future<User> updateProfile({
    String? email,
    String? phone,
    String? addressLine1,
    String? city,
    String? state,
    String? postalCode,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _user = User(
      id: _user.id,
      name: _user.name,
      email: email ?? _user.email,
      phone: phone ?? _user.phone,
      addressLine1: addressLine1 ?? _user.addressLine1,
      city: city ?? _user.city,
      state: state ?? _user.state,
      postalCode: postalCode ?? _user.postalCode,
      emergencyContactName: emergencyContactName ?? _user.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? _user.emergencyContactPhone,
    );
    return _user;
  }

  @override
  Future<void> acceptInvite({
    required String token,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}
