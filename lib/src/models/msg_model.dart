import 'package:swift_agents_core/src/models/conversations_response.dart';
import 'package:swift_agents_core/src/models/upload_attachments_response.dart';

import '../screens/widgets/chat_bubble.dart';

class MsgModel {
  final String? id;
  final String text;
  final BubbleRole role;
  final DateTime? timestamp;
  final List<AttachmentModel>? attachments;
  final ConversationSession? session;
  final String? authorName;
  final String? avatarUrl;
  final AuthorType? authorType;
  bool isSent;

  MsgModel(
    this.id,
    this.text,
    this.role,
    this.attachments,
    this.timestamp, {
    this.session,
    required this.authorName,
    required this.avatarUrl,
    required this.authorType,
    this.isSent = true,
  });
}
