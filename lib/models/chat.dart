import 'package:supabase_flutter/supabase_flutter.dart';

enum ChatType { direct, itemInquiry }

class Chat {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? itemId; // optional if chat is about a specific item
  final ChatType type;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCountUser1;
  final int unreadCountUser2;

  const Chat({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.itemId,
    this.type = ChatType.direct,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCountUser1 = 0,
    this.unreadCountUser2 = 0,
  });

  // Helper: check if the chat is about an item
  bool get isItemChat => type == ChatType.itemInquiry;

  // Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'item_id': itemId,
      'type': type.name,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count_user1': unreadCountUser1,
      'unread_count_user2': unreadCountUser2,
    };
  }

  // Create Chat from Supabase record
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      itemId: json['item_id'] as String?,
      type: ChatType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'direct'),
        orElse: () => ChatType.direct,
      ),
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: DateTime.tryParse(json['last_message_time'] ?? '') ?? DateTime.now(),
      unreadCountUser1: json['unread_count_user1'] ?? 0,
      unreadCountUser2: json['unread_count_user2'] ?? 0,
    );
  }

  // Copy with method
  Chat copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    String? itemId,
    ChatType? type,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCountUser1,
    int? unreadCountUser2,
  }) {
    return Chat(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      itemId: itemId ?? this.itemId,
      type: type ?? this.type,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCountUser1: unreadCountUser1 ?? this.unreadCountUser1,
      unreadCountUser2: unreadCountUser2 ?? this.unreadCountUser2,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, user1: $user1Id, user2: $user2Id, lastMessage: "$lastMessage")';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        other.id == id &&
        other.user1Id == user1Id &&
        other.user2Id == user2Id &&
        other.itemId == itemId &&
        other.type == type &&
        other.lastMessage == lastMessage &&
        other.lastMessageTime == lastMessageTime;
  }

  @override
  int get hashCode => Object.hash(
        id,
        user1Id,
        user2Id,
        itemId,
        type,
        lastMessage,
        lastMessageTime,
        unreadCountUser1,
        unreadCountUser2,
      );
}
