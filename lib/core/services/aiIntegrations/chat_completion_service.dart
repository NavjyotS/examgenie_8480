// lib/core/services/aiIntegrations/chat_completion_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../ai_client.dart';

// Pointing directly to your local backend route handler
const String _apiEndpointUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/getExamData',
);

/// Maps Cloudflare or third-party model identifiers to valid Google Gemini model names
String _resolveGeminiModel(String rawModel) {
  final modelLower = rawModel.toLowerCase();
  if (modelLower.contains('llama') || modelLower.startsWith('@cf/')) {
    // Fallback to a capable Gemini model supporting vision and structured output
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
  final mutableParams = Map<String, dynamic>.from(parameters);
  final responseFormat = mutableParams.remove('response_format');

  // Ensure we map Cloudflare/Llama model references to a valid Gemini model name
  final resolvedModel = _resolveGeminiModel(rawModel);

  final payload = <String, dynamic>{
    'model': resolvedModel,
    'messages': messages,
    if (responseFormat != null) 'response_format': responseFormat,
    'parameters': mutableParams,
  };

  const String jwtToken = String.fromEnvironment(
    'WORKER_JWT_TOKEN',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NSIsImVtYWlsIjoidGVzdEBleGFtcGxlLmNvbSIsImlhdCI6MTc4ODQxNzQyMSwiZXhwIjoxNzg4NDIxMDIxfQ.GMgJYA1vEfkTiahcbaNPRyv3ILmRe7P_4qjw9cE_SRU',
  );

  // Structured Log: Request Overview
  print('╔════════════════════════════════════════════════════════════════');
  print('║ 📤 [AI_SERVICE] OUTGOING CHAT COMPLETION REQUEST');
  print('╠────────────────────────────────────────────────────────────────');
  print('║ 🔗 URL      : $_apiEndpointUrl');
  print('║ 🔑 JWT Token: $jwtToken');
  print('║ 🤖 Model    : $rawModel ➔ Mapped to: $resolvedModel (Provider: $provider)');
  print('║ 📦 Payload  :\n${const JsonEncoder.withIndent('  ').convert(payload)}');
  print('╚════════════════════════════════════════════════════════════════');

  try {
    final result = await callApiEndpoint(
      _apiEndpointUrl,
      payload,
      jwtToken: jwtToken,
    );

    // Structured Log: Success Response
    print('╔════════════════════════════════════════════════════════════════');
    print('║ ✅ [AI_SERVICE] SUCCESSFUL RESPONSE RECEIVED');
    print('╠────────────────────────────────────────────────────────────────');
    print('║ 🔗 URL      : $_apiEndpointUrl');
    print('║ 📥 Response :\n${const JsonEncoder.withIndent('  ').convert(result)}');
    print('╚════════════════════════════════════════════════════════════════');

    return result;
  } catch (e, stackTrace) {
    // Structured Log: Error Details
    print('╔════════════════════════════════════════════════════════════════');
    print('║ ❌ [AI_SERVICE] EXECUTION ERROR');
    print('╠────────────────────────────────────────────────────────────────');
    print('║ 🔗 URL       : $_apiEndpointUrl');
    print('║ 🔑 JWT Token : $jwtToken');
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
    print('⚠️ [AI_SERVICE:STREAM] Streaming requested, falling back to standard completion.');
    final result = await getChatCompletion(provider, rawModel, messages, parameters: parameters);
    onChunk(result);
    onComplete();
  } catch (e) {
    print('❌ [AI_SERVICE:STREAM] Fallback error encountered: $e');
    onError(e is Exception ? e : Exception(e.toString()));
  }
}