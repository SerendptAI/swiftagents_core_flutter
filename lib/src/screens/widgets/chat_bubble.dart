import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/constants/fonts.dart';
import 'package:swift_agents/src/constants/variables.dart';
import 'package:swift_agents/src/controllers/sdk_provider.dart';
import 'package:swift_agents/src/models/msg_model.dart';
import '../../../swift_agents.dart';

enum BubbleRole { user, agent, system }

class ChatBubble extends StatefulWidget {
  final MsgModel message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  String _displayedText = "";
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeTextProcessing();
  }

  @override
  void didUpdateWidget(covariant ChatBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation only if the incoming text payload changes


    if ((oldWidget.message != widget.message)) {
      _timer?.cancel();
      _initializeTextProcessing();
    }
  }

  void _initializeTextProcessing() {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    final msg = widget.message;
    final lastMsg = sdkProvider.messages.last;
    final isStreaming = sdkProvider.isSendingMessage;

    final isLast = lastMsg == msg;

    // Only animate if the role is Agent
    if ((msg.role == BubbleRole.agent) && isLast && isStreaming) {
      _displayedText = "";
      _currentIndex = 0;
      _startTyping();
    } else {
      _displayedText = msg.text;
    }
  }

  void _startTyping() {
    _timer = Timer.periodic(const Duration(microseconds: 600), (timer) {
      if (_currentIndex < widget.message.text.length) {
        if (mounted) {
          setState(() {
            _displayedText += widget.message.text[_currentIndex];
            _currentIndex++;
          });
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    final msg = widget.message;

    if (msg.role == BubbleRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        child: Text(
          msg.text, // System texts show instantly
          style: TextStyle(
            color: t.foreground,
            fontSize: 12,
            fontFamily: Fonts.dmMono,
            package: Variables.sdkName,
          ),
        ),
      );
    }

    final isUser = msg.role == BubbleRole.user;
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
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        child: SelectableText(
          _displayedText, // Renders the typing stream or raw user text
          style: TextStyle(
            color: isUser ? Colors.white : t.userBubble,
            fontSize: 14,
            height: 1.35,
            fontFamily: Fonts.stoizi,
            fontWeight: FontWeight.w300,
            package: Variables.sdkName,
          ),
        ),
      ),
    );
  }
}
