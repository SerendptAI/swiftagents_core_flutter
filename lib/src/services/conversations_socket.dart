import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/swift_agents.dart';

class ConversationsSocket {
  final String baseUrl;

  static const int _maxRetries = 4;
  static const Duration _retryDelay = Duration(seconds: 3);

  WebSocket? _socket;
  int _retryCount = 0;
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;

  // Used to detect stale connect() calls that were superseded by a
  // disconnect() or a newer connect() while the WebSocket.connect()
  // future was still in flight.
  int _connectionGeneration = 0;
  ConversationsSocket({required this.baseUrl});

  Future<void> connect(
    String token,
    String conversationId, {
    void Function()? onConnect,
    void Function()? onDisconnect,
    void Function(dynamic error)? onError,
    void Function(ConversationsResponse? conversations)? onInit,
    void Function(ConversationSession? conversation)? onUpdate,
    void Function()? onReconnectFailed,
  }) async {
    // Prepare for a fresh connect: allow reconnects for this new session
    _shouldReconnect = true;
    _reconnectTimer?.cancel();
    _socket?.close();

    final int generation = ++_connectionGeneration;

    try {
      final companyId = SwiftAgentsCore.companyId;

      final url =
          '$baseUrl/sdk/$companyId/conversations/ws?token=$token';

      final socket = await WebSocket.connect(url);

      // If a newer connect() or a disconnect() happened while we were
      // awaiting the socket, this attempt is stale: close it and bail.
      if (generation != _connectionGeneration) {
        socket.close();
        _socket = null;
        return;
      }

      _socket = socket;

      // successful connection -> reset retry counter
      _retryCount = 0;
      _reconnectTimer?.cancel();

      onConnect?.call();

      void scheduleReconnect() {
        if (generation != _connectionGeneration) return;
        if (_retryCount >= _maxRetries || !_shouldReconnect) {
          // Report on reconnect failed
          if (_retryCount >= _maxRetries) {
            onReconnectFailed?.call();
          }
          return;
        }

        _reconnectTimer?.cancel();

        _reconnectTimer = Timer(_retryDelay, () {
          if (!_shouldReconnect || generation != _connectionGeneration) {
            return;
          }
          _retryCount++;
          connect(
            token,
            conversationId,
            onConnect: onConnect,
            onDisconnect: onDisconnect,
            onError: onError,
            onInit: onInit,
            onUpdate: onUpdate,
            onReconnectFailed: onReconnectFailed,
          );
        });
      }

      _socket!.listen(
        (message) {
          Map<String, dynamic> json;
          try {
            json = jsonDecode(message) as Map<String, dynamic>;
          } catch (e) {
            onError?.call(e);
            return;
          }

          try {
            switch (json['type']) {
              case 'init':
                _retryCount = 0;
                onInit?.call(
                  ConversationsResponse.fromJson(
                    json['data'] as Map<String, dynamic>,
                  ),
                );
                break;

              case 'update':
                onUpdate?.call(
                  ConversationSession.fromJson(
                    json['data'] as Map<String, dynamic>,
                  ),
                );
                break;

              case 'error':
                onError?.call(json['message'] ?? 'Unknown error');
                break;

              default:
                break;
            }
          } catch (e) {
            onError?.call(e);
          }
        },
        onDone: () {
          onDisconnect?.call();
          scheduleReconnect();
        },
        onError: (error) {
          onError?.call(error);
          scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (generation == _connectionGeneration) {
        onError?.call(e);
      }
    }
  }

  Future<void> disconnect() async {
    // prevent any further reconnect attempts and clean up
    _shouldReconnect = false;
    _connectionGeneration++; // invalidate any in-flight connect() attempt
    _reconnectTimer?.cancel();
    await _socket?.close();
    _socket = null;
  }
}
