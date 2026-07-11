import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents_core/src/controllers/sdk_provider.dart';
import 'package:swift_agents_core/src/screens/widgets/chat_bubble.dart';
import 'package:swift_agents_core/src/theme/theme.dart';
import '../models/msg_model.dart';

class MessagesScreen extends StatefulWidget {
  final List<MsgModel> messages;
  final VoidCallback? onClose;
  final VoidCallback? onMenuTap;
  final double lastMsgBottomPadding;

  const MessagesScreen({
    super.key,
    this.onClose,
    this.onMenuTap,
    this.messages = const [],
    this.lastMsgBottomPadding = 0,
  });

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    final sdkProvider = Provider.of<SdkProvider>(context);

    return Expanded(
      child: ListView.builder(
        reverse: true,
        itemCount: widget.messages.length,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        itemBuilder: (context, index) {
          final m = widget.messages.reversed.toList()[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ChatBubble(message: m),
              if ((widget.messages.last == m) &&
                  sdkProvider.showCurrentMsgLoading)
                Align(
                  alignment: Alignment.centerLeft,
                  child: ChatBubbleLoading(),
                ),
              if (widget.messages.last == m)
                SizedBox(height: widget.lastMsgBottomPadding),
            ],
          );
        },
      ),
    );
  }
}

// ***SCREEN-ONLY WIDGETs***
// 1.
class ChatBubbleLoading extends StatefulWidget {
  const ChatBubbleLoading({super.key});

  @override
  State<ChatBubbleLoading> createState() => _ChatBubbleLoadingState();
}

class _ChatBubbleLoadingState extends State<ChatBubbleLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const int dotCount = 4;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _activeDot => ((_controller.value * dotCount).floor()) % dotCount;

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          height: 40,
          width: 93,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF9DCCFF).withOpacity(0.02),
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(dotCount, (index) {
              final isActive = index == _activeDot;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive
                        ? t.userBubble
                        : const Color.fromARGB(255, 175, 207, 245),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
