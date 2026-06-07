import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:swift_agents/src/constants/variables.dart';
import 'package:swift_agents/src/models/conversation_details_response.dart';
import 'package:swift_agents/src/models/init_session_response.dart';
import 'package:swift_agents/src/models/msg_model.dart';
import 'package:swift_agents/src/models/upload_attachments_response.dart';
import 'package:swift_agents/src/screens/widgets/chat_bubble.dart';
import 'package:swift_agents/src/swift_agents_sdk.dart';
import 'package:swift_agents/src/utils/file_util.dart';
import 'package:swift_agents/src/utils/logger.dart';
import '../models/conversations_response.dart';

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
      throw StateError("""
        Swift API called before initialization.
        1. Call SwiftAgentsSdk.initialize( companyId: '****', apiKey: 'swa_****') in main.
        2. Pass SwiftAgentsSdk.getContext(email: 'user***@mail.com') into view
        3. Check your internet connection.
        """);
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

  Future<ConversationsResponse?> listConversations({
    int limit = 20,
    String? cursor,
    bool forceRefresh = false,
  }) async {
    _requireSession();

    try {
      var response = await dio.get(
        _sdkPath('/conversations'),
        options: Options(headers: _authHeaders),
        queryParameters: {'cursor': cursor, 'limit': limit},
      );

      if (response.data == null) return null;

      return ConversationsResponse.fromJson(response.data);
    } catch (e, trace) {
      // ERROR HANDLING
      logError("Fetch Conversation Failed: $e", trace);
      return null;
    }
  }

  Future<ConversationDetailsResponse?> getConversationDetails({
    required String conversationId,
  }) async {
    _requireSession();

    try {
      var response = await dio.get(
        _sdkPath('/conversations/$conversationId'),
        options: Options(headers: _authHeaders),
      );

      if (response.data == null) return null;

      return ConversationDetailsResponse.fromJson(response.data);
    } catch (e, trace) {
      // ERROR HANDLING
      logError("Fetch Messages Failed: $e", trace);
      return null;
    }
  }

  Stream<MsgModel> sendMessage({
    required String sessionId,
    required String message,
    List<AttachmentModel>? attachments,
  }) async* {
    _requireSession();

    try {
      final response = await dio.post<ResponseBody>(
        _sdkPath('/chat'),
        data: {
          'session_id': sessionId,
          'message': message,
          if (attachments?.isNotEmpty ?? false)
            'attachments': attachments?.map((a) => a.toJson()).toList(),
        },
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
          if (value.text.isNotEmpty || value.session != null) {
            yield value;
          }
        }
      }

      if (pendingText.trim().isNotEmpty) {
        for (final value in _extractSseData([pendingText])) {
          if (value.text.isNotEmpty || value.session != null) {
            yield value;
          }
        }
      }
    } catch (e, t) {
      _handleError(e, t);
    }
  }

  Iterable<MsgModel> _extractSseData(List<String> lines) sync* {
    print('\n\n');
    print('LineS: $lines');
    for (final line in lines) {
      print('A Line: $line');

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
              final sessionData = dataMap['session'];
              if (sessionData is Map<String, dynamic>) {
                yield MsgModel(
                  '', // No visible content string needed
                  BubbleRole.system,
                  session: ConversationSession.fromJson(sessionData),
                );
              }
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
          yield MsgModel(trimmedLine, BubbleRole.agent);
        }
      }
    }
  }

  Future<UploadAttachmentsResponse?> uploadAttachments({
    required List<UploadFile> files,
  }) async {
    _requireSession();

    try {
      final multipartFiles = files
          .where((file) => file.bytes != null)
          .map(
            (file) => MultipartFile.fromBytes(file.bytes!, filename: file.name),
          )
          .toList();

      FormData formData = FormData.fromMap({'files': multipartFiles});

      final formattedHeaders = {
        ..._authHeaders,
        'Content-Type': 'multipart/form-data',
      };

      final response = await dio.post(
        _sdkPath('/chat/upload'),
        data: formData,
        options: Options(headers: formattedHeaders),
      );

      if (response.data == null) return null;

      return UploadAttachmentsResponse.fromJson(response.data);
    } catch (e, t) {
      _handleError(e, t);
      return null;
    }
  }

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
