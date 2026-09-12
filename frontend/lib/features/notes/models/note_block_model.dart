import 'block_type.dart';

class NoteBlock {
  final String id;
  final String pageId;
  final BlockType type;
  final String content;
  final int sortOrder;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NoteBlock({
    required this.id,
    required this.pageId,
    required this.type,
    required this.content,
    required this.sortOrder,
    this.metadata = const {},
    this.createdAt,
    this.updatedAt,
  });

  NoteBlock copyWith({
    String? id,
    String? pageId,
    BlockType? type,
    String? content,
    int? sortOrder,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteBlock(
      id: id ?? this.id,
      pageId: pageId ?? this.pageId,
      type: type ?? this.type,
      content: content ?? this.content,
      sortOrder: sortOrder ?? this.sortOrder,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      id: json['id'] as String? ?? '',
      pageId: json['pageId'] as String? ?? '',
      type: BlockType.fromKey(json['type'] as String? ?? 'paragraph'),
      content: json['content'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pageId': pageId,
      'type': type.key,
      'content': content,
      'sortOrder': sortOrder,
      'metadata': metadata,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
