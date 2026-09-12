import 'package:file_picker/file_picker.dart';

class AttachedFileModel {
  final String id;
  final String name;
  final String extension;
  final int sizeBytes;
  final String? path;
  final List<int>? bytes;

  AttachedFileModel({
    required this.id,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    this.path,
    this.bytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'extension': extension,
      'sizeBytes': sizeBytes,
      'path': path,
    };
  }

  factory AttachedFileModel.fromJson(Map<String, dynamic> json) {
    return AttachedFileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      extension: json['extension'] ?? '',
      sizeBytes: json['sizeBytes'] ?? 0,
      path: json['path'],
    );
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage => ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(extension.toLowerCase());
  bool get isDocument => ['pdf', 'doc', 'docx', 'txt', 'md', 'csv'].contains(extension.toLowerCase());
}

class FilePickerService {
  Future<List<AttachedFileModel>> pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md', 'png', 'jpg', 'jpeg', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return [];
      }

      return result.files.map((file) {
        return AttachedFileModel(
          id: 'file_${DateTime.now().microsecondsSinceEpoch}_${file.name.hashCode}',
          name: file.name,
          extension: file.extension ?? 'file',
          sizeBytes: file.size,
          path: file.path,
          bytes: file.bytes,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
