import 'dart:async';
import 'package:flutter/material.dart';
import 'package:marqueer/marqueer.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/src/screens/widgets/animated_avatar_player.dart';
import 'package:swift_agents/src/screens/widgets/button_filled.dart';
import 'package:swift_agents/src/screens/widgets/chat_input.dart';
import 'package:swift_agents/src/screens/widgets/top_bar.dart';
import '../../swift_agents.dart';
import '../constants/fonts.dart';
import '../constants/variables.dart';
import '../controllers/online_provider.dart';
import '../controllers/sdk_provider.dart';
import '../theme/theme.dart';
import '../utils/file_util.dart';
import 'messages_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onClose;

  const HomeScreen({super.key, this.onMenuTap, this.onClose});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<UploadFile> sFiles = [];

  void _onSubmit(String text) {
    final sdkProvider = context.read<SdkProvider>();
    final isOnline = Provider.of<OnlineProvider>(
      context,
      listen: false,
    ).isOnline;

    final sessionId = sdkProvider.currentSessionId;

    sdkProvider.sendMessage(
      sessionId: sessionId,
      message: text,
      isOnline: isOnline,
    );
  }

  void _onUpload(List<UploadFile> files) async {
    sFiles = files; // List of already used Chat input
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    final onlineProvider = Provider.of<OnlineProvider>(context, listen: false);

    await sdkProvider.uploadAttachments(files: sFiles);

    onlineProvider.onlineStream.listen((bool isOnline) async {
      if (isOnline && sFiles.isNotEmpty) {
        await sdkProvider.uploadAttachments(files: sFiles);
      }
    });
  }

  void _onRemove(UploadFile removedFile) {
    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    // Remove file, so it doesn't upload a cancelled file, when usr is back online.
    sFiles.removeWhere((sFile) => sFile.name == removedFile.name);
    // Remove previous uploaded file, so sdk doesn't send msg with cancelled files
    sdkProvider.removeUploadedAttachment(file: removedFile);
  }

  @override
  Widget build(BuildContext context) {
    final sdkProvider = Provider.of<SdkProvider>(context);
    final activeMessages = sdkProvider.messages;
    var selectedIndex = sdkProvider.selectedConversationIndex;
    var conversation = sdkProvider.selectedConversation;
    final showReopenTicket =
        conversation?.type == "ticket" && conversation?.resolved == true;

    return Stack(
      children: [
        Column(
          children: [
            TopBar(onMenuTap: widget.onMenuTap, onClose: widget.onClose),
            activeMessages.isEmpty && (selectedIndex == null)
                ? NoMsgWidget(onSuggest: _onSubmit)
                : MessagesScreen(
                    messages: activeMessages,
                    onClose: widget.onClose,
                    onMenuTap: widget.onMenuTap,
                    lastMsgBottomPadding: showReopenTicket ? 95 : 0,
                  ),
            Opacity(
              opacity: showReopenTicket ? 0.25 : 1,
              child: IgnorePointer(
                ignoring: showReopenTicket,
                child: ChatInput(
                  onSubmit: _onSubmit,
                  onAttach: _onUpload,
                  onRemove: _onRemove,
                ),
              ),
            ),
          ],
        ),
        if (showReopenTicket)
          Align(alignment: Alignment.bottomCenter, child: ReopenTicket()),
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
        margin: EdgeInsets.fromLTRB(isFirst ? 15 : 5, 0, isLast ? 80 : 5, 0),
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
    final sdkProvider = Provider.of<SdkProvider>(context);
    final t = SwiftAgentsTheme.of(context);

    final company = sdkProvider.initSessionResponse?.company;
    final suggestions = company?.suggestedAIPrompts ?? [];
    final enableSuggestions = company?.enableSuggestedPrompts ?? false;

    final firstSLength = suggestions.isEmpty
        ? 0
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
              if (firstSLength > 0 && enableSuggestions)
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
                        final suggested = suggestions[index].toUpperCase();
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
              if (secondSLength > 0 && enableSuggestions)
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
                        final suggested = suggestions[offset].toUpperCase();
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

// 3.

class ReopenTicket extends StatefulWidget {
  const ReopenTicket({super.key});

  @override
  State<ReopenTicket> createState() => _ReopenTicketState();
}

class _ReopenTicketState extends State<ReopenTicket> {
  Timer? _timer;
  String _countdown = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final sdkProvider = Provider.of<SdkProvider>(context, listen: false);
    final resolvedAt =
        sdkProvider.selectedConversation?.resolvedAt ??
        sdkProvider.selectedConversation?.updatedAt;

    if (resolvedAt != null && _timer == null) {
      _startCountdown(resolvedAt);
    }
  }

  void _startCountdown(DateTime updatedAt) {
    final updatedTime = updatedAt.toLocal();

    _updateCountdown(updatedTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown(updatedTime);
    });
  }

  void _updateCountdown(DateTime updatedTime) {
    final expiryTime = updatedTime.add(const Duration(hours: 48));

    final remaining = expiryTime.difference(DateTime.now());

    if (remaining.isNegative) {
      _timer?.cancel();

      if (mounted) {
        setState(() {
          _countdown = 'EXPIRED';
        });
      }
      return;
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (mounted) {
      setState(() {
        if (hours > 0) {
          _countdown = '${hours}HR ${minutes}M';
        } else if (minutes > 0) {
          _countdown = '${minutes}M ${seconds}S';
        } else {
          _countdown = '${seconds}S';
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = SwiftAgentsTheme.of(context);
    final sdkProvider = Provider.of<SdkProvider>(context);
    final conversation = sdkProvider.selectedConversation;

    final expired = _countdown == 'EXPIRED';

    return Container(
      width: 307,
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: t.agentBubble,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(width: 1, color: t.userBubble.withAlpha(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'This chat has been closed as the ticket is resolved. Would you like to reopen it for further assistance?',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.85,
              fontFamily: Fonts.stoizi,
              package: Variables.sdkName,
            ),
          ),
          const SizedBox(height: 15),
          ButtonFilled(
            onPressed: () {
              final convoId = conversation?.id;
              if (convoId != null && !expired) {
                sdkProvider.reOpenTicket(conversationId: convoId);
              }
            },
            isLoading: sdkProvider.isCurrentReopenTicketsLoading,
            boxShadows: null,
            margin: EdgeInsets.zero,
            backgroundColor: expired ? Colors.grey[700] : Color(0xFF03A84E),
            text: expired
                ? 'REOPEN WINDOW EXPIRED'
                : 'REOPEN TICKET? ($_countdown)',
          ),
        ],
      ),
    );
  }
}
