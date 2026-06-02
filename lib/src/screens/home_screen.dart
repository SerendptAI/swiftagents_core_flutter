import 'dart:async';

import 'package:flutter/material.dart';
import 'package:marqueer/marqueer.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/screens/widgets/animated_avatar_player.dart';
import 'package:swift_agents/src/screens/widgets/chat_bubble.dart';
import 'package:swift_agents/src/screens/widgets/chat_input.dart';
import 'package:swift_agents/src/screens/widgets/top_bar.dart';
import '../../swift_agents.dart';
import '../constants/fonts.dart';
import '../constants/variables.dart';
import '../controllers/sdk_provider.dart';
import '../models/msg_model.dart';
import '../theme/theme.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onClose;

  const HomeScreen({super.key, this.onMenuTap, this.onClose});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // void _simulateAgent() {
  //   messages.add(MsgModel('AGENT IS SEARCHING...', BubbleRole.system));
  //
  //
  //   Timer(const Duration(seconds: 3), () {
  //     if (!mounted) return;
  //     setState(() {
  //       messages.add(MsgModel('Hey there, give me a second let me search', BubbleRole.agent));
  //     });
  //
  //     Future.delayed(Duration(seconds: 1), (){
  //       setState(() {
  //         messages.addAll([
  //         MsgModel("I couldn't find info on the platform. Please hold; our support team send a response via email.", BubbleRole.agent),
  //         MsgModel("May I have your email address?", BubbleRole.agent),
  //         ]);
  //       });
  //     });
  //   });
  // }

  void _onSubmit(String text) {
    final sdkProvider = context.read<SdkProvider>();

    final sessionId = sdkProvider.currentSessionId;

    sdkProvider.sendMessage(
      sessionId: sessionId,
      message: text,
    );
  }


  @override
  Widget build(BuildContext context) {
    final sdkProvider = context.watch<SdkProvider>();
    final activeMessages = sdkProvider.messages;
    return Column(
      children: [
        TopBar(onMenuTap: widget.onMenuTap, onClose: widget.onClose),
        activeMessages.isEmpty
            ? NoMsgWidget(
                onSuggest: _onSubmit,
              )
            : MessagesScreen(
                messages: activeMessages,
                onClose: widget.onClose,
                onMenuTap: widget.onMenuTap,
              ),
        ChatInput(
          onSubmit: _onSubmit,
        ),
      ],
    );
  }
}


// ***SCREEN-ONLY WIDGETs***
// 1.
class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _SuggestionChip({
    required this.label,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: EdgeInsets.fromLTRB(
          isFirst ? 15 : 5,
          0,
          isLast ? 80 : 5,
          0,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: t.border, width: 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 2,
            fontFamily: Fonts.dmMono,
            package: Variables.sdkName,
            color: t.foreground.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}

// 2.
class NoMsgWidget extends StatelessWidget {
  final void Function(String) onSuggest;
  const NoMsgWidget({super.key, required this.onSuggest});

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);

    final suggestions = const [
      'WHAT IS THIS COMPANY ABOUT',
      'WHAT ARE THE HOURS',
      'NEED HELP WITH BILLING',
      'ADD A CARD?',
    ];

    final firstSLength = suggestions.length <= 1
        ? 1
        : (suggestions.length / 2).floor();
    final secondSLength = (suggestions.length - firstSLength).abs();
    return Expanded(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 24, 0, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              AnimatedAvatarPlayer(),
              const SizedBox(height: 15),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 285),
                child: Center(
                  child: Text(
                    'HOW CAN WE HELP\nYOU?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 35,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.02,
                      fontFamily: Fonts.greedNarrow,
                      package: Variables.sdkName,
                      color: t.foreground,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              if (firstSLength > 0)
                SizedBox(
                  height: 46,
                  child: Marqueer(
                    pps: 35.0, // Pixels per second speed
                    direction: MarqueerDirection.rtl,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: firstSLength,
                      itemBuilder: (context, index) {
                        final suggested = suggestions[index];
                        return _SuggestionChip(
                          isLast: (index + 1) == firstSLength,
                          label: suggested,
                          onTap: () {
                            onSuggest(suggested);
                          },
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 13),
              if (secondSLength > 0)
                SizedBox(
                  height: 46,
                  child: Marqueer(
                    pps: 20.0, // Pixels per second speed
                    direction: MarqueerDirection.rtl,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: secondSLength,
                      itemBuilder: (context, index) {
                        final offset = (firstSLength) + index;
                        final suggested = suggestions[offset];
                        return _SuggestionChip(
                          isFirst: firstSLength == offset,
                          isLast: (offset + 1) == suggestions.length,
                          label: suggested,
                          onTap: () {
                            onSuggest(suggested);
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
