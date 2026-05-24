import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:swift_agents/src/constants/variables.dart';
import 'package:swift_agents/src/models/init_session_response.dart';
import 'package:swift_agents/src/models/msg_model.dart';
import 'package:swift_agents/src/screens/widgets/chat_bubble.dart';
import 'package:swift_agents/src/swift_agents_sdk.dart';
import 'package:swift_agents/src/utils/logger.dart';

class SwiftAgentsClient {
  final Dio dio;
  final String email;

  SwiftAgentsClient({required this.dio, required this.email});

  String? _sessionToken;

  String _sdkPath(String path) {
    final companyId = SwiftAgentsSdk.companyId;
    return '${Variables.apiBaseUrl}/api/v1/sdk/$companyId$path';
  }

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_sessionToken',
  };

  void _requireSession() {
    if (_sessionToken == null) {
      throw StateError(
        "Call SwiftAgentsSdk.initialize( companyId: '****', apiKey: 'swa_****'); before using the SDK.",
      );
    }
  }

  Future<InitSessionResponse?> initialize() async {
    Map<String, dynamic> data = {'email': email};

    try {
      var response = await dio.post(
        _sdkPath('/init'),
        data: data,
        options: Options(headers: {'X-API-Key': SwiftAgentsSdk.apiKey}),
      );

      var jsonData = response.data;

      if (jsonData != null) {
        InitSessionResponse sessionResponse = InitSessionResponse.fromJson(
          jsonData,
        );

        _sessionToken = sessionResponse.sessionToken;
        return sessionResponse;
      }

      return null;
    } catch (e, t) {
      _handleError(e, t);
      return null;
    }
  }

  // Future<SdkConversationListResponse> listConversations({
  //   int limit = 20,
  //   String? cursor,
  //   bool forceRefresh = false,
  // }) async {
  //   _requireSession();
  //
  //   final email = _activeUserEmail;
  //
  //   if (
  //   !forceRefresh &&
  //       cursor == null &&
  //       email != null
  //   ) {
  //     final cachedConversations = cache.conversations(email);
  //
  //     if (cachedConversations.isNotEmpty) {
  //       return SdkConversationListResponse(
  //         items: cachedConversations,
  //       );
  //     }
  //   }
  //
  //   try {
  //     final response = await _dio.get(
  //       _sdkPath('/conversations'),
  //       queryParameters: {
  //         'limit': limit.clamp(1, 50).toString(),
  //
  //         if (cursor != null)
  //           'cursor': cursor,
  //       },
  //       options: Options(
  //         headers: _authHeaders,
  //       ),
  //     );
  //
  //     final data = _parseResponse(response.data);
  //
  //     final conversations =
  //     SdkConversationListResponse.fromJson(data);
  //
  //     if (email != null && cursor == null) {
  //       cache.saveConversations(
  //         email,
  //         conversations.items,
  //       );
  //     }
  //
  //     return conversations;
  //   } on DioException catch (e) {
  //     throw _handleError(e);
  //   }
  // }
  //
  // Future<SdkConversationDetail> getConversation(
  //     String conversationId, {
  //       bool forceRefresh = false,
  //     }) async {
  //   _requireSession();
  //
  //   final cachedConversation = cache.conversation(
  //     conversationId,
  //   );
  //
  //   if (
  //   cachedConversation != null &&
  //       !forceRefresh
  //   ) {
  //     return cachedConversation;
  //   }
  //
  //   try {
  //     final response = await _dio.get(
  //       _sdkPath('/conversations/$conversationId'),
  //       options: Options(
  //         headers: _authHeaders,
  //       ),
  //     );
  //
  //     final data = _parseResponse(response.data);
  //
  //     final conversation =
  //     SdkConversationDetail.fromJson(data);
  //
  //     cache.saveConversation(conversation);
  //
  //     return conversation;
  //   } on DioException catch (e) {
  //     throw _handleError(e);
  //   }
  // }

  Stream<MsgModel> sendMessage({
    required String sessionId,
    required String message,
  }) async* {
    _requireSession();

    try {
      final response = await dio.post<ResponseBody>(
        _sdkPath('/chat'),
        data: {'session_id': sessionId, 'message': message},
        options: Options(
          headers: _authHeaders,
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data?.stream;

      if (stream == null) {
        return;
      }

      String pendingText = '';

      await for (final chunk in stream) {
        final decodedChunk = utf8.decode(chunk);
        pendingText += decodedChunk;

        final lines = pendingText.split('\n');
        pendingText = lines.removeLast();

        for (final value in _extractSseData(lines)) {
          if (value.text.isNotEmpty) {
            yield value;
          }
        }
      }

      if (pendingText.trim().isNotEmpty) {
        for (final value in _extractSseData([pendingText])) {
          if (value.text.isNotEmpty) {
            yield value;
          }
        }
      }
    } catch (e, t) {
      _handleError(e, t);
    }
  }

  Iterable<MsgModel> _extractSseData(List<String> lines) sync* {
    // print('\n\n');
    // print('LineS: $lines');
    for (final line in lines) {
      // print('A Line: $line');

      final trimmedLine = line.trim();

      // 1. Skip completely empty lines or lines that define SSE events
      if (trimmedLine.isEmpty || trimmedLine.startsWith('event:')) {
        continue;
      }

      String jsonString = trimmedLine;

      // 2. Strip standard SSE data prefix if present
      if (trimmedLine.startsWith('data:')) {
        jsonString = trimmedLine.substring(5).trim();
      }

      // If the processed string is empty now, skip it
      if (jsonString.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(jsonString);

        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final dataMap = decoded['data'];

          if (dataMap is Map<String, dynamic>) {
            final stage = dataMap['stage'];

            if (stage == 'done') {
              continue;
            }

            var msg = dataMap['message'];
            if (msg != null) {
              final isSystem = ["thinking", "chat_details"].contains(stage);

              yield MsgModel(
                msg.toString(),
                isSystem ? BubbleRole.system : BubbleRole.agent,
              );
            }
          }
        }
      } catch (_) {
        // Fallback: If it isn't JSON, don't yield raw SSE text pollution unless it's pure content
        if (!trimmedLine.contains(':')) {
          yield MsgModel(
            trimmedLine,
            BubbleRole.agent,
          );
        }
      }
    }
  }
  // Iterable<String> _extractSseData(List<String> lines) sync* {
  //   print('\n\n');
  //   print('LineS: $lines');
  //   for (final line in lines) {
  //     print('A Line: $line');
  //
  //     final trimmedLine = line.trim();
  //
  //     // 1. Skip completely empty lines or lines that define SSE events
  //     if (trimmedLine.isEmpty || trimmedLine.startsWith('event:')) {
  //       continue;
  //     }
  //
  //     String jsonString = trimmedLine;
  //
  //     // 2. Strip standard SSE data prefix if present
  //     if (trimmedLine.startsWith('data:')) {
  //       jsonString = trimmedLine.substring(5).trim();
  //     }
  //
  //     // If the processed string is empty now, skip it
  //     if (jsonString.isEmpty) {
  //       continue;
  //     }
  //
  //     try {
  //       final decoded = jsonDecode(jsonString);
  //
  //       if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
  //         final dataMap = decoded['data'];
  //
  //         if (dataMap is Map<String, dynamic>) {
  //           final stage = dataMap['stage'];
  //
  //           if (stage == 'done') {
  //             continue;
  //           }
  //
  //           if (dataMap.containsKey('message') && dataMap['message'] != null) {
  //             yield dataMap['message'].toString();
  //           }
  //         }
  //       }
  //     } catch (_) {
  //       // Fallback: If it isn't JSON, don't yield raw SSE text pollution unless it's pure content
  //       if (!trimmedLine.contains(':')) {
  //         yield trimmedLine;
  //       }
  //     }
  //   }
  // }

  void _handleError(dynamic error, StackTrace trace) {
    int statusCode = 0;
    String message = error.toString();

    // Safely check if error is a DioException before accessing response properties
    if (error is DioException) {
      statusCode = error.response?.statusCode ?? 0;
      final responseData = error.response?.data;

      if (responseData is Map<String, dynamic>) {
        message =
            responseData['detail']?.toString() ??
            responseData['message']?.toString() ??
            responseData['error']?.toString() ??
            error.message ??
            'Dio error occurred';
      } else if (responseData != null) {
        message = responseData.toString();
      } else {
        message = error.message ?? 'Dio error occurred';
      }
    }

    logError(SwiftAgentsApiException(statusCode, message), trace);
  }

  // void _handleError(error, trace) {
  //   final statusCode = error.response?.statusCode ?? 0;
  //
  //   final responseData = error.response?.data;
  //
  //   String message = error.message ?? 'Unknown error';
  //
  //   if (responseData is Map<String, dynamic>) {
  //     message =
  //         responseData['detail']?.toString() ??
  //         responseData['message']?.toString() ??
  //         responseData['error']?.toString() ??
  //         message;
  //   } else if (responseData != null) {
  //     message = responseData.toString();
  //   } else {
  //     message = error.toString();
  //   }
  //
  //   logError(SwiftAgentsApiException(statusCode, message), trace) ;
  // }
}

class SwiftAgentsApiException implements Exception {
  final int statusCode;
  final String message;

  const SwiftAgentsApiException(this.statusCode, this.message);

  @override
  String toString() {
    return 'SwiftAgentsApiException($statusCode): $message';
  }
}
