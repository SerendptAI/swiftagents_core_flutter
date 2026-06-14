import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents/src/constants/fonts.dart';
import 'package:swift_agents/src/constants/variables.dart';
import 'package:swift_agents/src/controllers/sdk_provider.dart';
import 'package:swift_agents/src/models/msg_model.dart';
import 'package:swift_agents/src/models/upload_attachments_response.dart';
import '../../../swift_agents.dart';
import 'get_cached_image.dart';

enum BubbleRole { user, agent, system }

class ChatBubble extends StatefulWidget {
  final MsgModel message;

  const ChatBubble({super.key, required this.message});

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
    final isStreaming = sdkProvider.isCurrentMsgSending;

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

  Color getFileColor(String extension) {
    switch (extension.toLowerCase().replaceAll('.', '')) {
    // Adobe
      case 'pdf':
        return const Color(0xFFD32F2F); // Adobe Red

    // Microsoft Office
      case 'doc':
      case 'docx':
        return const Color(0xFF185ABD); // Word Blue

      case 'xls':
      case 'xlsx':
      case 'csv':
        return const Color(0xFF107C41); // Excel Green

      case 'ppt':
      case 'pptx':
        return const Color(0xFFD24726); // PowerPoint Orange

    // Images
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'svg':
        return const Color(0xFF8E44AD); // Vibrant Purple

    // Video
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
      case 'webm':
        return const Color(0xFFE91E63); // Pink

    // Audio
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'ogg':
      case 'flac':
        return const Color(0xFF9C27B0); // Deep Purple

    // Archives
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
        return const Color(0xFFFF9800); // Orange

    // Executables
      case 'exe':
      case 'msi':
      case 'apk':
      case 'ipa':
        return const Color(0xFF607D8B); // Blue Grey

    // Code
      case 'dart':
        return const Color(0xFF0175C2); // Dart Blue

      case 'js':
      case 'ts':
        return const Color(0xFFF7DF1E); // JavaScript Yellow

      case 'html':
        return const Color(0xFFE34F26); // HTML Orange

      case 'css':
        return const Color(0xFF1572B6); // CSS Blue

      case 'json':
        return const Color(0xFFFBC02D); // JSON Gold

      case 'xml':
        return const Color(0xFFFF7043);

      case 'java':
        return const Color(0xFFED8B00);

      case 'py':
        return const Color(0xFF3776AB); // Python Blue

    // Text
      case 'txt':
      case 'rtf':
        return Colors.grey;

      default:
        return Color(0xFF3a3a3a);
    }
  }

  Widget showAttachment(
    AttachmentModel attachment, {
    double height = 140,
    double width = 168,
  }) {
    double extFontSize = max((0.505 * width), 20);
    final extText = attachment.getFileExtension?.toUpperCase();
    final deco = BoxDecoration(
      color: attachment.isImage? Color(0xFF3a3a3a):getFileColor(extText ?? ''),
      borderRadius: BorderRadius.circular(22),
    );

    return attachment.isImage
        ? Container(
            width: width,
            height: height,
            decoration: deco,
            clipBehavior: Clip.hardEdge,
            child: GetCachedImage(
              url: attachment.url,
              placeholder: Icon(Icons.image_sharp, color: Colors.grey),
            ),
          )
        : Container(
            width: width,
            height: height,
            decoration: deco,
            alignment: Alignment.center,
            child: Text(
              extText ?? attachment.filename ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: extFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                // fontFamily: Fonts.greedNarrow,
                // package: Variables.sdkName,
              ),
            ),
          );
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
    final attachments = msg.attachments ?? [];
    final aLength = attachments.length;

    if (msg.role == BubbleRole.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        child: Text(
          msg.text.toUpperCase(), // System texts show instantly
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (aLength > 0) SizedBox(height: 20),
          if (aLength == 1)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: showAttachment(attachments.first),
            )
          else if (aLength == 2)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  showAttachment(attachments.first, width: 104, height: 95),
                  SizedBox(width: 15),
                  showAttachment(attachments.last, width: 104, height: 95),
                ],
              ),
            )
          else if (aLength > 2)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Wrap(
                spacing: 12,
                children: attachments
                    .map((a) => showAttachment(a, width: 84, height: 75))
                    .toList(),
              ),
            ),
          Container(
            margin: EdgeInsets.only(top: aLength > 0 ? 16 : 25, bottom: 5),
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
                fontWeight: FontWeight.w400,
                package: Variables.sdkName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
