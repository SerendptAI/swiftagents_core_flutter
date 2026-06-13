import 'package:swift_agents/src/models/upload_attachments_response.dart';

class ConversationDetailsResponse {
  final String id;
  final String? type;
  final String? subject;
  final bool resolved;
  final List<ConversationMessage> messages;
  final String? attributedChat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConversationDetailsResponse({
    required this.id,
    this.type,
    this.subject,
    this.resolved = false,
    this.messages = const [],
    this.attributedChat,
    this.createdAt,
    this.updatedAt,
  });

  factory ConversationDetailsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return ConversationDetailsResponse(
      id: json['id'],
      type: json['type'],
      subject: json['subject'],
      resolved: json['resolved'] ?? false,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => ConversationMessage.fromJson(e))
          .toList() ?? [],
      attributedChat: json['attributed_chat'],
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
      'messages': messages.map((e) => e.toJson()).toList(),
      'attributed_chat': attributedChat,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class ConversationMessage {
  final String? role;
  final String? content;
  final DateTime? timestamp;
  final List<AttachmentModel>? attachments;

  ConversationMessage({
    this.role,
    this.content,
    this.timestamp,
    this.attachments,
  });

  factory ConversationMessage.fromJson(
    Map<String, dynamic> json,
  ) {
    return ConversationMessage(
      role: json['role'],
      content: json['content'],
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachmentModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp?.toIso8601String(),
      'attachments': attachments?.map((e) => e.toJson()).toList(),
    };
  }
}