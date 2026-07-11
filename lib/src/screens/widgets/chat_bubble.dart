import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:swift_agents_core/src/constants/colors.dart';
import 'package:swift_agents_core/src/constants/fonts.dart';
import 'package:swift_agents_core/src/constants/variables.dart';
import 'package:swift_agents_core/src/controllers/sdk_provider.dart';
import 'package:swift_agents_core/src/models/msg_model.dart';
import 'package:swift_agents_core/src/models/upload_attachments_response.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:swift_agents_core/src/utils/file_util.dart';
import 'package:swift_agents_core/src/utils/utils.dart';
import '../../../swift_agents_core.dart';
import 'get_cached_image.dart';

enum BubbleRole { user, assistant, system, inbound, outbound, error }

enum AuthorType { user, ai, agent }

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
    final isStreaming = sdkProvider.showCurrentMsgTyping;

    final isLast = lastMsg == msg;

    // Only animate if the role is Agent
    if ((msg.role == BubbleRole.assistant) && isLast && isStreaming) {
      _displayedText = "";
      _currentIndex = 0;
      _startTyping();
    } else {
      _displayedText = msg.text;
    }
  }

  void _startTyping() {
    const interval = Duration(milliseconds: 18);

    _timer?.cancel();

    _timer = Timer.periodic(interval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final text = widget.message.text;

      if (_currentIndex >= text.length) {
        timer.cancel();
        return;
      }

      // Larger messages = larger chunks
      final chunkSize = switch (text.length) {
        <= 200 => 4,
        <= 800 => 10,
        <= 2000 => 20,
        _ => 40,
      };

      final nextIndex = min(_currentIndex + chunkSize, text.length);

      setState(() {
        _displayedText = text.substring(0, nextIndex);
        _currentIndex = nextIndex;
      });
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
    final extText = attachment.filename ?? '';
    double extFontSize = extText.length > 3 ? 12 : max((0.505 * width), 20);
    final deco = BoxDecoration(
      color: attachment.isImage
          ? Color(0xFF3a3a3a)
          : getFileColor(attachment.getFileExtension ?? ''),
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
            padding: const EdgeInsets.all(3.0),
            child: Text(
              FileUtils.getFileNameFromSignature(extText).toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: extFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                fontFamily: Fonts.greedNarrow,
                package: Variables.sdkName,
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
    final sdkProvider = Provider.of<SdkProvider>(context);
    final initSessionResponse = sdkProvider.initSessionResponse;
    final company = initSessionResponse?.company;
    final msg = widget.message;
    final attachments = msg.attachments ?? [];
    final aLength = attachments.length;
    final utils = Utils();

    if (msg.role == BubbleRole.system) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
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
        ),
      );
    }

    final isUser =
        msg.role == BubbleRole.user ||
        (msg.role == BubbleRole.inbound && msg.authorType == AuthorType.user);
    final isHumanAgent =
        msg.avatarUrl != null &&
        msg.authorName != null &&
        !isUser &&
        msg.authorType == AuthorType.agent;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          SizedBox(height: aLength > 0 ? 16 : 14),
          // Human agent profile
          if (isHumanAgent)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(shape: BoxShape.circle),
                  clipBehavior: Clip.hardEdge,
                  child: GetCachedImage(
                    url: msg.avatarUrl,
                    width: 30.5,
                    height: 30.5,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  msg.authorName ?? 'Agent',
                  style: TextStyle(
                    fontSize: 12,
                    color: t.foreground,
                    fontFamily: Fonts.stoizi,
                    package: Variables.sdkName,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 17.69,
                  height: 17.21,
                  color: kLibPurple,
                  alignment: Alignment.center,
                  child: GetCachedImage(
                    url: company?.logoUrl,
                    placeholder: Text(
                      'LOGO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        fontFamily: Fonts.greedNarrow,
                        package: Variables.sdkName,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          // Attachment Images
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
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Agent Profile
              Visibility(
                visible: !isHumanAgent && !isUser,
                child: Container(
                  width: 30.5,
                  height: 30.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: GetCachedImage(
                    url: company?.logoUrl,
                    width: 32,
                    height: 32,
                  ),
                ),
              ),
              // Txt Bubble
              Container(
                margin: EdgeInsets.only(
                  top: 14,
                  bottom: 5,
                  left: isHumanAgent && !isUser ? 40 : 14,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width *
                      (isUser ? 0.78 : 0.75),
                ),
                decoration: BoxDecoration(
                  color: isUser ? t.userBubble : t.agentBubble,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                ),
                child: isUser
                    ? Text(
                        _displayedText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.35,
                          fontFamily: Fonts.stoizi,
                          fontWeight: FontWeight.w400,
                          package: Variables.sdkName,
                        ),
                      )
                    : MarkdownBody(
                        data: _displayedText,
                        selectable: true,
                        extensionSet: md.ExtensionSet.gitHubFlavored,
                        shrinkWrap: true,
                        softLineBreak: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 14,
                            height: 1.35,
                            fontFamily: Fonts.stoizi,
                            fontWeight: FontWeight.w400,
                            package: Variables.sdkName,
                          ),

                          h1: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: Fonts.stoizi,
                            package: Variables.sdkName,
                          ),

                          h2: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: Fonts.stoizi,
                            package: Variables.sdkName,
                          ),

                          h3: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: Fonts.stoizi,
                            package: Variables.sdkName,
                          ),

                          strong: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: Fonts.stoizi,
                            package: Variables.sdkName,
                          ),

                          em: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontFamily: Fonts.stoizi,
                            package: Variables.sdkName,
                          ),

                          listBullet: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 14,
                            fontFamily: Fonts.stoizi,
                            package: Variables.sdkName,
                          ),

                          blockquote: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 14,
                            height: 1.35,
                            fontFamily: Fonts.stoizi,
                            package: Variables.sdkName,
                          ),

                          code: TextStyle(
                            color: isUser ? Colors.white : t.userBubble,
                            fontSize: 13,
                            fontFamily: Fonts.dmMono,
                            package: Variables.sdkName,
                          ),

                          codeblockDecoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
              ),
            ],
          ),
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: !isUser ? 55 : 0,
                right: isUser ? 10 : 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUser && msg.isSent)
                    Text(
                      'Sent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF72777A),
                        fontFamily: Fonts.dmSans,
                        package: Variables.sdkName,
                      ),
                    ),
                  if (isUser && msg.isSent)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, right: 3.0),
                      child: SvgPicture.asset(
                        'assets/svgs/double_tick.svg',
                        width: 17,
                        height: 17,
                        colorFilter: ColorFilter.mode(
                          Color(0xFF72777A),
                          BlendMode.srcIn,
                        ),
                        package: Variables.sdkName,
                      ),
                    ),
                  if (msg.timestamp != null)
                    Text(
                      utils.formatDateTime(msg.timestamp!),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF72777A),
                        fontFamily: Fonts.dmSans,
                        package: Variables.sdkName,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
