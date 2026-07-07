import 'dart:collection';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:swift_agents/src/constants/variables.dart';
import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/src/models/reopen_ticket_response.dart';
import 'package:swift_agents/src/models/upload_attachments_response.dart';
import 'package:swift_agents/src/services/conversation_messages_socket.dart';
import 'package:swift_agents/src/services/conversations_socket.dart';
import 'package:swift_agents/src/services/interceptors/api_logger_interceptor.dart';
import 'package:swift_agents/src/services/swift_agents_client.dart';
import 'package:swift_agents/src/utils/file_util.dart';
import '../models/conversation_details_response.dart';
import '../models/init_session_response.dart';
import '../models/msg_model.dart';
import '../screens/widgets/chat_bubble.dart';
import '../utils/logger.dart';
import 'package:uuid/uuid.dart';

class SdkProvider with ChangeNotifier {
  SwiftAgentsClient client;
  ConversationsSocket conversationsSocket;
  ConversationMessagesSocket conversationMsgSocket;

  SdkProvider(
    this.client,
    this.conversationsSocket,
    this.conversationMsgSocket,
  );

  // a. Init
  bool _isInitiateSessionLoading = false;
  bool get isInitiateSessionLoading => _isInitiateSessionLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  InitSessionResponse? _initSessionResponse;
  InitSessionResponse? get initSessionResponse => _initSessionResponse;

  // b. Messages
  final Map<String, bool> _isSendingMessages = {};
  bool get isCurrentMsgSending =>
      _isSendingMessages[_currentSessionId] ?? false;

  final Map<String, bool> _showMsgLoading = {};

  /// State for ChatBubble loading widget
  bool get showCurrentMsgLoading => _showMsgLoading[_currentSessionId] ?? false;

  final Map<String, bool> _showMsgTyping = {};

  /// State for ChatBubble typing
  bool get showCurrentMsgTyping => _showMsgTyping[_currentSessionId] ?? false;

  String? _streamedMsgID;
  String _streamedMessage = '';
  String get streamedMessage => _streamedMessage;

  String? _messageError;
  String? get messageError => _messageError;

  // c. Attached Messages
  bool _isUploadAttachmentsLoading = false;
  bool get isUploadAttachmentsLoading => _isUploadAttachmentsLoading;

  bool _isNewFilesUploaded = false;
  bool get isNewFilesUploaded => _isNewFilesUploaded;

  final ValueNotifier<double> uploadProgress = ValueNotifier(0.0);

  UploadAttachmentsResponse? _uploadAttachmentsResponse;
  UploadAttachmentsResponse? get uploadAttachmentsResponse =>
      _uploadAttachmentsResponse;

  List<AttachmentModel> _previousUploadedFiles = [];
  UnmodifiableListView<AttachmentModel> get previousUploadedFiles =>
      UnmodifiableListView(_previousUploadedFiles);

  // d. Chat sessions
  int? _selectedConversationIndex;
  int? get selectedConversationIndex => _selectedConversationIndex;
  ConversationSession? get selectedConversation =>
      _selectedConversationIndex != null
      ? _conversationsList[_selectedConversationIndex!]
      : null;

  String? _currentSessionId;

  /// GET CURRENT ACTIVE SESSION ID
  String get currentSessionId => _currentSessionId!;

  final Map<String, List<MsgModel>> _chatSessions = {};

  /// GET CURRENT CHAT MESSAGES
  UnmodifiableListView<MsgModel> get messages =>
      UnmodifiableListView(_chatSessions[_currentSessionId] ?? []);

  // e. Conversations
  bool _isGetConversationsLoading = false;
  bool get isGetConversationsLoading => _isGetConversationsLoading;

  bool _isInitConversationsSockLoading = false;
  bool get isInitConversationsSockLoading => _isInitConversationsSockLoading;

  // Backend is the only source of truth.
  ConversationsResponse? _conversationsResponse;
  ConversationsResponse? get conversationsResponse => _conversationsResponse;

  // does optimistic updates as seen in sendMessages, initConversationsSock, and
  // reOpenTicket; backend is not the only source.
  List<ConversationSession> _conversationsList = [];
  UnmodifiableListView<ConversationSession> get conversationsList =>
      UnmodifiableListView(_conversationsList);

