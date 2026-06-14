import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/src/models/upload_attachments_response.dart';
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

  SdkProvider(this.client);

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

  String _streamedMessage = '';
  String get streamedMessage => _streamedMessage;

  String? _messageError;
  String? get messageError => _messageError;

  // c. Attached Messages
  bool _isUploadAttachmentsLoading = false;
  bool get isUploadAttachmentsLoading => _isUploadAttachmentsLoading;

  bool _isNewFilesUploaded  = false;
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
  set selectedConversationIndex(int? index) =>
      _selectedConversationIndex = index;

  String? _currentSessionId;

  /// GET CURRENT ACTIVE SESSION ID
  String get currentSessionId => _currentSessionId!;

  final Map<String, List<MsgModel>> _chatSessions = {};

  /// GET CURRENT CHAT MESSAGES
  UnmodifiableListView<MsgModel> get messages =>
      UnmodifiableListView(_chatSessions[_currentSessionId] ?? []);

  // e. Conversations
  bool _isGetConversionsLoading = false;
  bool get isGetConversionsLoading => _isGetConversionsLoading;

  // Backend is the only source of truth.
  ConversationsResponse? _conversationsResponse;
  ConversationsResponse? get conversationsResponse => _conversationsResponse;

  // does optimistic updates seen in sendMessages, backend not the only source.
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

  // UI methods
  /// 1. Create a new chat
  void createNewChat() {
    final id = const Uuid().v4();
    _currentSessionId = id;
    _chatSessions[id] = [];
    notifyListeners();
  }

  /// 2. Sets & open a chat session
  void openChat(String sessionId, int index) {
    _currentSessionId = sessionId;
    notifyListeners();

    if (_currentSessionId != null) {
      getConversationMessages(sessionId: _currentSessionId!);
    }
  }

  /// 3. Clears previously uploaded files metadata
  void clearPreviousUploadedFiles(){
    _previousUploadedFiles.clear();
    notifyListeners();
  }

  // API ViewModels Methods
  /// 1. Create session for user
  Future<InitSessionResponse?> initiateSession() async {
    if (_isInitiateSessionLoading || _isInitialized) return null;

    _isInitiateSessionLoading = true;
    notifyListeners();

    InitSessionResponse? session = await client.initialize();

    if (session != null) {
      _initSessionResponse = session;
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
  }) async {
    if (_isSendingMessages[sessionId] == true ||
        !_isInitialized ||
        _isUploadAttachmentsLoading)
      return null;
    _isSendingMessages[sessionId] = true;
    _streamedMessage = '';
    _messageError = null;
    bool hasAddedMessage = false;

    final sessionMsgs = _chatSessions.putIfAbsent(sessionId, () => []);

    // Add user message to chat first, even upload.
    final delinkedPrevUploadedFiles = List.of(_previousUploadedFiles);
    sessionMsgs.add(MsgModel(message, BubbleRole.user, delinkedPrevUploadedFiles));
    notifyListeners();

    // 1. Declare these outside so they are accessible in the finally block
    BubbleRole? currentActiveRole;
    int activeMessageIndex = -1;

    if (!_isInitialized) return null;
    try {
      await for (final chunk in client.sendMessage(
        sessionId: sessionId,
        message: message,
        attachments: _previousUploadedFiles,
      )) {
        if (!hasAddedMessage) {
          // if (chunk.role != currentActiveRole) { // Allows persistent display of system message
          currentActiveRole = chunk.role;
          _streamedMessage = '';
          sessionMsgs.add(
            MsgModel('', currentActiveRole, null),
          ); // AI doesn't send attachments yet
          activeMessageIndex = sessionMsgs.length - 1;
          hasAddedMessage = true;
          _previousUploadedFiles.clear();
        }

        // Intercept your session data & update it, if it's attached to the chunk.
        if (chunk.session != null) {
          _conversationsList.removeWhere(
            (session) => session.id == chunk.session?.id,
          );
          _conversationsList.insert(0, chunk.session!);
          _selectedConversationIndex = 0;
          notifyListeners();
          continue;
        }

        if (chunk.role == BubbleRole.system) {
          _streamedMessage = chunk.text;
        } else {
          _streamedMessage += chunk.text;
        }

        if (activeMessageIndex != -1) {
          currentActiveRole = chunk.role;
          sessionMsgs[activeMessageIndex] = MsgModel(
            _streamedMessage.trim(),
            currentActiveRole,
            null,
          );
        }

        notifyListeners();
      }

      return sessionMsgs;
    } catch (e, trace) {
      logError('Error: ${e.toString()}', trace);
    } finally {
      _isSendingMessages[sessionId] = false;
      notifyListeners();
    }
    return null;
  }

  /// 3. Gets Conversations List
  Future<ConversationsResponse?> getConversations({
    bool refresh = false,

    /// This checks if Conversations has been fetched atleast once
    bool checkConversationsLoaded = false,
  }) async {
    if (_isGetConversionsLoading || !_isInitialized || _isUploadAttachmentsLoading) return null;
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
      final response = await client.listConversations(
        cursor: _nextCursor,
        limit: 20,
      );

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

  /// 4. Get a Conversation Messages
  Future<ConversationDetailsResponse?> getConversationMessages({
    required String sessionId,
  }) async {
    if (_getConversionMsgesLoading[sessionId] == true) return null;

    _getConversionMsgesLoading[sessionId] = true;
    notifyListeners();

    try {
      final details = await client.getConversationDetails(
        conversationId: sessionId,
      );

      if (details != null) {
        final formattedMsgs = details.messages.map((msg) {
          final role = msg.role == 'user' ? BubbleRole.user : BubbleRole.agent;
          return MsgModel(msg.content ?? '', role, msg.attachments);
        }).toList();

        _chatSessions[details.id] = formattedMsgs;
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
    if (_isUploadAttachmentsLoading) return null;

    uploadProgress.value = 0.0;
    _isUploadAttachmentsLoading = true;
    _isNewFilesUploaded = false;

    notifyListeners();

    try {
      // Check if file has been uploaded before, if true don't re-upload.
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

  void removeUploadedAttachment({required UploadFile file}) {
    _previousUploadedFiles.removeWhere(
      (pUFile) => pUFile.filename == file.name,
    );
  }
}
