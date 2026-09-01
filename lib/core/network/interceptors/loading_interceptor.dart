import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../loading/loading_overlay_provider.dart';

const skipLoadingOverlayExtraKey = 'skipLoadingOverlay';

class LoadingInterceptor extends Interceptor {
  LoadingInterceptor(this._ref);

  final Ref _ref;

  bool _shouldTrack(RequestOptions options) {
    return options.extra[skipLoadingOverlayExtraKey] != true;
  }

  void _show(RequestOptions options) {
    if (_shouldTrack(options)) {
      _ref.read(loadingOverlayProvider.notifier).show();
    }
  }

  void _hide(RequestOptions options) {
    if (_shouldTrack(options)) {
      _ref.read(loadingOverlayProvider.notifier).hide();
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _show(options);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _hide(response.requestOptions);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _hide(err.requestOptions);
    handler.next(err);
  }
}

Interceptor createLoadingInterceptor(Ref ref) {
  return LoadingInterceptor(ref);
}
