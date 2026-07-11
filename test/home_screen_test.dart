import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents_core/src/controllers/online_provider.dart';
import 'package:swift_agents_core/src/controllers/sdk_provider.dart';
import 'package:swift_agents_core/src/screens/home_screen.dart';
import 'package:swift_agents_core/src/screens/widgets/chat_input.dart';
import 'package:swift_agents_core/src/services/conversation_messages_socket.dart';
import 'package:swift_agents_core/src/services/conversations_socket.dart';
import 'package:swift_agents_core/src/services/swift_agents_client.dart';

void main() {
  testWidgets(
    'HomeScreen renders one chat input when the ticket is not resolved',
    (tester) async {
      final sdkProvider = SdkProvider(
        SwiftAgentsClient(
          dio: Dio(BaseOptions(baseUrl: 'https://example.com')),
          email: 'test@example.com',
        ),
        ConversationsSocket(baseUrl: 'https://example.com'),
        ConversationMessagesSocket(baseUrl: 'https://example.com'),
      );
      final onlineProvider = OnlineProvider();

      addTearDown(() {
        onlineProvider.dispose();
        sdkProvider.dispose();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SdkProvider>.value(value: sdkProvider),
            ChangeNotifierProvider<OnlineProvider>.value(value: onlineProvider),
          ],
          child: const MaterialApp(home: Scaffold(body: HomeScreen())),
        ),
      );

      await tester.pump();

      expect(find.byType(ChatInput), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );
}
