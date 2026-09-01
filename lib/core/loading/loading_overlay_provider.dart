import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingOverlayNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void show() => state++;

  void hide() {
    if (state > 0) {
      state--;
    }
  }

  void reset() => state = 0;
}

final loadingOverlayProvider =
    NotifierProvider<LoadingOverlayNotifier, int>(LoadingOverlayNotifier.new);

extension LoadingOverlayController on Ref {
  void showLoadingOverlay() => read(loadingOverlayProvider.notifier).show();

  void hideLoadingOverlay() => read(loadingOverlayProvider.notifier).hide();
}

extension LoadingOverlayWidgetRef on WidgetRef {
  void showLoadingOverlay() => read(loadingOverlayProvider.notifier).show();

  void hideLoadingOverlay() => read(loadingOverlayProvider.notifier).hide();
}
