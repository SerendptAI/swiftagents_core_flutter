import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/src/services/swift_agents_client.dart';
import '../models/conversation_details_response.dart';
import '../models/init_session_response.dart';
import '../models/msg_model.dart';
import '../screens/widgets/chat_bubble.dart';
import '../utils/logger.dart';
import 'package:uuid/uuid.dart';

class SdkProvider with ChangeNotifier {
  SwiftAgentsClient client;

  SdkProvider(this.client);

  // a. Init
  bool _isInitiateSessionLoading = false;
  bool get isInitiateSessionLoading => _isInitiateSessionLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  InitSessionResponse? _sessionResponse;
  InitSessionResponse? get sessionResponse => _sessionResponse;

  // b. Messages
  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  String _streamedMessage = '';
  String get streamedMessage => _streamedMessage;

  String? _messageError;
  String? get messageError => _messageError;

  // c. Chat sessions
  String? _currentSessionId;

  /// GET CURRENT ACTIVE SESSION ID
  String get currentSessionId => _currentSessionId!;

  final Map<String, List<MsgModel>> _chatSessions = {};

  /// GET CURRENT CHAT MESSAGES
  UnmodifiableListView<MsgModel> get messages =>
      UnmodifiableListView(_chatSessions[_currentSessionId] ?? []);

  // d. Conversations
  bool _isGetConversionsLoading = false;
  bool get isGetConversionsLoading => _isGetConversionsLoading;

  ConversationsResponse? _conversationsResponse;
  ConversationsResponse? get conversationsResponse => _conversationsResponse;

  List<ConversationItem> _conversationsList = [];
  UnmodifiableListView<ConversationItem> get conversationsList =>
      UnmodifiableListView(_conversationsList);

  String? _nextCursor;
  bool _hasNext = true;

  String? get nextCursor => _nextCursor;
  bool get hasNext => _hasNext;

  bool _hasLoadedConversations = false;
  bool get hasLoadedConversations => _hasLoadedConversations;

  bool _isGetConversionMsgesLoading = false;
  bool get isGetConversionMsgesLoading => _isGetConversionMsgesLoading;

  // UI methods
  /// 1. Create a new chat
  void createNewChat() {
    final id = const Uuid().v4();
    _currentSessionId = id;
    _chatSessions[id] = [];
    notifyListeners();
  }

  /// 2. Sets a chat session as
  void openChat(String sessionId) {
    _currentSessionId = sessionId;
    notifyListeners();
    print('Hello 1');
    if (_currentSessionId != null) {
      print('Hello 2');
      getConversationMessages(sessionId: _currentSessionId!);
    }
  }

  // API ViewModels Methods
  /// 1. Create session for user
  Future<InitSessionResponse?> initiateSession() async {
    if (_isInitiateSessionLoading || _isInitialized) return null;

    _isInitiateSessionLoading = true;
    notifyListeners();

    InitSessionResponse? session = await client.initialize();

    if (session != null) {
      _sessionResponse = session;
      _isInitialized = true;
      debugPrint('USER(${client.email}) SESSION INITIATED');
    }

    _isInitiateSessionLoading = false;

    notifyListeners();

    return session;
  }

  /// 2. Send message
  Future<void> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    _isSendingMessage = true;
    _streamedMessage = '';
    _messageError = null;

    final sessionMsgs = _chatSessions.putIfAbsent(sessionId, () => []);

    sessionMsgs.add(MsgModel(message, BubbleRole.user));
    notifyListeners();

    // 1. Declare these outside so they are accessible in the finally block
    BubbleRole? currentActiveRole;
    int activeMessageIndex = -1;

    try {
      await for (final chunk in client.sendMessage(
        sessionId: sessionId,
        message: message,
      )) {
        if (chunk.role != currentActiveRole) {
          currentActiveRole = chunk.role;
          _streamedMessage = '';
          sessionMsgs.add(MsgModel('', currentActiveRole));
          activeMessageIndex = sessionMsgs.length - 1;
        }

        if (chunk.role == BubbleRole.system) {
          _streamedMessage = chunk.text;
        } else {
          _streamedMessage += chunk.text;
        }

        if (activeMessageIndex != -1) {
          sessionMsgs[activeMessageIndex] = MsgModel(
            _streamedMessage.trim(),
            currentActiveRole!,
          );
        }

        notifyListeners();
      }
    } catch (e, trace) {
      logError('Error: ${e.toString()}', trace);
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  /// 3. Gets Conversations List
  Future<ConversationsResponse?> getConversations({
    bool refresh = false,

    /// This checks if Conversations has been fetched atleast once
    bool checkConversationsLoaded = false,
  }) async {
    if (_isGetConversionsLoading || !_isInitialized) return null;
    if (checkConversationsLoaded && _hasLoadedConversations) return null;

    if (refresh) {
      _conversationsList.clear();
      _nextCursor = null;
      _hasNext = true;
    }

    // Nothing left to load
    if (!_hasNext && !refresh) {
      return null;
    }

    _isGetConversionsLoading = true;
    notifyListeners();

    try {
      final response = await client.listConversations(cursor: _nextCursor);

      if (response != null) {
        final fetchedItems = response.items ?? [];

        final existingIds = _conversationsList.map((e) => e.id).toSet();

        final newItems = fetchedItems.where(
          (fItem) => !existingIds.contains(fItem.id),
        );

        _conversationsList.addAll(newItems);

        _nextCursor = response.nextCursor;
        _hasNext = response.hasNext;
        _conversationsResponse = response;
        _hasLoadedConversations = true;
      }

      return response;
    } finally {
      _isGetConversionsLoading = false;
      notifyListeners();
    }
  }

  Future<ConversationDetailsResponse?> getConversationMessages({
    required String sessionId,
  }) async {
    if (_isGetConversionMsgesLoading) return null;

    _isGetConversionMsgesLoading = true;
    notifyListeners();

    try {
      final details = await client.getConversationDetails(
        conversationId: sessionId,
      );

      if (details != null) {
        final formattedMsgs = details.messages.map((msg) {
          final role = msg.role == 'user' ? BubbleRole.user: BubbleRole.agent;
          return MsgModel(msg.content ?? '', role);
        }).toList();

        _chatSessions[details.id] = formattedMsgs;
      }

      return details;
    } finally {
      _isGetConversionMsgesLoading = false;
      notifyListeners();
    }
  }
}
