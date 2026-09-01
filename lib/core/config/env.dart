/// API environment configuration.
///
/// Default production API: [https://altrixs.com](https://altrixs.com/)
///
/// Override for staging/local:
/// `flutter run --dart-define=API_BASE_URL=https://staging.altrixs.com`
class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://altrixs.com',
  );

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
