class ConversationsResponse {
  final List<ConversationSession>? items;
  final String? nextCursor;
  final bool hasNext;

  ConversationsResponse({this.items, this.nextCursor, this.hasNext = false});

  ConversationsResponse copyWith({
    List<ConversationSession>? items,
    String? nextCursor,
    bool? hasNext,
  }) {
    return ConversationsResponse(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNext: hasNext ?? this.hasNext,
    );
  }

  factory ConversationsResponse.fromJson(Map<String, dynamic> json) {
    return ConversationsResponse(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => ConversationSession.fromJson(e))
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

class ConversationSession {
  final String? id;
  final String? type;
  final String? subject;
  final String? lastMessage;
  final bool resolved;
  final DateTime? resolvedAt;
  final int messageCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ConversationSession({
    this.id,
    this.type,
    this.subject,
    this.lastMessage,
    this.resolved = false,
    this.resolvedAt,
    this.messageCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  ConversationSession copyWith({
    String? id,
    String? type,
    String? subject,
    String? lastMessage,
    bool? resolved,
    DateTime? resolvedAt,
    int? messageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationSession(
      id: id ?? this.id,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      lastMessage: lastMessage ?? this.lastMessage,
      resolved: resolved ?? this.resolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      messageCount: messageCount ?? this.messageCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ConversationSession.fromJson(Map<String, dynamic> json) {
    return ConversationSession(
      id: json['id'],
      type: json['type'],
      subject: json['subject'],
      lastMessage: json['last_message'],
      resolved: json['resolved'] ?? false,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'])
          : null,
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
      'resolved_at': resolvedAt?.toIso8601String(),
      'message_count': messageCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
