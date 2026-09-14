import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../patient/data/models/patient_models.dart';
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

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    _ensureApiConfigured();
    try {
      final response = await call();
      final data = response.data;
      if (data == null) {
        throw const ApiException('Empty response from server');
      }
      requireApiSuccess(data);
      return data;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// 1. GET /api/patient/invite/preview?token=...
  Future<InvitePreviewModel> previewInvite(String token) async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientInvitePreview,
        queryParameters: {'token': token},
      ),
    );
    return InvitePreviewModel.fromJson(data);
  }

  /// 2. POST /api/patient/invite/accept
  Future<void> acceptInvite(InviteAcceptRequest request) async {
    final rawBody = jsonEncode(request.toJson());
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientInviteAccept,
        data: rawBody,
        options: Options(
          contentType: 'application/json',
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
  }

  /// 3. POST /api/patient/login
  /// Sends raw JSON body: {"email":"...","mail":"...","password":"..."}
  Future<LoginResponse> login(LoginRequest request) async {
    final rawBody = jsonEncode(request.toJson());

    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientLogin,
        data: rawBody,
        options: Options(
          contentType: 'application/json',
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
    return LoginResponse.fromJson(data);
  }

  /// 4. POST /api/patient/forgot-password
  Future<void> forgotPassword(String email) async {
    final rawBody = jsonEncode({'email': email.trim()});
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientForgotPassword,
        data: rawBody,
        options: Options(
          contentType: 'application/json',
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
  }

  /// 5. POST /api/patient/reset-password
  Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    final rawBody = jsonEncode({
      'token': token,
      'password': password,
    });
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientResetPassword,
        data: rawBody,
        options: Options(
          contentType: 'application/json',
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
  }

  /// 6. GET /api/patient/me
  Future<ProfileResponse> getProfile() async {
    final data = await _request(
      () => _dio.get<Map<String, dynamic>>(
        ApiEndpoints.patientMe,
        options: Options(
          headers: const {
            'Accept': 'application/json',
          },
        ),
      ),
    );
    return ProfileResponse.fromJson(data);
  }

  /// 7. PATCH /api/patient/me
  Future<ProfileResponse> updateProfile(UpdateProfileRequest request) async {
    final rawBody = jsonEncode(request.toJson());
    final data = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        ApiEndpoints.patientMe,
        data: rawBody,
        options: Options(
          contentType: 'application/json',
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      ),
    );
    return ProfileResponse.fromJson(data);
  }

  /// 8. POST /api/patient/logout
  Future<void> logout() async {
    await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientLogout,
        data: const {},
      ),
    );
  }

  /// 9. DELETE /api/patient/me
  Future<void> deleteAccount() async {
    await _request(
      () => _dio.delete<Map<String, dynamic>>(
        ApiEndpoints.patientMe,
      ),
    );
  }

  /// 10. POST /api/patient/avatar (Multipart)
  Future<String?> uploadAvatar(String filePath) async {
    _ensureApiConfigured();
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
      ),
    });

    final data = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiEndpoints.patientAvatar,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      ),
    );

    final payload = unwrapApiPayload(data);
    final clientMap = payload['client'] is Map<String, dynamic>
        ? payload['client'] as Map<String, dynamic>
        : (payload['patient'] is Map<String, dynamic>
            ? payload['patient'] as Map<String, dynamic>
            : const <String, dynamic>{});
    final rawUrl = readString(
      payload,
      [
        'avatarUrl',
        'avatar_url',
        'avatar',
        'image',
        'imageUrl',
        'image_url',
        'photoUrl',
        'photo_url',
        'url',
      ],
      fallback: readString(clientMap, [
        'avatarUrl',
        'avatar_url',
        'avatar',
        'image',
        'imageUrl',
        'image_url',
        'photoUrl',
        'photo_url',
        'url',
      ]),
    );

    return rawUrl.isNotEmpty ? resolveMediaUrl(rawUrl) : null;
  }
}