  String? _nextCursor;
  bool _hasNext = true;

  String? get nextCursor => _nextCursor;
  bool get hasNext => _hasNext;

  bool _hasLoadedConversations = false;
  bool get hasLoadedConversations => _hasLoadedConversations;

  final Map<String, bool> _getConversionMsgesLoading = {};
  bool get isCurrentConversationMsgesLoading =>
      _getConversionMsgesLoading[_currentSessionId] ?? false;

  final Map<String, bool> _getConversionMsgesSockLoading = {};
  bool get isCurrentConversationMsgesSockLoading =>
      _getConversionMsgesSockLoading[_currentSessionId] ?? false;

  // f. Reopen Ticket
  final Map<String, bool> _isReopenTicketsLoading = {};
  bool get isCurrentReopenTicketsLoading =>
      _isReopenTicketsLoading[_currentSessionId] ?? false;

  // Other methods
  void _requireSession() {
    if (initSessionResponse?.sessionToken == null) {
      throw StateError("""
        Swift API called before initialization.
        1. Call SwiftAgentsCore.init( companyId: '****', apiKey: 'swa_****') in main.
        2. Pass SwiftAgentsCore.getContext(email: 'user***@mail.com') into view
        3. Check your internet connection.
        """);
    }
  }

  // UI Methods
  /// 1. Create a new chat
  void createNewChat({required bool enableMsgSocket}) {
    final id = const Uuid().v4();
    _currentSessionId = id;
    _chatSessions[id] = [];
    _selectedConversationIndex = null;

    if (enableMsgSocket) initConversationMessagesSock(conversationId: id);

    notifyListeners();
  }

  /// 2. Sets & open a chat session
  void openChat(String sessionId, int index) {
    _currentSessionId = sessionId;
    _selectedConversationIndex = index;
    notifyListeners();

    if (_currentSessionId != null) {
      initConversationMessagesSock(conversationId: _currentSessionId!);
      getConversationMessages(sessionId: _currentSessionId!);
    }
  }

  /// 3. Clears previously uploaded files metadata
  void clearPreviousUploadedFiles() {
    _previousUploadedFiles.clear();
    notifyListeners();
  }

  /// 4. Remove stored attachment metadata
  void removeUploadedAttachment({required UploadFile file}) {
    _previousUploadedFiles.removeWhere(
      (pUFile) => pUFile.filename == file.name,
    );
  }

  /// 5. Updates a particular conversation based on details from getConversationMessages
  void updateConversationFromMsgesDetail(ConversationDetailsResponse details){
    // Update conversations list
    if (details.updatedAt != null) {
      final updatedConvoIndex = _conversationsList.indexWhere(
            (c) => details.id == c.id,
      );

      if (updatedConvoIndex != -1) {
        _conversationsList[updatedConvoIndex] = _conversationsList[updatedConvoIndex].copyWith(
          updatedAt: details.updatedAt,
          resolved: details.resolved,
          resolvedAt: details.resolvedAt,
          type: details.type,
          subject: details.subject,
        );
      }
    }
  }

  // API ViewModels Methods
  /// 1. Create session for user
  Future<InitSessionResponse?> initiateSession({bool refresh = false}) async {
    if (_isInitiateSessionLoading || (_isInitialized && !refresh)) return null;

    _isInitiateSessionLoading = true;
    notifyListeners();

    // Create a new client instance on refresh, to avoid using the frozen client (frozen by auth's QueuedInterceptor).
    final newClient = refresh
        ? SwiftAgentsClient(
            dio: Dio(
              BaseOptions(
                baseUrl: Variables.apiBaseUrl,
                connectTimeout: Duration(seconds: 30),
                receiveTimeout: Duration(seconds: 180),
                followRedirects: false,
              ),
            ),
            email: client.email,
          )
        : client;

    if (refresh) {
      newClient.dio.interceptors.add(ApiLoggerInterceptor());
    }

    InitSessionResponse? session = await newClient.initialize();

    if (session != null) {
      _initSessionResponse = session;
      // _initSessionResponse = session.copyWith( // Used for testing auth token refresh.
      //   sessionToken: refresh ? session.sessionToken : expiredToken,
      // );

      _isInitialized = true;
      debugPrint('USER(${client.email}) SESSION INITIATED');
    }

    _isInitiateSessionLoading = false;

    notifyListeners();

    return session;
  }

