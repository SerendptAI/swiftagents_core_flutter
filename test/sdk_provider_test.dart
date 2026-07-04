import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swift_agents/src/constants/variables.dart';
import 'package:swift_agents/src/controllers/sdk_provider.dart';
import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/src/models/msg_model.dart';
import 'package:swift_agents/src/screens/widgets/chat_bubble.dart';
import 'package:swift_agents/src/services/conversation_messages_socket.dart';
import 'package:swift_agents/src/services/conversations_socket.dart';
import 'package:swift_agents/src/services/swift_agents_client.dart';

void main() {
  //USAGE: flutter test test/sdk_provider_test.dart
  group('SdkProvider conversation socket updates', () {
    test('merges incoming socket conversations into the visible list', () {
      final provider = SdkProvider(
        SwiftAgentsClient(dio: Dio(), email: 'test@example.com'),
        ConversationsSocket(baseUrl: Variables.apiBaseUrl),
        ConversationMessagesSocket(baseUrl: Variables.sockBaseUrl),
      );

      provider.mergeConversationsUpdate(
        ConversationsResponse(
          items: [
            ConversationSession(
              id: 'new-conversation',
              subject: 'New conversation',
              lastMessage: 'Hello',
            ),
          ],
          hasNext: false,
        ),
      );

      expect(
        provider.conversationsList.map((item) => item.id).toList(),
        contains('new-conversation'),
      );
      expect(provider.conversationsList.first.id, 'new-conversation');
    });
  });
}
