import '../../domain/entities/auth_result.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/otp_request.dart';
import '../models/verify_otp_request.dart';

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
      accessToken: response.accessToken,
      user: response.user.toEntity(),
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) {
    return _remoteDataSource.forgotPassword(
      ForgotPasswordRequest(email: email),
    );
  }

  @override
  Future<void> sendOtp({required String email}) {
    return _remoteDataSource.sendOtp(OtpRequest(email: email));
  }

  @override
  Future<AuthResult> verifyOtp({
    required String email,
    required String code,
  }) async {
    final response = await _remoteDataSource.verifyOtp(
      VerifyOtpRequest(email: email, code: code),
    );
    return AuthResult(
      accessToken: response.accessToken,
      user: response.user.toEntity(),
    );
  }
}
