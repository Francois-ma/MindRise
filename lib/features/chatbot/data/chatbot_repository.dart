import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final chatbotRepositoryProvider = Provider<ChatbotRepository>((ref) {
  return ChatbotRepository(ref.watch(dioProvider));
});

class ChatbotRepository {
  const ChatbotRepository(this._dio);

  final Dio _dio;

  Future<ChatbotReply> sendMessage({
    required String message,
    required List<ChatbotHistoryMessage> history,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/chatbot/message/',
      data: {
        'message': message,
        'history': history.map((item) => item.toJson()).toList(),
      },
    );
    return ChatbotReply.fromJson(response.data ?? const {});
  }
}

class ChatbotHistoryMessage {
  const ChatbotHistoryMessage({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatbotReply {
  const ChatbotReply({required this.reply, required this.model});

  final String reply;
  final String model;

  factory ChatbotReply.fromJson(Map<String, dynamic> json) {
    return ChatbotReply(
      reply: json['reply']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
    );
  }
}
