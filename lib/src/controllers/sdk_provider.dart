import 'package:flutter/cupertino.dart';
import 'package:swift_agents/src/services/swift_agents_client.dart';
import '../models/init_session_response.dart';
import '../models/msg_model.dart';
import '../screens/widgets/chat_bubble.dart';

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

  // 2. Send message
// 2. Send message
  Future<void> sendMessage({
    required String sessionId,
    required String message,
  }) async {
    _isSendingMessage = true;
    _streamedMessage = '';
    _messageError = null;

    // 1. Add the User's Message bubble to the list immediately
    _messages.add(MsgModel(message, BubbleRole.user));
    notifyListeners();

    try {
      // Keep track of the current role we are streaming and the active bubble's index
      BubbleRole? currentActiveRole;
      int activeMessageIndex = -1;

      await for (final chunk in client.sendMessage(
        sessionId: sessionId,
        message: message,
      )) {

        // DETECT ROLE CHANGE: If this chunk's role is different from the last one we saw
        if (chunk.role != currentActiveRole) {
          // Update the tracking state to the new role
          currentActiveRole = chunk.role;

          // Clear the buffered text accumulated from the PREVIOUS role step
          _streamedMessage = '';

          // Append a fresh, empty bubble to host this new phase of the stream
          _messages.add(MsgModel('', currentActiveRole));

          // Target the very last index (the bubble we just added) as our update spot
          activeMessageIndex = _messages.length - 1;
        }

        // Replace / Accumulate text for system / agent role respectively.
        if (chunk.role == BubbleRole.system) {
          _streamedMessage = chunk.text;
        } else {
          _streamedMessage += chunk.text;
        }

        // Safely update the correct message bubble at our floating pointer index
        if (activeMessageIndex != -1) {
          _messages[activeMessageIndex] = MsgModel(
            _streamedMessage,
            currentActiveRole!,
          );
        }

        notifyListeners();
      }
    } catch (e) {
      _messageError = e.toString();
      _messages.add(MsgModel('Error: ${e.toString()}', BubbleRole.system));
      notifyListeners();
    } finally {
      _isSendingMessage = false;
      notifyListeners();
    }
  }

  // // 2. Send message
  // Future<void> sendMessage({
  //   required String sessionId,
  //   required String message,
  // }) async {
  //   _isSendingMessage = true;
  //   _streamedMessage = '';
  //   _messageError = null;
  //
  //   // 1. Add the User's Message bubble to the list immediately
  //   _messages.add(MsgModel(message, BubbleRole.user));
  //   notifyListeners();
  //
  //   try {
  //     // 2. Create a single placeholder Agent message that we will mutate dynamically
  //     int agentMessageIndex = _messages.length;
  //     notifyListeners();
  //
  //     await for (final chunk in client.sendMessage(
  //       sessionId: sessionId,
  //       message: message,
  //     )) {
  //       _streamedMessage += chunk.text;
  //
  //       // 3. Keep updating the content field of our active agent bubble
  //       final storedMsg = _messages.elementAtOrNull(agentMessageIndex);
  //
  //       if (chunk.role == BubbleRole.system) {
  //         // 3a. add system message
  //         if (storedMsg?.role != BubbleRole.system || storedMsg == null) {
  //           _messages.add(MsgModel('', BubbleRole.system));
  //         }
  //         _messages[agentMessageIndex] = MsgModel(
  //           _streamedMessage,
  //           BubbleRole.system,
  //         );
  //       } else {
  //         // 3b. add agent message
  //         if (storedMsg?.role != BubbleRole.agent || storedMsg == null) {
  //           _messages.add(MsgModel('', BubbleRole.agent));
  //         }
  //         _messages[agentMessageIndex] = MsgModel(
  //           _streamedMessage,
  //           BubbleRole.agent,
  //         );
  //       }
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     _messageError = e.toString();
  //     // Optional: Add a system message bubble or handle error text contextually
  //     _messages.add(MsgModel('Error: ${e.toString()}', BubbleRole.system));
  //     notifyListeners();
  //   } finally {
  //     _isSendingMessage = false;
  //     notifyListeners();
  //   }
  // }
}
