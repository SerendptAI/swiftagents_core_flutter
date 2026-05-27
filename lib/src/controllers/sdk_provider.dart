import 'package:flutter/cupertino.dart';
import 'package:swift_agents/src/services/swift_agents_client.dart';
import '../models/init_session_response.dart';
import '../models/msg_model.dart';
import '../screens/widgets/chat_bubble.dart';
import '../utils/logger.dart';
import 'package:uuid/uuid.dart';

class SdkProvider with ChangeNotifier {
  SwiftAgentsClient client;

  SdkProvider(this.client);

  // Init
  bool _isInitiateSessionLoading = false;
  bool get isInitiateSessionLoading => _isInitiateSessionLoading;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  InitSessionResponse? _sessionResponse;
  InitSessionResponse? get sessionResponse => _sessionResponse;

  // Messages
  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  String _streamedMessage = '';
  String get streamedMessage => _streamedMessage;

  String? _messageError;
  String? get messageError => _messageError;

  // New state layer to hold the active conversation
  final List<MsgModel> _messages = [];
  List<MsgModel> get messages => _messages;

  // API ViewModels Methods
  // 1. Create session for user
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

  Future<void> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    _isSendingMessage = true;
    _streamedMessage = '';
    _messageError = null;

    _messages.add(MsgModel(message, BubbleRole.user));
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
          _messages.add(MsgModel('', currentActiveRole));
          activeMessageIndex = _messages.length - 1;
        }

        if (chunk.role == BubbleRole.system) {
          _streamedMessage = chunk.text;
        } else {
          _streamedMessage += chunk.text;
        }

        if (activeMessageIndex != -1) {
          _messages[activeMessageIndex] = MsgModel(
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

}
