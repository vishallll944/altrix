import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../models/invite_accept_request.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/profile_response.dart';
import '../models/update_profile_request.dart';

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
        ApiEndpoints.patientLogin,
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ProfileResponse> getProfile() async {
    _ensureApiConfigured();
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientMe,
      );
      return ProfileResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ProfileResponse> updateProfile(UpdateProfileRequest request) async {
    _ensureApiConfigured();
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.patientMe,
        data: request.toJson(),
      );
      return ProfileResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> acceptInvite(InviteAcceptRequest request) async {
    _ensureApiConfigured();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientInviteAccept,
        data: request.toJson(),
      );
      final data = response.data;
      if (data != null && data['success'] == false) {
        throw ApiException(
          data['error'] as String? ?? 'Could not set password',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> forgotPassword(String email) async {
    _ensureApiConfigured();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientForgotPassword,
        data: {'email': email},
      );
      final data = response.data;
      if (data != null && data['success'] == false) {
        throw ApiException(
          data['error'] as String? ?? 'Could not send reset email',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    _ensureApiConfigured();
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientResetPassword,
        data: {
          'token': token,
          'password': password,
        },
      );
      final data = response.data;
      if (data != null && data['success'] == false) {
        throw ApiException(
          data['error'] as String? ?? 'Could not reset password',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
