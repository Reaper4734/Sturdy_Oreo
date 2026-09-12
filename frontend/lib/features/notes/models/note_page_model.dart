import 'note_block_model.dart';

class NotePage {
  final String id;
  final String workspaceId;
  final String title;
  final String? parentPageId;
  final String? icon;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<NoteBlock> blocks;

  const NotePage({
    required this.id,
    required this.workspaceId,
    this.title = 'Untitled',
    this.parentPageId,
    this.icon,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
    this.blocks = const [],
  });

  NotePage copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? parentPageId,
    bool clearParentPageId = false,
    String? icon,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<NoteBlock>? blocks,
  }) {
    return NotePage(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      parentPageId: clearParentPageId ? null : (parentPageId ?? this.parentPageId),
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      blocks: blocks ?? this.blocks,
    );
  }

  factory NotePage.fromJson(Map<String, dynamic> json) {
    List<NoteBlock> parsedBlocks = [];
    if (json['blocks'] != null && json['blocks'] is List) {
      parsedBlocks = (json['blocks'] as List)
          .map((b) => NoteBlock.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    return NotePage(
      id: json['id'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled',
      parentPageId: json['parentPageId'] as String?,
      icon: json['icon'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt']) : null,
      blocks: parsedBlocks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'title': title,
      'parentPageId': parentPageId,
      'icon': icon,
      'sortOrder': sortOrder,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }
}
