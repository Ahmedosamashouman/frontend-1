import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../features/community/services/community_supabase.dart';
import '../models/text_turn_response.dart';
import '../models/voice_turn_response.dart';

class AiChatService {
  AiChatService._();

  static const String _baseUrl = String.fromEnvironment(
    'UPHEAL_API_BASE_URL',
    defaultValue: 'https://api.upheal.app',
  );

  static const String _path = '/v1/chat/text-turn';
  static const String _voicePath = '/v1/chat/voice-turn';

  static Future<TextTurnResponse> sendMessage(
    String message, {
    String? sessionId,
    int limit = 3,
    String audience = 'adult',
    double temperature = 0.3,
    int maxTokens = 220,
  }) async {
    final token = _getAccessToken();

    final body = <String, dynamic>{
      'message': message,
      'limit': limit,
      'audience': audience,
      'temperature': temperature,
      'max_tokens': maxTokens,
    };
    if (sessionId != null) body['session_id'] = sessionId;

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$_path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 45),
            onTimeout: () => throw TimeoutException(
              'The coach is taking too long. Please try again.',
            ),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          throw Exception('Unexpected response format from AI service.');
        }
        return TextTurnResponse.fromJson(data);
      }

      throw _mapError(response.statusCode, response.body);
    } on TimeoutException {
      rethrow;
    } on FormatException {
      throw Exception('Failed to parse AI service response.');
    }
  }

  static Future<VoiceTurnResponse> sendVoice(
    String filePath, {
    String? sessionId,
    int limit = 3,
    String audience = 'adult',
    double temperature = 0.3,
    int maxTokens = 180,
  }) async {
    final token = _getAccessToken();
    final uri = Uri.parse('$_baseUrl$_voicePath');

    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['limit'] = limit.toString();
    request.fields['audience'] = audience;
    request.fields['temperature'] = temperature.toString();
    request.fields['max_tokens'] = maxTokens.toString();
    if (sessionId != null) request.fields['session_id'] = sessionId;

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    try {
      final streamed = await request.send().timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw TimeoutException(
              'Voice processing is taking too long. Please try again.',
            ),
          );

      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is! Map<String, dynamic>) {
          throw Exception('Unexpected response format from AI service.');
        }
        return VoiceTurnResponse.fromJson(data);
      }

      throw _mapError(response.statusCode, response.body);
    } on TimeoutException {
      rethrow;
    } on FormatException {
      throw Exception('Failed to parse AI service response.');
    }
  }

  static String? _getAccessToken() {
    final client = CommunitySupabase.clientOrNull;
    if (client == null) return null;
    return client.auth.currentSession?.accessToken;
  }

  static Exception _mapError(int statusCode, String body) {
    switch (statusCode) {
      case 401:
        return Exception('Your session expired. Please sign in again.');
      case 422:
        return Exception('No clear audio was detected. Please try again.');
      case 429:
        return Exception(
            'You have sent too many messages. Please wait a moment.');
      case 502:
      case 503:
      case 504:
        return Exception(
          'The AI model is waking up. Please try again in a moment.',
        );
      default:
        if (kDebugMode) {
          debugPrint('[AiChatService] error $statusCode: $body');
        }
        return Exception(
          'Something went wrong ($statusCode). Please try again.',
        );
    }
  }
}
