import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../core/api_client.dart';

class StompChatService {
  final ApiClient _apiClient = ApiClient();
  StompClient? _client;
  Completer<void>? _connectCompleter;

  Future<void> ensureConnected() async {
    if (_client != null && _client!.connected) {
      return;
    }

    if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
      return _connectCompleter!.future;
    }

    _connectCompleter = Completer<void>();

    final token = _apiClient.token;
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    _client = StompClient(
      config: StompConfig(
        url: ApiClient.wsUrl,
        onConnect: (StompFrame frame) {
          debugPrint('[StompChatService] Connected to STOMP broker');
          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.complete();
          }
        },
        onWebSocketError: (dynamic error) {
          debugPrint('[StompChatService] WebSocket error: $error');
          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.completeError(error);
          }
        },
        onStompError: (StompFrame frame) {
          debugPrint('[StompChatService] STOMP error: ${frame.body}');
          if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
            _connectCompleter!.completeError(Exception(frame.body ?? 'STOMP error'));
          }
        },
        onDisconnect: (frame) {
          debugPrint('[StompChatService] Disconnected from STOMP broker');
        },
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
      ),
    );

    _client!.activate();

    return _connectCompleter!.future.timeout(
      const Duration(seconds: 7),
      onTimeout: () {
        debugPrint('[StompChatService] Connection timeout');
        throw TimeoutException('Timed out connecting to WebSocket at ${ApiClient.wsUrl}');
      },
    );
  }

  /// Streams an interview response token-by-token from `/topic/interview/$sessionId`
  Stream<String> streamInterview(String userMessage, {String? sessionId}) {
    final effectiveSessionId = sessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
    final controller = StreamController<String>.broadcast();

    ensureConnected().then((_) {
      StompUnsubscribe? unsubscribe;

      unsubscribe = _client!.subscribe(
        destination: '/topic/interview/$effectiveSessionId',
        callback: (StompFrame frame) {
          if (frame.body == null || frame.body!.isEmpty) return;
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            if (data.containsKey('token')) {
              controller.add(data['token'] as String);
            }
            if (data['done'] == true) {
              unsubscribe?.call();
              controller.close();
            } else if (data.containsKey('error')) {
              unsubscribe?.call();
              controller.addError(Exception(data['error']));
              controller.close();
            }
          } catch (e) {
            controller.addError(e);
            controller.close();
          }
        },
      );

      _client!.send(
        destination: '/app/interview/stream',
        body: jsonEncode({
          'sessionId': effectiveSessionId,
          'message': userMessage,
        }),
      );
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  /// Streams a canvas AI tutor response token-by-token from `/topic/canvas/$sessionId`
  Stream<String> streamCanvasExplanation({
    required String userMessage,
    required String sessionId,
    String? videoId,
    String? timestamp,
    String? userId,
  }) {
    final controller = StreamController<String>.broadcast();

    ensureConnected().then((_) {
      StompUnsubscribe? unsubscribe;

      unsubscribe = _client!.subscribe(
        destination: '/topic/canvas/$sessionId',
        callback: (StompFrame frame) {
          if (frame.body == null || frame.body!.isEmpty) return;
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            if (data.containsKey('token')) {
              controller.add(data['token'] as String);
            }
            if (data['done'] == true) {
              unsubscribe?.call();
              controller.close();
            } else if (data.containsKey('error')) {
              unsubscribe?.call();
              controller.addError(Exception(data['error']));
              controller.close();
            }
          } catch (e) {
            controller.addError(e);
            controller.close();
          }
        },
      );

      final payload = <String, String>{
        'sessionId': sessionId,
        'message': userMessage,
      };
      if (videoId != null && videoId.isNotEmpty) {
        payload['videoId'] = videoId;
      }
      if (timestamp != null && timestamp.isNotEmpty) {
        payload['timestamp'] = timestamp;
      }
      if (userId != null && userId.isNotEmpty) {
        payload['userId'] = userId;
      }

      _client!.send(
        destination: '/app/canvas/stream',
        body: jsonEncode(payload),
      );
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  /// Listens to live video ingestion progress updates on `/topic/ingestion/$videoId`
  Stream<Map<String, dynamic>> streamIngestionProgress(String videoId) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();

    ensureConnected().then((_) {
      StompUnsubscribe? unsubscribe;

      unsubscribe = _client!.subscribe(
        destination: '/topic/ingestion/$videoId',
        callback: (StompFrame frame) {
          if (frame.body == null || frame.body!.isEmpty) return;
          try {
            final data = jsonDecode(frame.body!) as Map<String, dynamic>;
            controller.add(data);
            if (data['step'] == 'COMPLETE' || data['step'] == 'ERROR') {
              unsubscribe?.call();
              controller.close();
            }
          } catch (e) {
            controller.addError(e);
            controller.close();
          }
        },
      );
    }).catchError((e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  void dispose() {
    _client?.deactivate();
    _client = null;
    _connectCompleter = null;
  }
}

final stompChatServiceProvider = Provider<StompChatService>((ref) {
  final service = StompChatService();
  ref.onDispose(() => service.dispose());
  return service;
});
