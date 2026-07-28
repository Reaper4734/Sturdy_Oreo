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
}
