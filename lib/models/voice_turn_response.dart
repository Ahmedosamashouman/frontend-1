class VoiceTurnResponse {
  final String transcript;
  final String answer;
  final String? sessionId;
  final String? requestId;
  final String? audioBase64;
  final String? audioMimeType;

  const VoiceTurnResponse({
    required this.transcript,
    required this.answer,
    this.sessionId,
    this.requestId,
    this.audioBase64,
    this.audioMimeType,
  });

  factory VoiceTurnResponse.fromJson(Map<String, dynamic> json) {
    return VoiceTurnResponse(
      transcript: json['transcript'] as String,
      answer: json['answer'] as String,
      sessionId: json['session_id'] as String?,
      requestId: json['request_id'] as String?,
      audioBase64: json['audio_base64'] as String?,
      audioMimeType: json['audio_content_type'] as String?,
    );
  }
}
