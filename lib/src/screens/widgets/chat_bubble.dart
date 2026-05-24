import 'package:flutter/material.dart';
import 'package:swift_agents/src/constants/fonts.dart';
import 'package:swift_agents/src/constants/variables.dart';
import '../../../swift_agents.dart';

enum BubbleRole { user, agent, system }

class ChatBubble extends StatelessWidget {
  final String text;
  final BubbleRole role;

  const ChatBubble({super.key, required this.text, required this.role});

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);

    if (role == BubbleRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        child: Text(
          text,
          style: TextStyle(
            color: t.foreground,
            fontSize: 12,
            fontFamily: Fonts.dmMono,
            package: Variables.sdkName,
          ),
        ),
      );
    }

    final isUser = role == BubbleRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 25, bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? t.userBubble : t.agentBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : t.userBubble,
            fontSize: 14,
            height: 1.35,
            // w300 maps directly to book font variant in pubspec.yaml,
            // do not change to w400.
            fontFamily: Fonts.stoizi,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}
