// ignore_for_file: avoid_print, unused_local_variable
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_client.dart';
import 'package:frontend/shared/models/mind_map_model.dart';
import 'dart:convert';

void main() {
  test('Test API Connections', () async {
    final client = ApiClient();
    
    print('Testing /search/videos...');
    final res1 = await client.get('/search/videos?topic=Python');
    print('Response: \${res1.statusCode} - \${res1.body}');
    
    print('Testing /v1/mindmap/generate...');
    final res2 = await client.post('/v1/mindmap/generate', body: {
      'subjectTitle': 'Python OOP',
    });
    print('Response: \${res2.statusCode} - \${res2.body}');
    
    if (res2.statusCode == 200) {
      final json = jsonDecode(res2.body);
      final cluster = SubjectCluster.fromJson(json);
      print('Parsed MindMap Schema successfully! Root node: \${cluster.rootNode.label}');
    }
  });
}
