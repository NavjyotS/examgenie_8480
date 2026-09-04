import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'GEMINI_API_KEY', obfuscate: true)
  static const String geminiApiKey = _Env.geminiApiKey;

  @EnviedField(varName: 'API_BASE_URL')
  static const String apiBaseUrl = _Env.apiBaseUrl;

  @EnviedField(varName: 'TOKEN_BASE_URL')
  static const String tokenBaseUrl = _Env.tokenBaseUrl;

  @EnviedField(varName: 'DEVICE_API_KEY', obfuscate: true)
  static const String deviceApiKey = _Env.deviceApiKey;
}