import 'package:swift_agents/src/models/conversations_response.dart';
import 'package:swift_agents/src/models/upload_attachments_response.dart';

import '../screens/widgets/chat_bubble.dart';

class MsgModel {
  final String text;
  final BubbleRole role;
  final ConversationSession? session;
  final List<AttachmentModel>? attachments;

  MsgModel(this.text, this.role, this.attachments, {this.session});
}

