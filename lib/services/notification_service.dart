import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';
import 'chat_service.dart';

class NotificationService {
  /// Get unread message count for a user
  static Future<int> getUnreadMessageCount(String userId) async {
    try {
      debugPrint('🔔 Getting unread count for user: $userId');
      
      // Get all chats for the user
      final chats = await ChatService.getUserChats(userId);
      int totalUnread = 0;
      
      for (final chat in chats) {
        if (chat['buyer_id'] == userId) {
          totalUnread += (chat['unread_count_buyer'] as int? ?? 0);
        } else if (chat['seller_id'] == userId) {
          totalUnread += (chat['unread_count_seller'] as int? ?? 0);
        }
      }
      
      debugPrint('🔔 Total unread messages: $totalUnread');
      return totalUnread;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }
  
  /// Stream of unread message count for real-time updates
  static Stream<int> getUnreadCountStream(String userId) async* {
    while (true) {
      try {
        final count = await getUnreadMessageCount(userId);
        yield count;
        
        // Wait 5 seconds before checking again
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('❌ Error in unread count stream: $e');
        yield 0;
        await Future.delayed(const Duration(seconds: 10));
      }
    }
  }
  
  /// Mark all messages as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      debugPrint('✅ Marking all messages as read for user: $userId');
      
      final chats = await ChatService.getUserChats(userId);
      
      for (final chat in chats) {
        final isBuyer = chat['buyer_id'] == userId;
        await ChatService.markAsRead(chat['id'], userId, isBuyer);
      }
      
      debugPrint('✅ All messages marked as read');
    } catch (e) {
      debugPrint('❌ Error marking all as read: $e');
    }
  }
}