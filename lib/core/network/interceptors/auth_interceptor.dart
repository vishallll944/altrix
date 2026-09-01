import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_token_provider.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._readToken);

  final String? Function() _readToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

Interceptor createAuthInterceptor(Ref ref) {
  return AuthInterceptor(() => ref.read(authTokenProvider));
}
