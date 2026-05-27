import 'package:flutter/material.dart';
import 'package:swift_agents/src/screens/widgets/chat_bubble.dart';
import '../models/msg_model.dart';

class MessagesScreen extends StatefulWidget {
  final List<MsgModel> messages;
  final VoidCallback? onClose;
  final VoidCallback? onMenuTap;

  const MessagesScreen({
    super.key,
    this.onClose,
    this.onMenuTap,
    this.messages = const [],
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        reverse: true,
        itemCount: widget.messages.length,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemBuilder: (context, index) {
          final m = widget.messages.reversed.toList()[index];
          return ChatBubble(message: m);
        },
      ),
    );
  }
}
