class ConversationsResponse {
  final List<ConversationItem>? items;
  final String? nextCursor;
  final bool hasNext;

  ConversationsResponse({
    this.items,
    this.nextCursor,
    this.hasNext = false,
  });

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => ConversationItem.fromJson(e))
          .toList(),
      nextCursor: json['next_cursor'],
      hasNext: json['has_next'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items?.map((e) => e.toJson()).toList(),
      'next_cursor': nextCursor,
      'has_next': hasNext,
    };
  }
}

class ConversationItem {
  final String? id;
  final String? type;
  final String? subject;
  final String? lastMessage;
  final bool resolved;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConversationItem({
    this.id,
    this.type,
    this.subject,
    this.lastMessage,
    this.resolved = false,
    this.messageCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'],
      type: json['type'],
      subject: json['subject'],
      lastMessage: json['last_message'],
      resolved: json['resolved'] ?? false,
      messageCount: json['message_count'] ?? 0,
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
      'last_message': lastMessage,
      'resolved': resolved,
      'message_count': messageCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}