import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../services/chat_service.dart';
import '../../theme/modern_theme.dart';
import '../../config/supabase_config.dart';
import '../../widgets/cached_network_image.dart';

class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ModernTheme.animationNormal,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadMessages();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    // Mark messages as read
    final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId != null) {
      final isBuyer = widget.chat['buyer_id'] == userId;
      ChatService.markAsRead(widget.chat['id'], userId, isBuyer);
    }
    
    _animationController.forward();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: ModernTheme.animationFast,
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    
    // Determine the other user
    final isCurrentUserBuyer = widget.chat['buyer_id'] == currentUserId;
    final otherUser = isCurrentUserBuyer ? widget.chat['seller'] : widget.chat['buyer'];
    final item = widget.chat['items'];
    
    return Scaffold(
      backgroundColor: isDarkMode ? ModernTheme.backgroundDark : ModernTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: ModernTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                (otherUser?['name'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: ModernTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser?['name'] ?? 'Unknown User',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (item != null)
                    Text(
                      item['title'] ?? 'Unknown Item',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showItemInfo(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Item Info Bar
          if (item != null) _buildItemInfoBar(item),
          
          // Messages List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ChatService.getMessagesStream(widget.chat['id']),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading messages...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading messages',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}), // Trigger rebuild
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                final messages = snapshot.data ?? [];
                
                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients && messages.isNotEmpty) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                
                if (messages.isEmpty) {
                  return _buildEmptyMessages();
                }
                
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(ModernTheme.spacing16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(messages[index], currentUserId);
                    },
                  ),
                );
              },
            ),
          ),
          
          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildItemInfoBar(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacing12),
      decoration: BoxDecoration(
        color: ModernTheme.primaryBlue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: ModernTheme.primaryBlue.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          ItemImage(
            imageUrl: (item['images'] as List?)?.isNotEmpty == true 
                ? item['images'][0] 
                : '',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'Unknown Item',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '₹${item['price']?.toString() ?? '0'}',
                  style: TextStyle(
                    color: ModernTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showItemInfo(),
            child: const Text('View Item'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, String? currentUserId) {
    final isMyMessage = message['sender_id'] == currentUserId;
    final sender = message['sender'];
    final content = message['message'] ?? message['content'] ?? '';
    final timestamp = message['created_at'];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: ModernTheme.spacing8),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: ModernTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                (sender?['name'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(
                  color: ModernTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: ModernTheme.spacing16,
                vertical: ModernTheme.spacing12,
              ),
              decoration: BoxDecoration(
                color: isMyMessage 
                    ? ModernTheme.primaryBlue 
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(ModernTheme.radiusL),
                  topRight: const Radius.circular(ModernTheme.radiusL),
                  bottomLeft: Radius.circular(isMyMessage ? ModernTheme.radiusL : ModernTheme.radiusS),
                  bottomRight: Radius.circular(isMyMessage ? ModernTheme.radiusS : ModernTheme.radiusL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: TextStyle(
                      color: isMyMessage ? Colors.white : null,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(timestamp),
                    style: TextStyle(
                      color: isMyMessage 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: ModernTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                (Provider.of<SupabaseAuthProvider>(context, listen: false).displayName)[0].toUpperCase(),
                style: TextStyle(
                  color: ModernTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyMessages() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ModernTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: ModernTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: ModernTheme.spacing16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ModernTheme.spacing8),
          Text(
            'Start the conversation!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.only(
        left: ModernTheme.spacing16,
        right: ModernTheme.spacing16,
        top: ModernTheme.spacing12,
        bottom: MediaQuery.of(context).padding.bottom + ModernTheme.spacing12,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ModernTheme.radiusXXL),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode 
                    ? ModernTheme.cardDark 
                    : Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ModernTheme.spacing16,
                  vertical: ModernTheme.spacing12,
                ),
              ),
            ),
          ),
          const SizedBox(width: ModernTheme.spacing8),
          Container(
            decoration: BoxDecoration(
              color: ModernTheme.primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ModernTheme.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      color: Colors.white,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    final messageToSend = content;
    _messageController.clear();

    try {
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🗨️ Attempting to send message: $messageToSend');
      debugPrint('🗨️ Chat ID: ${widget.chat['id']}');
      debugPrint('🗨️ Sender ID: $userId');

      final isBuyer = widget.chat['buyer_id'] == userId;
      
      final success = await ChatService.sendMessage(
        chatId: widget.chat['id'],
        senderId: userId,
        message: messageToSend,
        isBuyer: isBuyer,
      );

      if (success) {
        debugPrint('✅ Message sent successfully');
        // Auto-scroll to bottom after sending
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        throw Exception('Failed to send message - service returned false');
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      
      // Restore the message to the text field
      _messageController.text = messageToSend;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Failed to send message. Please try again.')),
            ],
          ),
          backgroundColor: ModernTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _sendMessage(),
          ),
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  String _formatMessageTime(String? timeString) {
    if (timeString == null) return '';
    
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      
      if (now.difference(time).inDays == 0) {
        // Same day - show time
        return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
      } else {
        // Different day - show date
        return '${time.day}/${time.month}';
      }
    } catch (e) {
      return '';
    }
  }

  void _showItemInfo() {
    final item = widget.chat['items'];
    if (item == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
        ),
        title: const Text('Item Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ItemImage(
              imageUrl: (item['images'] as List?)?.isNotEmpty == true 
                  ? item['images'][0] 
                  : '',
              width: double.infinity,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              item['title'] ?? 'Unknown Item',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${item['price']?.toString() ?? '0'}',
              style: TextStyle(
                color: ModernTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to item detail
            },
            child: const Text('View Full Details'),
          ),
        ],
      ),
    );
  }
}