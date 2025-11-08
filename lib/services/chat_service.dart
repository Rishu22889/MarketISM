import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class ChatService {
  static const String chatsTable = 'chats';
  static const String messagesTable = 'messages';
  
  /// Create or get existing chat between buyer and seller for an item
  static Future<String?> createOrGetChat({
    required String itemId,
    required String buyerId,
    required String sellerId,
    required String itemTitle,
  }) async {
    try {
      debugPrint('🗨️ Creating/getting chat for item: $itemId');
      debugPrint('👤 Buyer: $buyerId, Seller: $sellerId');
      
      // Check if chat already exists
      final existingChat = await SupabaseConfig.client
          .from(chatsTable)
          .select('id')
          .eq('item_id', itemId)
          .eq('buyer_id', buyerId)
          .eq('seller_id', sellerId)
          .maybeSingle();
      
      if (existingChat != null) {
        debugPrint('✅ Found existing chat: ${existingChat['id']}');
        return existingChat['id'];
      }
      
      // Create new chat with proper data types
      final chatData = {
        'item_id': itemId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'item_title': itemTitle,
        'last_message': '',
        'last_message_at': DateTime.now().toIso8601String(),
        'unread_count_buyer': 0,
        'unread_count_seller': 0,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      debugPrint('📝 Inserting chat data: $chatData');
      
      final response = await SupabaseConfig.client
          .from(chatsTable)
          .insert(chatData)
          .select('id')
          .single();
      
      debugPrint('✅ Created new chat: ${response['id']}');
      return response['id'];
    } catch (e) {
      debugPrint('❌ Error creating/getting chat: $e');
      debugPrint('❌ Error details: ${e.toString()}');
      
      // Try a simpler approach if the above fails
      try {
        debugPrint('🔄 Trying simplified chat creation...');
        final simpleResponse = await SupabaseConfig.client
            .from(chatsTable)
            .insert({
              'item_id': itemId,
              'buyer_id': buyerId,
              'seller_id': sellerId,
            })
            .select('id')
            .single();
        
        debugPrint('✅ Created chat with simple approach: ${simpleResponse['id']}');
        return simpleResponse['id'];
      } catch (e2) {
        debugPrint('❌ Simple approach also failed: $e2');
        return null;
      }
    }
  }
  
  /// Send a message in a chat
  static Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    required bool isBuyer,
  }) async {
    try {
      debugPrint('📤 Sending message to chat: $chatId');
      debugPrint('👤 Sender: $senderId, Message: $message');
      
      // Insert message
      await SupabaseConfig.client
          .from(messagesTable)
          .insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'message': message,
            'created_at': DateTime.now().toIso8601String(),
          });
      
      // Update chat with last message (simplified approach without RPC)
      try {
        // Get current unread count
        final currentChat = await SupabaseConfig.client
            .from(chatsTable)
            .select('unread_count_buyer, unread_count_seller')
            .eq('id', chatId)
            .single();
        
        final currentBuyerCount = currentChat['unread_count_buyer'] ?? 0;
        final currentSellerCount = currentChat['unread_count_seller'] ?? 0;
        
        // Increment the appropriate unread count
        final newBuyerCount = isBuyer ? currentBuyerCount : currentBuyerCount + 1;
        final newSellerCount = isBuyer ? currentSellerCount + 1 : currentSellerCount;
        
        await SupabaseConfig.client
            .from(chatsTable)
            .update({
              'last_message': message,
              'last_message_at': DateTime.now().toIso8601String(),
              'unread_count_buyer': newBuyerCount,
              'unread_count_seller': newSellerCount,
            })
            .eq('id', chatId);
      } catch (updateError) {
        debugPrint('⚠️ Error updating chat metadata: $updateError');
        // Message was sent successfully, just metadata update failed
      }
      
      debugPrint('✅ Message sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return false;
    }
  }
  
  /// Get messages for a chat with real-time subscription
  static Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    debugPrint('📡 Setting up messages stream for chat: $chatId');
    
    return SupabaseConfig.client
        .from(messagesTable)
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((data) {
          debugPrint('📨 Received ${data.length} messages for chat: $chatId');
          return data;
        });
  }
  
  /// Get user's chats
  static Future<List<Map<String, dynamic>>> getUserChats(String userId) async {
    try {
      debugPrint('📋 Getting chats for user: $userId');
      
      final response = await SupabaseConfig.client
          .from(chatsTable)
          .select('''
            id,
            item_id,
            item_title,
            buyer_id,
            seller_id,
            last_message,
            last_message_at,
            unread_count_buyer,
            unread_count_seller,
            buyer:buyer_id(name, email),
            seller:seller_id(name, email)
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('last_message_at', ascending: false);
      
      debugPrint('✅ Found ${response.length} chats for user');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting user chats: $e');
      return [];
    }
  }
  
  /// Mark messages as read
  static Future<void> markAsRead(String chatId, String userId, bool isBuyer) async {
    try {
      debugPrint('✅ Marking chat as read: $chatId for user: $userId');
      
      final unreadField = isBuyer ? 'unread_count_buyer' : 'unread_count_seller';
      
      await SupabaseConfig.client
          .from(chatsTable)
          .update({unreadField: 0})
          .eq('id', chatId);
      
      debugPrint('✅ Chat marked as read');
    } catch (e) {
      debugPrint('❌ Error marking chat as read: $e');
    }
  }
  
  /// Get unread message count for user
  static Future<int> getUnreadCount(String userId) async {
    try {
      final chats = await getUserChats(userId);
      int totalUnread = 0;
      
      for (final chat in chats) {
        if (chat['buyer_id'] == userId) {
          totalUnread += (chat['unread_count_buyer'] as int? ?? 0);
        } else {
          totalUnread += (chat['unread_count_seller'] as int? ?? 0);
        }
      }
      
      debugPrint('📊 Total unread messages for user $userId: $totalUnread');
      return totalUnread;
    } catch (e) {
      debugPrint('❌ Error getting unread count: $e');
      return 0;
    }
  }
}