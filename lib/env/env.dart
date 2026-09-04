abstract class Env {
  // Use 'const' and 'String.fromEnvironment' to capture compile-time variables
  //static const String apiKey = String.fromEnvironment('API_KEY');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String tokenBaseUrl = String.fromEnvironment('TOKEN_BASE_URL');
  static const String deviceApiKey = String.fromEnvironment('DEVICE_API_KEY');
}
