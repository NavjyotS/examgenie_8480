import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/aiIntegrations/chat_completion_service.dart';

class ChatConfig {
  final String provider;
  final String model;
  final bool streaming;

  const ChatConfig({
    required this.provider,
    required this.model,
    this.streaming = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatConfig &&
          provider == other.provider &&
          model == other.model &&
          streaming == other.streaming;

  @override
  int get hashCode => provider.hashCode ^ model.hashCode ^ streaming.hashCode;
}

class ChatState {
  final String response;
  final dynamic fullResponse;
  final bool isLoading;
  final Exception? error;

  const ChatState({
    this.response = '',
    this.fullResponse,
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    String? response,
    dynamic fullResponse,
    bool? isLoading,
    Exception? error,
    bool clearError = false,
  }) {
    return ChatState(
      response: response ?? this.response,
      fullResponse: fullResponse ?? this.fullResponse,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final String provider;
  final String model;
  final bool streaming;

  ChatNotifier({
    required this.provider,
    required this.model,
    required this.streaming,
  }) : super(const ChatState());

  Future<void> sendMessage(
    List<Map<String, dynamic>> messages, {
    Map<String, dynamic> parameters = const {},
  }) async {
    print('🚀 [ChatNotifier] sendMessage invoked. Streaming enabled: $streaming');

    state = ChatState(
      response: '',
      fullResponse: streaming ? <Map<String, dynamic>>[] : null,
      isLoading: true,
    );

    try {
      if (streaming) {
        await getStreamingChatCompletion(
          provider,
          model,
          messages,
          onChunk: (chunk) {
            print('📥 [ChatNotifier] onChunk received: $chunk');

            final chunks = List<Map<String, dynamic>>.from(
              state.fullResponse as List? ?? [],
            )..add(chunk);

            String? content;
            
            // 1. Check OpenAI / standard Delta format
            content = chunk['choices']?[0]?['delta']?['content'] as String?;
            
            // 2. Check direct text or wrapper formats
            if (content == null && chunk.containsKey('text')) {
              content = chunk['text']?.toString();
            } else if (content == null && chunk.containsKey('content')) {
              content = chunk['content']?.toString();
            }

            // 3. Fallback: If this is a direct structured exam JSON (contains sections or title), 
            // serialize it to a JSON string so state.response captures it properly.
            if (content == null && (chunk.containsKey('sections') || chunk.containsKey('title'))) {
              content = jsonEncode(chunk);
            }

            state = state.copyWith(
              fullResponse: chunks,
              response: content != null
                  ? state.response + content
                  : state.response,
            );
          },
          onComplete: () {
            print('✅ [ChatNotifier] Stream onComplete triggered. Setting isLoading = false.');
            state = state.copyWith(isLoading: false);
          },
          onError: (error) {
            print('❌ [ChatNotifier] Stream onError triggered: $error');
            state = state.copyWith(error: error, isLoading: false);
          },
          parameters: parameters,
        );
      } else {
        print('🔄 [ChatNotifier] Executing non-streaming call (getChatCompletion)...');
        final result = await getChatCompletion(
          provider,
          model,
          messages,
          parameters: parameters,
        );
        
        String content = '';
        if (result.containsKey('choices')) {
          content = result['choices']?[0]?['message']?['content'] as String? ?? '';
        } else if (result.containsKey('text')) {
          content = result['text']?.toString() ?? '';
        } else if (result.containsKey('sections') || result.containsKey('title')) {
          // Direct structured exam JSON returned from worker
          content = jsonEncode(result);
        }
            
        state = ChatState(
          response: content,
          fullResponse: result,
          isLoading: false,
        );
      }
    } catch (error) {
      print('❌ [ChatNotifier] Critical error inside sendMessage: $error');
      state = state.copyWith(
        error: error is Exception ? error : Exception(error.toString()),
        isLoading: false,
      );
    }
  }

  void clearResponse() => state = const ChatState();
}

final chatNotifierProvider =
    StateNotifierProvider.family<ChatNotifier, ChatState, ChatConfig>(
      (ref, config) => ChatNotifier(
        provider: config.provider,
        model: config.model,
        streaming: config.streaming,
      ),
    );