  /// 2. Send message
  Future<List<MsgModel>?> sendMessage({
    required String sessionId,
    required String message,
    required bool isOnline,
  }) async {
    if (_isSendingMessages[sessionId] == true ||
        !_isInitialized ||
        _isUploadAttachmentsLoading)
      return null;
    _showMsgTyping[sessionId] = true;
    _isSendingMessages[sessionId] = true;
    _streamedMsgID = null;
    _streamedMessage = '';
    _messageError = null;
    _showMsgLoading[sessionId] = false;
    BubbleRole? currentActiveRole;
    int activeMessageIndex = -1;
    bool hasAddedMessage = false;
    var isAIStreamOver = false;
    var sentAt = DateTime.now();

    final sessionMsgs = _chatSessions.putIfAbsent(sessionId, () => []);

    if (_conversationsList.isNotEmpty) {
      // if (sessionMsgs.isNotEmpty) {
      // isAIStreamOver = sessionMsgs.any(
      //   (sMsg) => [BubbleRole.inbound, BubbleRole.outbound].contains(sMsg.role),
      // );
      // }
      isAIStreamOver = _conversationsList[_selectedConversationIndex ?? 0].type == "ticket";
    }

    // Only show loading widget, if user is not speaking to human (i.e AI) & isOnline
    _showMsgLoading[sessionId] = !isAIStreamOver && isOnline;

    // Add user message to chat first, even before upload.
    final delinkedPrevUploadedFiles = List.of(_previousUploadedFiles);
    sessionMsgs.add(
      MsgModel(
        null,
        message,
        isAIStreamOver ? BubbleRole.inbound : BubbleRole.user,
        delinkedPrevUploadedFiles,
        sentAt,
        authorName: null,
        avatarUrl: null,
        authorType: AuthorType.user,
        isSent: false,
      ),
    );
    notifyListeners();

    try {
      _requireSession();
      await for (final chunk in client.sendMessage(
        sessionId: sessionId,
        message: message,
        attachments: _previousUploadedFiles,
      )) {
        final disableErrorMessage =
            !(isAIStreamOver && chunk.role == BubbleRole.error);
        if (!hasAddedMessage) {
          // if (chunk.role != currentActiveRole) { // Allows persistent display of system messages
          currentActiveRole = chunk.role;
          _streamedMessage = '';
          if (!isAIStreamOver) _showMsgLoading[sessionId] = false;
          if (sessionMsgs.isNotEmpty) sessionMsgs.last.isSent = true;
          if (chunk.text.isNotEmpty && disableErrorMessage) {
            print('Adding new message to sessionMsgs: ${chunk.text}');
            sessionMsgs.add(
              MsgModel(
                null,
                '',
                currentActiveRole,
                null,
                sentAt,
                authorName: chunk.authorName,
                avatarUrl: chunk.avatarUrl,
                authorType: AuthorType.ai,
              ),
            ); // AI doesn't send attachments yet
            activeMessageIndex = sessionMsgs.length - 1;
            hasAddedMessage = true;
          }

          _previousUploadedFiles.clear();
        }

        // Intercept your session data & update it, if it's attached to the chunk.
        if (chunk.session != null) {
          _conversationsList.removeWhere(
            (session) => session.id == chunk.session?.id,
          );
          _conversationsList.insert(0, chunk.session!);
          _selectedConversationIndex = 0;
          // Also Update _streamedMsgID as it's only sent on stage done
          _streamedMsgID = chunk.id;
          notifyListeners();
          continue;
        }

        if (activeMessageIndex != -1 &&
            chunk.text.isNotEmpty &&
            disableErrorMessage) {
          _streamedMessage = chunk.text;
          currentActiveRole = chunk.role;

          var sUpdatedAt = chunk.session?.updatedAt;
          if (sUpdatedAt != null) sentAt = sUpdatedAt;

          var newMsg = MsgModel(
            null,
            _streamedMessage.trim(),
            currentActiveRole,
            null,
            sentAt,
            authorName: chunk.authorName,
            avatarUrl: chunk.avatarUrl,
            authorType: AuthorType.ai,
          );

          (sessionMsgs.isEmpty)
              ? sessionMsgs.add(newMsg)
              : sessionMsgs[activeMessageIndex] = newMsg;
        }

        notifyListeners();
      }

      return sessionMsgs;
    } catch (e, trace) {
      logError('Error: ${e.toString()}', trace);
    } finally {
      _isSendingMessages[sessionId] = false;
      _showMsgLoading[sessionId] = false;
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 300), () {
        _showMsgTyping[sessionId] = false;
        notifyListeners();
      });
    }
    return null;
  }

  /// 3. Gets Conversations List
  Future<ConversationsResponse?> getConversations({
    /// This is used to refresh the conversations list, and fetch the first page of conversations.
    /// only call this when the user is online, to avoid unnecessary API Error.
    bool refresh = false,
    /// This checks if Conversations has been fetched atleast once
    bool checkConversationsLoaded = false,
  }) async {
    // Is initiateSession loaded && Conversations not been fetched already.
    if (_isGetConversationsLoading || !_isInitialized) return null;
    // Use checkConversationsLoaded as a switch to check, if Conversations has loaded atleast once,
    // which is denoted by _hasLoadedConversations = true.
    if (checkConversationsLoaded && _hasLoadedConversations) return null;

    // Nothing left to load
    if (!_hasNext && !refresh) {
      return null;
    }

    _isGetConversationsLoading = true;
    notifyListeners();

    try {
      _requireSession();
      final response = await client.listConversations(
        cursor: refresh ? null : _nextCursor,
        limit: 20,
      );

      if (response != null) {
        if (refresh) {
          // Non-Pagnated (refreshed)
          _conversationsList = response.items ?? [];
          if (_conversationsList.isEmpty){
            // create new chat if no conversations exist, to avoid empty screen.
            createNewChat(enableMsgSocket: true);
          }
          else if (((_selectedConversationIndex ??0) + 1) > _conversationsList.length) {
            // If the selected index is out of bounds, open the first conversation.
            openChat(_conversationsList[0].id!, 0);
          } 
        } else {
          // Paganated
          final fetchedItems = response.items ?? [];

          final existingIds = _conversationsList.map((e) => e.id).toSet();

          final newItems = fetchedItems.where(
            (fItem) => !existingIds.contains(fItem.id),
          );

          _conversationsList.addAll(newItems);
        }

        _nextCursor = response.nextCursor;
        _hasNext = response.hasNext;
        _conversationsResponse = response;
        _hasLoadedConversations = true;
      }

      return response;
    } finally {
      _isGetConversationsLoading = false;
      notifyListeners();
    }
  }

  /// 4. Get a Conversation Messages
  Future<ConversationDetailsResponse?> getConversationMessages({
    required String sessionId,
  }) async {
    if (_getConversionMsgesLoading[sessionId] == true || !_isInitialized)
      return null;

    _getConversionMsgesLoading[sessionId] = true;
    notifyListeners();

    try {
      _requireSession();
      final details = await client.getConversationDetails(
        conversationId: sessionId,
      );

      if (details != null) {
        final formattedMsgs = details.messages.map((msg) {
          return MsgModel(
            msg.id,
            msg.content ?? '',
            msg.role ?? BubbleRole.assistant,
            msg.attachments,
            msg.timestamp,
            authorName: msg.authorName,
            avatarUrl: msg.avatarUrl,
            authorType: msg.authorType,
          );
        }).toList();

        _chatSessions[details.id] = formattedMsgs;
        updateConversationFromMsgesDetail(details);
      }

      return details;
    } finally {
      _getConversionMsgesLoading[sessionId] = false;
      notifyListeners();
    }
  }

  /// 5. Upload Attachments
  Future<UploadAttachmentsResponse?> uploadAttachments({
    required List<UploadFile> files,
  }) async {
    if (_isUploadAttachmentsLoading || !_isInitialized) return null;

    uploadProgress.value = 0.0;
    _isUploadAttachmentsLoading = true;
    _isNewFilesUploaded = false;

    notifyListeners();

    try {
      // Check if file has been uploaded before, if true don't re-upload.
      _requireSession();
      final uploadedNames = _previousUploadedFiles
          .map((e) => e.filename)
          .toSet();

      final deLinkedFiles = List.of(files);
      deLinkedFiles.removeWhere((file) => uploadedNames.contains(file.name));

      // return early if no new files to upload, but still notify listeners to update UI.
      if (deLinkedFiles.isNotEmpty) {
        _isNewFilesUploaded = false;
      } else {
        _isNewFilesUploaded = true;
        _isUploadAttachmentsLoading = false;
      }
      notifyListeners();

      if (_isNewFilesUploaded) return _uploadAttachmentsResponse;

      // Upload
      final aResponse = await client.uploadAttachments(
        files: deLinkedFiles,
        onProgress: (double progress) {
          uploadProgress.value = progress;
        },
      );

      if (aResponse != null) {
        _uploadAttachmentsResponse = aResponse;
        _previousUploadedFiles.addAll(aResponse.attachments ?? []);
        _isNewFilesUploaded = true;
      }
      notifyListeners();

      return aResponse;
    } finally {
      _isUploadAttachmentsLoading = false;
      notifyListeners();
    }
  }

  /// 6. Re-open a Ticket
  Future<ReopenTicketResponse?> reOpenTicket({
    required String conversationId,
  }) async {
    _requireSession();
    if (_isReopenTicketsLoading[conversationId] == true || !_isInitialized)
      return null;

    _isReopenTicketsLoading[conversationId] = true;
    notifyListeners();

    try {
      final response = await client.reopenTicket(
        conversationId: conversationId,
      );

      if (response != null) {
        final isReOpened = response.status == "reopened";

        if (isReOpened) {
          // Find the reopened conversation.
          final updatedIndx = _conversationsList.indexWhere(
            (convo) => convo.id == (response.ticketId ?? conversationId),
          );
          // Do an optismitic update...
          _conversationsList[updatedIndx].copyWith(resolved: false);
        }

        notifyListeners();
      }

      return response;
    } finally {
      _isReopenTicketsLoading[conversationId] = false;
      notifyListeners();
    }
  }

  // WEB SOCKETS
  /// 1. Initate Conversation Messages Socket
  void initConversationMessagesSock({required String conversationId}) {
    if (_initSessionResponse == null) {
      // debugPrint(
      //   'Socket connection cannot be initiated. Session token is null.',
      // );
      return;
    }

    if (_getConversionMsgesSockLoading[conversationId] == true) return;

    _getConversionMsgesSockLoading[conversationId] = true;
    notifyListeners();

    _requireSession();
    conversationMsgSocket.connect(
      _initSessionResponse?.sessionToken ?? '',
      conversationId,
      onInit: (ConversationDetailsResponse? details) {
        _getConversionMsgesSockLoading[conversationId] = false;
        notifyListeners();
        logDebug('USER(${client.email}) MSG SOCKET CONNECTED');

        if (details != null) {
          // Update messages
          final formattedMsgs = details.messages.map((msg) {
            return MsgModel(
              msg.id,
              msg.content ?? '',
              msg.role ?? BubbleRole.assistant,
              msg.attachments,
              msg.timestamp,
              authorName: msg.authorName,
              avatarUrl: msg.avatarUrl,
              authorType: msg.authorType,
            );
          }).toList();
          _chatSessions[details.id] = formattedMsgs;

          updateConversationFromMsgesDetail(details);

          notifyListeners();
        }
      },
      onUpdate: (msgs) {
        _getConversionMsgesSockLoading[conversationId] = false;
        notifyListeners();
        logDebug('USER(${client.email}) MSG SOCKET UPDATED: ${msgs?.toJson()}');
        mergeMessagesUpdate(msgs);
      },
      onDisconnect: () {
        _getConversionMsgesSockLoading[conversationId] = false;
        notifyListeners();
        logDebug('USER(${client.email}) MSG SOCKET DISCONNECTED');
      },
      onError: (error, [trace]) {
        _getConversionMsgesSockLoading[conversationId] = false;
        if (error == "Invalid or missing SDK token") {
          initiateSession(refresh: true).then((session) {
            if (session != null) {
              initConversationMessagesSock(conversationId: conversationId);
            }
          });
        } else {
          logError('USER(${client.email}) MESSAGE SOCKET ERROR: $error', trace);
        }
      },
    );
  }

  void mergeMessagesUpdate(ConversationDetailsResponse? details) {
    logWarning(
      'USER(${client.email}) MSG SOCKET FETCHED 1: ${details?.toJson()}',
    );

    if (details != null && details.messages.isNotEmpty) {
      final messages = details.messages;
      // Rejects socket updates triggered by the current streamed message.
      if (_streamedMsgID != null && messages.isNotEmpty) {
        final disableUpdate = _streamedMsgID == messages.last.id;
        if (disableUpdate) return;
      }

      // Update messages
      final formattedMsgs = messages.map((msg) {
        return MsgModel(
          msg.id,
          msg.content ?? '',
          msg.role ?? BubbleRole.assistant,
          msg.attachments,
          msg.timestamp,
          authorName: msg.authorName,
          avatarUrl: msg.avatarUrl,
          authorType: msg.authorType,
        );
      }).toList();

      final currentChatMessages = _chatSessions[details.id];
      if (currentChatMessages != null) {
        currentChatMessages
          ..clear()
          ..addAll(formattedMsgs);
      } else {
        _chatSessions[details.id] = formattedMsgs;
      }
      updateConversationFromMsgesDetail(details);
      notifyListeners();
    }
  }

  /// 2. Initate Conversations Socket
  void initConversationsSock() {
    if (_initSessionResponse == null) {
      debugPrint(
        'Socket connection cannot be initiated. Session token or session ID is null.',
      );
      return;
    }

    if (_isInitConversationsSockLoading == true || !_isInitialized) return;

    _isInitConversationsSockLoading = true;
    notifyListeners();

    _requireSession();
    conversationsSocket.connect(
      _initSessionResponse?.sessionToken ?? '',
      onInit: (ConversationsResponse? conversationsResponse) {
        _isInitConversationsSockLoading = false;
        notifyListeners();
        logDebug('USER(${client.email}) CONVERSATIONS SOCKET CONNECTED');
      },
      onUpdate: (ConversationsResponse? convosUpdate) {
        _isInitConversationsSockLoading = false;
        notifyListeners();
        logDebug(
          'USER(${client.email}) CONVO SOCKET UPDATED: ${convosUpdate?.toJson()}',
        );

        mergeConversationsUpdate(convosUpdate);
      },
      onDisconnect: () {
        _isInitConversationsSockLoading = false;
        notifyListeners();
        logDebug('USER(${client.email}) CONVERSATIONS SOCKET DISCONNECTED');
      },
      onError: (error, [trace]) {
        _isInitConversationsSockLoading = false;
        notifyListeners();
        if (error == "Invalid or missing SDK token") {
          initiateSession(refresh: true).then((session) {
            if (session != null) {
              initConversationsSock();
            }
          });
        } else {
          logError(
            'USER(${client.email}) CONVERSATIONS SOCKET ERROR: $error',
            trace,
          );
        }
      },
    );
  }

  void mergeConversationsUpdate(ConversationsResponse? update) {
    if (update != null) {
      for (ConversationSession convoUpdate in (update.items ?? []).reversed) {
        final updatedConvoIndex = _conversationsList.indexWhere(
          (c) => convoUpdate.id == c.id,
        );

        if (updatedConvoIndex != -1) {
          _conversationsList.removeAt(updatedConvoIndex);
        }
        _conversationsList.insert(0, convoUpdate);
      }


      // Update the selected conversation's index, so that the selected conversation on the sidebar,
      // matches the displayed conversation shown on the Messages screen on the right.
      final newIndexOfTheCurrentConvo = conversationsList.indexWhere((convo) => convo.id == _currentSessionId);
      if (newIndexOfTheCurrentConvo != -1) _selectedConversationIndex = newIndexOfTheCurrentConvo;

      notifyListeners();
    }
  }
}
