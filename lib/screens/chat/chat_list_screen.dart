import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../config/supabase_config.dart';
import '../../widgets/cached_network_image.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _chats = [];
  bool _isLoading = true;
  
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
    _loadChats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load chats where user is either buyer or seller
      final response = await SupabaseConfig.client
          .from('chats')
          .select('''
            *,
            items:item_id (
              id,
              title,
              price,
              images
            ),
            buyer:buyer_id (
              id,
              name,
              email
            ),
            seller:seller_id (
              id,
              name,
              email
            )
          ''')
          .or('buyer_id.eq.$userId,seller_id.eq.$userId')
          .order('last_message_at', ascending: false);

      setState(() {
        _chats = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error loading chats: $e')),
            ],
          ),
          backgroundColor: ModernTheme.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode ? ModernTheme.backgroundDark : ModernTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your conversations...'),
                ],
              ),
            )
          : _chats.isEmpty
              ? _buildEmptyState()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadChats,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(ModernTheme.spacing8),
                      itemCount: _chats.length,
                      itemBuilder: (context, index) {
                        return _buildChatCard(_chats[index], index);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat, int index) {
    final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
    final currentUserId = authProvider.user?.id;
    
    // Determine the other user (not the current user)
    final isCurrentUserBuyer = chat['buyer_id'] == currentUserId;
    final otherUser = isCurrentUserBuyer ? chat['seller'] : chat['buyer'];
    final item = chat['items'];
    
    final otherUserName = otherUser?['name'] ?? 'Unknown User';
    final lastMessage = chat['last_message'] ?? 'No messages yet';
    final lastMessageTime = chat['last_message_at'];
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 150 + (index * 50)),
      margin: const EdgeInsets.only(bottom: ModernTheme.spacing8),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
        ),
        child: InkWell(
          onTap: () => _openChat(chat),
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(ModernTheme.spacing16),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ModernTheme.primaryBlue.withOpacity(0.1),
                  child: Text(
                    otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      color: ModernTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
                
                const SizedBox(width: ModernTheme.spacing16),
                
                // Chat Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Name and Item Info
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              otherUserName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTime(lastMessageTime),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Item Title
                      if (item != null)
                        Text(
                          'About: ${item['title'] ?? 'Unknown Item'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ModernTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 4),
                      
                      // Last Message
                      Text(
                        lastMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Item Image and Price
                if (item != null)
                  Column(
                    children: [
                      ItemImage(
                        imageUrl: (item['images'] as List?)?.isNotEmpty == true 
                            ? item['images'][0] 
                            : '',
                        width: 50,
                        height: 50,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${item['price']?.toString() ?? '0'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ModernTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ModernTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: ModernTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: ModernTheme.spacing24),
          Text(
            'No conversations yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ModernTheme.spacing8),
          Text(
            'Start chatting with sellers by tapping\nthe chat button on any item',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ModernTheme.spacing32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to browse items
              Navigator.pop(context);
            },
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Browse Items'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: ModernTheme.spacing24,
                vertical: ModernTheme.spacing16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null) return '';
    
    try {
      final time = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(time);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      return '';
    }
  }

  void _openChat(Map<String, dynamic> chat) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ChatDetailScreen(chat: chat),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        transitionDuration: ModernTheme.animationNormal,
      ),
    ).then((_) {
      // Refresh chats when returning from chat detail
      _loadChats();
    });
  }
}