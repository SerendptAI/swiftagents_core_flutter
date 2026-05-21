import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:swift_agents/src/constants/variables.dart';
import 'package:swift_agents/src/models/init_session_response.dart';
import 'package:swift_agents/src/swift_agents_sdk.dart';

class SwiftAgentsClient {
  final Dio dio;
  final String email;

  SwiftAgentsClient({
    required this.dio,
    required this.email,
  });

  String? _sessionToken;

  String _sdkPath(String path){
    final companyId = SwiftAgentsSdk.companyId;
    return '${Variables.apiBaseUrl}/v1/sdk/$companyId$path';
  }

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_sessionToken',
  };

  void _requireSession() {
    if (_sessionToken == null) {
      throw StateError(
        'Call SwiftAgentsClient.initialize before using the SDK.',
      );
    }
  }

  Future<InitSessionResponse?> initialize() async {

    Map<String, dynamic> data = {'email': email};

    try {
      var response = await dio.post(
        _sdkPath('/init'),
        data: data,
        options: Options(
          headers: {
            'X-API-Key ': SwiftAgentsSdk.apiKey,
          }
        ),
      );

      var jsonData = response.data;

      if (jsonData != null) {
        InitSessionResponse sessionResponse = InitSessionResponse.fromJson(jsonData);
        debugPrint("API session: ${sessionResponse.toJson()}");

        return sessionResponse;
      }

      return null;
    } on DioException catch (e) {
      throw _handleError(e);
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

  Stream<String> sendMessage({
    required String sessionId,
    required String message,
  }) async* {
    _requireSession();

    try {
      final response = await dio.post<ResponseBody>(
        _sdkPath('/chat'),
        data: {
          'session_id': sessionId,
          'message': message,
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
          if (value.isNotEmpty) {
            yield value;
          }
        }
      }

      if (pendingText.trim().isNotEmpty) {
        for (final value in _extractSseData([pendingText])) {
          if (value.isNotEmpty) {
            yield value;
          }
        }
      }
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  Iterable<String> _extractSseData(
      List<String> lines,
      ) sync* {
    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.isEmpty) {
        continue;
      }

      if (!trimmedLine.startsWith('data:')) {
        yield trimmedLine;
        continue;
      }

      final data = trimmedLine
          .substring(5)
          .trim();

      if (data == '[DONE]') {
        continue;
      }

      try {
        final decoded = jsonDecode(data);

        if (decoded is Map<String, dynamic>) {
          yield (
              decoded['delta'] ??
                  decoded['content'] ??
                  decoded['message'] ??
                  data
          ).toString();
        } else {
          yield decoded.toString();
        }
      } catch (_) {
        yield data;
      }
    }
  }

  SwiftAgentsApiException _handleError(
      DioException error,
      ) {
    final statusCode =
        error.response?.statusCode ?? 500;

    final responseData = error.response?.data;

    String message =
        error.message ?? 'Unknown error';

    if (responseData is Map<String, dynamic>) {
      message =
          responseData['message']?.toString() ??
              responseData['error']?.toString() ??
              message;
    } else if (responseData != null) {
      message = responseData.toString();
    }

    return SwiftAgentsApiException(
      statusCode,
      message,
    );
  }
}

class SwiftAgentsApiException implements Exception {
  final int statusCode;

  final String message;

  const SwiftAgentsApiException(
      this.statusCode,
      this.message,
      );

  @override
  String toString() {
    return 'SwiftAgentsApiException($statusCode): $message';
  }
}