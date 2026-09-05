// lib/core/services/aiIntegrations/chat_completion_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../ai_client.dart';

/// Environment configuration using --dart-define-from-file
class Env {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String tokenBaseUrl = String.fromEnvironment('TOKEN_BASE_URL');
  static const String deviceApiKey = String.fromEnvironment('DEVICE_API_KEY');
}

/// Service to handle short-lived JWT acquisition, caching, and rotation
class TokenService {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<String> getValidToken() async {
    final cached = await _storage.read(key: 'jwt_token');
    final expiryStr = await _storage.read(key: 'jwt_expiry');

    if (cached != null && expiryStr != null) {
      final expiry = DateTime.parse(expiryStr);
      if (DateTime.now()
          .isBefore(expiry.subtract(const Duration(minutes: 1)))) {
        return cached; // Token is still valid with buffer margin
      }
    }

    final tokenUrl = Env.tokenBaseUrl;
    print('🔗 [TOKEN_SERVICE] Requesting token from URL: "$tokenUrl"');

    // Token is missing or approaching expiration — request a new one using configuration keys
    final response = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        'X-API-Key': Env.deviceApiKey,
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'] as String;
      final expiresIn = data['expiresIn'] as int;

      await _storage.write(key: 'jwt_token', value: token);
      await _storage.write(
        key: 'jwt_expiry',
        value:
            DateTime.now().add(Duration(seconds: expiresIn)).toIso8601String(),
      );

      return token;
    } else {
      print(
          '❌ [TOKEN_SERVICE] Failed request to URL: "$tokenUrl" with status code: ${response.statusCode}');
      throw Exception(
          'Failed to obtain short-lived JWT token: ${response.statusCode}');
    }
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'jwt_expiry');
  }
}

/// Maps Cloudflare or third-party model identifiers to valid Google Gemini model names
String _resolveGeminiModel(String rawModel) {
  final modelLower = rawModel.toLowerCase();
  if (modelLower.contains('llama') || modelLower.startsWith('@cf/')) {
    return 'gemini-3.5-flash-lite';
  }
  return rawModel;
}

Future<Map<String, dynamic>> getChatCompletion(
  String provider,
  String rawModel,
  List<Map<String, dynamic>> messages, {
  Map<String, dynamic> parameters = const {},
}) async {
  final apiEndpointUrl = Env.apiBaseUrl;
  print('🔗 [AI_SERVICE] Target API_BASE_URL being used: "$apiEndpointUrl"');

  final mutableParams = Map<String, dynamic>.from(parameters);
  final responseFormat = mutableParams.remove('response_format');

  final resolvedModel = _resolveGeminiModel(rawModel);

  final payload = <String, dynamic>{
    'model': resolvedModel,
    'messages': messages,
    if (responseFormat != null) 'response_format': responseFormat,
    'parameters': mutableParams,
  };

  // Obtain dynamically managed short-lived JWT through TokenService
  String resolvedJwtToken;
  try {
    resolvedJwtToken = await TokenService.getValidToken();
  } catch (e) {
    print('❌ [AI_SERVICE] Failed to retrieve valid JWT token: $e');
    rethrow;
  }

  // Structured Log: Request Overview
  print('╔════════════════════════════════════════════════════════════════');
  print('║ 📤 [AI_SERVICE] OUTGOING CHAT COMPLETION REQUEST');
  print('╠────────────────────────────────────────────────────────────────');
  print('║ 🔗 URL      : $apiEndpointUrl');
  print('║ 🔑 JWT Token: $resolvedJwtToken');
  print(
      '║ 🤖 Model    : $rawModel ➔ Mapped to: $resolvedModel (Provider: $provider)');
  //print('║ 📦 Payload  :\n${const JsonEncoder.withIndent('  ').convert(payload)}');
  print('╚════════════════════════════════════════════════════════════════');

  try {
    // First attempt using the active short-lived token
    try {
      return await callApiEndpoint(
        apiEndpointUrl,
        payload,
        jwtToken: resolvedJwtToken,
      );
    } catch (apiError) {
      // If unauthorized due to edge case expiration, clear cache, fetch new token, and retry once
      if (apiError.toString().contains('401') ||
          apiError.toString().contains('Unauthorized')) {
        print(
            '⚠️ [AI_SERVICE] Token rejected (401). Refreshing token and retrying...');
        await TokenService.clearToken();
        resolvedJwtToken = await TokenService.getValidToken();

        return await callApiEndpoint(
          apiEndpointUrl,
          payload,
          jwtToken: resolvedJwtToken,
        );
      }
      rethrow;
    }
  } catch (e, stackTrace) {
    print('╔════════════════════════════════════════════════════════════════');
    print('║ ❌ [AI_SERVICE] EXECUTION ERROR');
    print('╠────────────────────────────────────────────────────────────────');
    print('║ 🔗 URL       : $apiEndpointUrl');
    print('║ ⚠️ Error     : $e');
    print('║ 📚 StackTrace:\n$stackTrace');
    print('╚════════════════════════════════════════════════════════════════');
    rethrow;
  }
}

Future<void> getStreamingChatCompletion(
  String provider,
  String rawModel,
  List<Map<String, dynamic>> messages, {
  required void Function(Map<String, dynamic> chunk) onChunk,
  required void Function() onComplete,
  required void Function(Exception error) onError,
  Map<String, dynamic> parameters = const {},
}) async {
  try {
    print(
        '⚠️ [AI_SERVICE:STREAM] Streaming requested, falling back to standard completion.');
    final result = await getChatCompletion(provider, rawModel, messages,
        parameters: parameters);
    onChunk(result);
    onComplete();
  } catch (e) {
    print('❌ [AI_SERVICE:STREAM] Fallback error encountered: $e');
    onError(e is Exception ? e : Exception(e.toString()));
  }
}
