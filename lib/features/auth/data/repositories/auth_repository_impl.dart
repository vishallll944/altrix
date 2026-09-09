import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/invite_accept_request.dart';
import '../models/login_request.dart';
import '../models/update_profile_request.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequest(email: email, password: password),
    );
    return AuthResult(
      token: response.token,
      user: response.client.toEntity(),
    );
  }

  @override
  Future<User> getProfile() async {
    final response = await _remoteDataSource.getProfile();
    return response.client.toEntity();
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
    final response = await _remoteDataSource.updateProfile(
      UpdateProfileRequest(
        email: email,
        phone: phone,
        addressLine1: addressLine1,
        city: city,
        state: state,
        postalCode: postalCode,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      ),
    );
    return response.client.toEntity();
  }

  @override
  Future<void> acceptInvite({
    required String token,
    required String password,
  }) {
    return _remoteDataSource.acceptInvite(
      InviteAcceptRequest(token: token, password: password),
    );
  }

  @override
  Future<void> forgotPassword({
    required String email,
  }) {
    return _remoteDataSource.forgotPassword(email);
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String password,
  }) {
    return _remoteDataSource.resetPassword(
      token: token,
      password: password,
    );
  }
}
