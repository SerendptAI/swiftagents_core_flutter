import 'package:swift_agents/src/models/conversations_response.dart';

import '../screens/widgets/chat_bubble.dart';

class MsgModel {
  final String text;
  final BubbleRole role;
  final ConversationSession? session;

  MsgModel(this.text, this.role, {this.session});
}

