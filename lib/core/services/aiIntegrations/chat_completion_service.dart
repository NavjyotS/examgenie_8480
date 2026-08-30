import 'dart:convert';
import 'package:dio/dio.dart';
import '../ai_client.dart';

const String _chatCompletionEndpoint = String.fromEnvironment(
  'AWS_LAMBDA_CHAT_COMPLETION_URL',
);

/// Resolves the full OpenAI-compatible target URL for a given provider.
String _getProviderTargetUrl(String provider) {
  switch (provider.toUpperCase()) {
    case 'GEMINI':
      return 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';
    case 'OPENAI':
      return 'https://api.openai.com/v1/chat/completions';
    case 'ANTHROPIC':
      return 'https://api.anthropic.com/v1/messages';
    default:
      return 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions';
  }
}

/// Sanitizes the model string by removing any leading 'gemini/' prefix.
String _sanitizeModel(String model) {
  if (model.startsWith('gemini/')) {
    return model.replaceFirst('gemini/', '');
  }
  return model;
}

/// Resolves request headers for the given provider during local development proxying.
Map<String, String> _getProviderHeaders(String provider) {
  switch (provider.toUpperCase()) {
    case 'GEMINI':
      const key = String.fromEnvironment('GEMINI_API_KEY');
      return key.isNotEmpty ? {'Authorization': 'Bearer $key'} : {};
    case 'OPENAI':
      const key = String.fromEnvironment('OPENAI_API_KEY');
      return key.isNotEmpty ? {'Authorization': 'Bearer $key'} : {};
    case 'ANTHROPIC':
      const key = String.fromEnvironment('ANTHROPIC_API_KEY');
      return key.isNotEmpty ? {'x-api-key': key} : {};
    case 'PERPLEXITY':
      const key = String.fromEnvironment('PERPLEXITY_API_KEY');
      return key.isNotEmpty ? {'Authorization': 'Bearer $key'} : {};
    default:
      return {};
  }
}

Future<Map<String, dynamic>> getChatCompletion(
  String provider,
  String rawModel,
  List<Map<String, dynamic>> messages, {
  Map<String, dynamic> parameters = const {},
}) async {
  final targetUrl = _getProviderTargetUrl(provider);
  final cleanModel = _sanitizeModel(rawModel);

  final uri = Uri.parse(_chatCompletionEndpoint);
  final dynamicEndpoint = uri
      .replace(queryParameters: {...uri.queryParameters, 'url': targetUrl})
      .toString();

  // Extract response_format from parameters and place at root level
  final mutableParams = Map<String, dynamic>.from(parameters);
  final responseFormat = mutableParams.remove('response_format');

  final bool isProxy = uri.host == 'connector.rocket.new';
  final Map<String, dynamic> payload;

  if (isProxy) {
    // OpenAI/Gemini compatible payload format for direct CORS proxy forwarding
    payload = <String, dynamic>{
      'model': cleanModel,
      'messages': messages,
      'stream': false,
      if (responseFormat != null) 'response_format': responseFormat,
      ...mutableParams,
    };
  } else {
    // Wrapper payload format for AWS Lambda function
    payload = <String, dynamic>{
      'provider': provider,
      'model': cleanModel,
      'messages': messages,
      'stream': false,
      if (responseFormat != null) 'response_format': responseFormat,
      'parameters': mutableParams,
    };
  }

  return await callLambdaFunction(
    dynamicEndpoint,
    payload,
    headers: isProxy ? _getProviderHeaders(provider) : null,
  );
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
  final targetUrl = _getProviderTargetUrl(provider);
  final cleanModel = _sanitizeModel(rawModel);

  final uri = Uri.parse(_chatCompletionEndpoint);
  final dynamicEndpoint = uri
      .replace(queryParameters: {...uri.queryParameters, 'url': targetUrl})
      .toString();

  // Extract response_format from parameters and place at root level
  final mutableParams = Map<String, dynamic>.from(parameters);
  final responseFormat = mutableParams.remove('response_format');

  final bool isProxy = uri.host == 'connector.rocket.new';
  final Map<String, dynamic> payload;

  if (isProxy) {
    // OpenAI/Gemini compatible payload format for direct CORS proxy forwarding
    payload = <String, dynamic>{
      'model': cleanModel,
      'messages': messages,
      'stream': true,
      if (responseFormat != null) 'response_format': responseFormat,
      ...mutableParams,
    };
  } else {
    // Wrapper payload format for AWS Lambda function
    payload = <String, dynamic>{
      'provider': provider,
      'model': cleanModel,
      'messages': messages,
      'stream': true,
      if (responseFormat != null) 'response_format': responseFormat,
      'parameters': mutableParams,
    };
  }

  try {
    final dio = Dio();
    final response = await dio.post<ResponseBody>(
      dynamicEndpoint,
      data: payload,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          if (isProxy) ..._getProviderHeaders(provider),
        },
        responseType: ResponseType.stream,
      ),
    );

    String buffer = '';
    await for (final chunk in response.data!.stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final data = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            if (data['type'] == 'chunk' && data['chunk'] != null) {
              onChunk(data['chunk'] as Map<String, dynamic>);
            } else if (data['type'] == 'done') {
              onComplete();
            } else if (data['type'] == 'error') {
              print(
                'Lambda Function Error: ${data['error']}, details: ${data['details']}',
              );
              onError(Exception(data['error']));
            }
          } catch (_) {}
        }
      }
    }
  } catch (error) {
    print('Streaming error: $error');
    onError(error is Exception ? error : Exception(error.toString()));
  }
}