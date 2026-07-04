import 'package:swift_agents/src/models/upload_attachments_response.dart';
import 'package:swift_agents/src/screens/widgets/chat_bubble.dart';

class ConversationDetailsResponse {
  final String id;
  final String? type;
  final String? subject;
  final bool resolved;
  final DateTime? resolvedAt;
  final List<ConversationMessage> messages;
  final List<ConversationMessage> attributedChat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConversationDetailsResponse({
    required this.id,
    this.type,
    this.subject,
    this.resolvedAt,
    this.resolved = false,
    this.messages = const [],
    this.attributedChat = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ConversationDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationDetailsResponse(
      id: json['id'],
      type: json['type'],
      subject: json['subject'],
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
      resolved: json['resolved'] ?? false,
      messages:
          (json['messages'] as List<dynamic>?)
              ?.map((e) => ConversationMessage.fromJson(e))
              .toList() ??
          [],
      attributedChat:
          (json['attributed_chat'] as List<dynamic>?)
              ?.map((e) => ConversationMessage.fromJson(e))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'subject': subject,
      'resolved': resolved,
      'resolved_at': resolvedAt?.toIso8601String(),
      'messages': messages.map((e) => e.toJson()).toList(),
      'attributed_chat': attributedChat.map((e) => e.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ConversationMessage {
  final String? id;
  final BubbleRole? role;
  final String? content;
  final DateTime? timestamp;
  final List<AttachmentModel>? attachments;
  final String? authorName;
  final String? avatarUrl;
  final AuthorType? authorType;

  ConversationMessage({
    this.id,
    this.role,
    this.content,
    this.timestamp,
    this.attachments,
    this.authorName,
    this.avatarUrl,
    this.authorType,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    // final bubbleRoles = BubbleRole.values;
    // final authorTypes = AuthorType.values;
    return ConversationMessage(
      id: json['id'],
      role: BubbleRole.values.singleWhere(
        (type) => type.name == (json['role'] as String?)?.toLowerCase(),
        orElse: () => BubbleRole.assistant, // Default to assistant if role is not found
      ),
      content: json['content'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachmentModel.fromJson(e))
          .toList(),
      authorName: json['author_name'],
      avatarUrl: json['avatar_url'],
      authorType: AuthorType.values.singleWhere(
        (type) => type.name == (json['author_type'] as String?)?.toLowerCase(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role?.name,
      'content': content,
      'timestamp': (timestamp is DateTime)
          ? timestamp?.toIso8601String()
          : timestamp,
      'attachments': attachments?.map((e) => e.toJson()).toList(),
      'author_name': authorName,
      'avatar_url': avatarUrl,
      'author_type': authorType?.name,
    };
  }
}
