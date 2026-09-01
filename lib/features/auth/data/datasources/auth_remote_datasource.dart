import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../models/forgot_password_request.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/otp_request.dart';
import '../models/verify_otp_request.dart';

class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._dio);

  final Dio _dio;

  void _ensureApiConfigured() {
    if (!Env.isApiConfigured) {
      throw const ApiException(
        'API URL is not configured yet. Add API_BASE_URL when your backend is ready.',
      );
    }
  }

  Future<LoginResponse> login(LoginRequest request) async {
    _ensureApiConfigured();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authLogin,
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    _ensureApiConfigured();
    try {
      await _dio.post<void>(
        ApiEndpoints.authForgotPassword,
        data: request.toJson(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> sendOtp(OtpRequest request) async {
    _ensureApiConfigured();
    try {
      await _dio.post<void>(
        ApiEndpoints.authOtpSend,
        data: request.toJson(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<LoginResponse> verifyOtp(VerifyOtpRequest request) async {
    _ensureApiConfigured();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authOtpVerify,
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
