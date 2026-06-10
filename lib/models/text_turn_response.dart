class TextTurnResponse {
  final String answer;
  final String? sessionId;
  final String? requestId;

  const TextTurnResponse({
    required this.answer,
    this.sessionId,
    this.requestId,
  });

  factory TextTurnResponse.fromJson(Map<String, dynamic> json) {
    final String answer = _extractAnswer(json);
    return TextTurnResponse(
      answer: answer,
      sessionId: json['session_id'] as String?,
      requestId: json['request_id'] as String?,
    );
  }

  static String _extractAnswer(Map<String, dynamic> json) {
    if (json['answer'] is String) return json['answer'];
    if (json['reply'] is String) return json['reply'];
    if (json['content'] is String) return json['content'];
    if (json['message'] is String) return json['message'];

    final choices = json['choices'];
    if (choices is List && choices.isNotEmpty) {
      final message = choices[0];
      if (message is Map<String, dynamic>) {
        if (message['content'] is String) return message['content'];
        if (message['text'] is String) return message['text'];
      }
    }

    throw FormatException('Could not extract answer from response: $json');
  }
}
