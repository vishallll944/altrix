import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
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
    options.contentType ??= 'application/json';
    options.headers['Content-Type'] ??= 'application/json';
    options.headers['Accept'] ??= 'application/json';
    handler.next(options);
  }
}

Interceptor createAuthInterceptor(Ref ref) {
  return AuthInterceptor(() {
    final token = ref.read(authTokenProvider);
    if (token != null && token.isNotEmpty) return token;
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final stored = prefs.getString('auth_token');
      if (stored != null && stored.isNotEmpty) {
        ref.read(authTokenProvider.notifier).state = stored;
        return stored;
      }
    } catch (_) {}
    return null;
  });
}
