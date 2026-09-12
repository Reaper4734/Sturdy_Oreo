import '../services/file_picker_service.dart';

class ChatMessage {
  final String id;
  final String sender; // 'AI' or 'USER'
  final String text;
  final List<String>? options;
  final List<AttachedFileModel>? attachments;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.options,
    this.attachments,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'options': options,
      'attachments': attachments?.map((a) => a.toJson()).toList(),
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      sender: json['sender'] ?? 'AI',
      text: json['text'] ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachedFileModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: json['metadata'] as Map<String, dynamic>?,
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp']) : null,
    );
  }
}
