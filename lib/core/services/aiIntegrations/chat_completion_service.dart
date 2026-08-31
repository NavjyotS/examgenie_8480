import 'dart:convert';
import 'package:dio/dio.dart';
import '../ai_client.dart';

// Replace with your actual Supabase Edge Function URL
const String _supabaseFunctionUrl = String.fromEnvironment(
  'SUPABASE_FUNCTION_URL',
  defaultValue: 'https://YOUR_SUPABASE_PROJECT_REF.supabase.co/functions/v1/generate-exam',
);

// Replace with your Supabase Anon/Public Key
const String _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'YOUR_SUPABASE_ANON_KEY',
);

Future<Map<String, dynamic>> getChatCompletion(
  String provider,
  String rawModel,
  List<Map<String, dynamic>> messages, {
  Map<String, dynamic> parameters = const {},
}) async {
  // Extract response_format from parameters and place at root level if needed
  final mutableParams = Map<String, dynamic>.from(parameters);
  final responseFormat = mutableParams.remove('response_format');

  // Format payload according to Supabase Edge Function requirements
  final payload = <String, dynamic>{
    'provider': provider,
    'model': rawModel,
    'messages': messages,
    'stream': false,
    if (responseFormat != null) 'response_format': responseFormat,
    'parameters': mutableParams,
  };

  // Log outgoing payload for debugging purposes
  print('📤 [getChatCompletion] Outgoing Payload Prepared...');// ${jsonEncode(payload)}');

  try {
    final result = await callSupabaseFunction(
      _supabaseFunctionUrl,
      payload,
      apiKey: _supabaseAnonKey,
    );
    print('✅ [getChatCompletion] Successfully received response.');
    return result;
  } catch (e) {
    print('❌ [getChatCompletion] Error during execution: $e');
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
  final mutableParams = Map<String, dynamic>.from(parameters);
  final responseFormat = mutableParams.remove('response_format');

  final payload = <String, dynamic>{
    'provider': provider,
    'model': rawModel,
    'messages': messages,
    'stream': true,
    if (responseFormat != null) 'response_format': responseFormat,
    'parameters': mutableParams,
  };

  print('📤 [getStreamingChatCompletion] Outgoing Payload Prepared...');

  try {
    final dio = Dio();
    final response = await dio.post<ResponseBody>(
      _supabaseFunctionUrl,
      data: payload,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_supabaseAnonKey',
          'apikey': _supabaseAnonKey,
        },
        responseType: ResponseType.stream,
      ),
    );

    print('📥 [getStreamingChatCompletion] Connection established. Starting stream read loop...');
    
    // Read the incoming byte stream and accumulate it directly as text chunks
    await for (final chunk in response.data!.stream) {
      final decodedChunk = utf8.decode(chunk);
      
      // Pass the raw text fragment directly to onChunk so ChatNotifier builds up the full string
      onChunk({'text': decodedChunk});
    }
    
    print('🏁 [getStreamingChatCompletion] Stream finished. Triggering onComplete().');
    onComplete();
  } catch (error) {
    print('❌ [getStreamingChatCompletion] Critical Streaming Exception: $error');
    onError(error is Exception ? error : Exception(error.toString()));
  }
}