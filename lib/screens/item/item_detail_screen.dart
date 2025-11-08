import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/image_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/cached_network_image.dart';
import '../../widgets/image_lightbox.dart';
import '../chat/chat_detail_screen.dart';
import 'edit_item_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLoading = false;
  bool _isFavorite = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: ModernTheme.animationNormal,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
    _incrementViews();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _incrementViews() async {
    try {
      await SupabaseConfig.client
          .from('items')
          .update({'views': (widget.item['views'] ?? 0) + 1})
          .eq('id', widget.item['id']);
    } catch (e) {
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final images = List<String>.from(widget.item['images'] ?? []);
    
    return Scaffold(
      backgroundColor: isDarkMode ? ModernTheme.backgroundDark : ModernTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? ModernTheme.errorRed : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () => _shareItem(),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      ModernTheme.primaryBlue.withOpacity(0.1),
                      ModernTheme.primaryPurple.withOpacity(0.1),
                    ],
                  ),
                ),
                child: images.isNotEmpty
                    ? PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          debugPrint('🖼️ Item detail image URL: ${images[index]}');
                          return GestureDetector(
                            onTap: () => _openImageLightbox(images, index),
                            child: CachedNetworkImage(
                              imageUrl: images[index],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      )
                    : GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No images available')),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: '',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(ModernTheme.radiusXXL),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image indicators
                      if (images.length > 1)
                        Container(
                          padding: const EdgeInsets.all(ModernTheme.spacing16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: images.asMap().entries.map((entry) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == entry.key
                                      ? ModernTheme.primaryBlue
                                      : Colors.grey.withOpacity(0.3),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.all(ModernTheme.spacing20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price and Title
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '₹${widget.item['price']?.toString() ?? '0'}',
                                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: ModernTheme.primaryBlue,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: ModernTheme.spacing8),
                                      Text(
                                        widget.item['title'] ?? 'No Title',
                                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ModernTheme.spacing12,
                                    vertical: ModernTheme.spacing6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getConditionColor().withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(ModernTheme.radiusXXL),
                                    border: Border.all(
                                      color: _getConditionColor().withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    _getConditionText(widget.item['condition']),
                                    style: TextStyle(
                                      color: _getConditionColor(),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: ModernTheme.spacing20),
                            
                            // Category and Views
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ModernTheme.spacing12,
                                    vertical: ModernTheme.spacing6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ModernTheme.primaryPurple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(ModernTheme.radiusM),
                                  ),
                                  child: Text(
                                    _getCategoryText(widget.item['category']),
                                    style: TextStyle(
                                      color: ModernTheme.primaryPurple,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: isDarkMode ? ModernTheme.textSecondaryDark : ModernTheme.textSecondaryLight,
                                ),
                                const SizedBox(width: ModernTheme.spacing4),
                                Text(
                                  '${widget.item['views'] ?? 0} views',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: ModernTheme.spacing24),
                            
                            // Description
                            Text(
                              'Description',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: ModernTheme.spacing12),
                            Text(
                              widget.item['description'] ?? 'No description available.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                              ),
                            ),
                            
                            const SizedBox(height: ModernTheme.spacing32),
                            
                            // Seller Info
                            Container(
                              padding: const EdgeInsets.all(ModernTheme.spacing16),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? ModernTheme.cardDark 
                                    : ModernTheme.cardLight,
                                borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                                border: Border.all(
                                  color: isDarkMode 
                                      ? ModernTheme.borderDark 
                                      : ModernTheme.borderLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Seller Information',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: ModernTheme.spacing12),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: ModernTheme.primaryBlue.withOpacity(0.1),
                                        child: Text(
                                          (widget.item['seller_name'] ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(
                                            color: ModernTheme.primaryBlue,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: ModernTheme.spacing12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              widget.item['seller_name'] ?? 'Unknown Seller',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'Active seller',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: ModernTheme.successGreen,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Chat functionality coming soon!')),
                                          );
                                        },
                                        icon: Icon(
                                          Icons.chat_bubble_outline,
                                          color: ModernTheme.primaryBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: ModernTheme.spacing32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          left: ModernTheme.spacing20,
          right: ModernTheme.spacing20,
          top: ModernTheme.spacing16,
          bottom: MediaQuery.of(context).padding.bottom + ModernTheme.spacing16,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Consumer<SupabaseAuthProvider>(
          builder: (context, authProvider, child) {
            final isOwnItem = authProvider.user?.id == widget.item['seller_id'];
            
            return Row(
              children: [
                if (!isOwnItem) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startChat(context),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: ModernTheme.spacing16),
                      ),
                    ),
                  ),
                  const SizedBox(width: ModernTheme.spacing12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () {
                        _showBuyDialog(context);
                      },
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.shopping_cart),
                      label: Text(_isLoading ? 'Processing...' : 'Buy Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: ModernTheme.spacing16),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => 
                                EditItemScreen(item: widget.item),
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
                        );
                        
                        // If item was updated, go back to refresh the list
                        if (result == true) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Item'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: ModernTheme.spacing16),
                      ),
                    ),
                  ),
                  const SizedBox(width: ModernTheme.spacing12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showDeleteDialog(context);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ModernTheme.errorRed,
                        padding: const EdgeInsets.symmetric(vertical: ModernTheme.spacing16),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getConditionColor() {
    switch (widget.item['condition']) {
      case 'new_item':
        return ModernTheme.successGreen;
      case 'likeNew':
        return ModernTheme.infoBlue;
      case 'good':
        return ModernTheme.primaryBlue;
      case 'fair':
        return ModernTheme.warningAmber;
      case 'poor':
        return ModernTheme.errorRed;
      default:
        return ModernTheme.primaryBlue;
    }
  }

  String _getConditionText(String? condition) {
    switch (condition) {
      case 'new_item':
        return 'Brand New';
      case 'likeNew':
        return 'Like New';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return 'Good';
    }
  }

  String _getCategoryText(String? category) {
    switch (category) {
      case 'electronics':
        return 'Electronics';
      case 'books':
        return 'Books';
      case 'clothing':
        return 'Clothing';
      case 'furniture':
        return 'Furniture';
      case 'sports':
        return 'Sports';
      case 'cycles':
        return 'Cycles';
      case 'essentials':
        return 'Essentials';
      case 'others':
        return 'Others';
      case 'other':
        return 'Other';
      default:
        return 'Other';
    }
  }

  void _showBuyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
        ),
        title: Row(
          children: [
            Icon(Icons.shopping_cart, color: ModernTheme.primaryBlue),
            const SizedBox(width: 8),
            const Text('Buy This Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This will start a chat with the seller to discuss the purchase.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ModernTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item['title'] ?? 'Unknown Item',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${widget.item['price']?.toString() ?? '0'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.primaryBlue,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _buyNowAction(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.primaryBlue,
            ),
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  Future<void> _buyNowAction(BuildContext context) async {
    final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please log in to buy items'),
            ],
          ),
          backgroundColor: ModernTheme.warningAmber,
        ),
      );
      return;
    }
    
    // Check if user is trying to buy their own item
    if (userId == widget.item['seller_id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('You cannot buy your own item'),
            ],
          ),
          backgroundColor: ModernTheme.infoBlue,
        ),
      );
      return;
    }
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      // Create or get chat
      final chatId = await ChatService.createOrGetChat(
        itemId: widget.item['id'].toString(),
        buyerId: userId,
        sellerId: widget.item['seller_id'],
        itemTitle: widget.item['title'] ?? 'Unknown Item',
      );
      
      if (chatId == null) {
        throw Exception('Failed to create chat');
      }
      
      // Send automatic "Buy Now" message
      final itemTitle = widget.item['title'] ?? 'this item';
      final itemPrice = widget.item['price']?.toString() ?? '0';
      final autoMessage = "Hi! I'm interested in buying your product '$itemTitle' (₹$itemPrice). Let's discuss where to meet.";
      
      final messageSent = await ChatService.sendMessage(
        chatId: chatId,
        senderId: userId,
        message: autoMessage,
        isBuyer: true,
      );
      
      Navigator.pop(context); // Close loading dialog
      
      if (messageSent) {
        // Create chat object for navigation
        final chatData = {
          'id': chatId,
          'item_id': widget.item['id'],
          'buyer_id': userId,
          'seller_id': widget.item['seller_id'],
          'item_title': widget.item['title'],
          'items': widget.item,
          'buyer': {
            'id': userId,
            'name': authProvider.displayName,
            'email': authProvider.user?.email,
          },
          'seller': {
            'id': widget.item['seller_id'],
            'name': widget.item['seller_name'],
            'email': widget.item['seller_email'],
          },
        };
        
        // Navigate to chat
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                ChatDetailScreen(chat: chatData),
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
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Chat started with seller!'),
              ],
            ),
            backgroundColor: ModernTheme.successGreen,
          ),
        );
      } else {
        throw Exception('Failed to send initial message');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error starting chat: $e')),
            ],
          ),
          backgroundColor: ModernTheme.errorRed,
        ),
      );
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
                final userId = authProvider.user?.id;
                
                if (userId == null) {
                  throw Exception('User not authenticated');
                }

                // Verify user owns this item
                if (widget.item['seller_id'] != userId) {
                  throw Exception('You can only delete your own items');
                }

                // Delete associated images first
                final images = List<String>.from(widget.item['images'] ?? []);
                if (images.isNotEmpty) {
                  await ImageService.deleteImages(images);
                }
                
                // Delete the item from database using proper RLS-compliant method
                await SupabaseConfig.client
                    .from('items')
                    .delete()
                    .eq('id', widget.item['id'])
                    .eq('seller_id', userId); // Ensure RLS compliance
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Item deleted successfully'),
                      ],
                    ),
                    backgroundColor: ModernTheme.successGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Error deleting item: $e')),
                      ],
                    ),
                    backgroundColor: ModernTheme.errorRed,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ModernTheme.radiusL),
                    ),
                  ),
                );
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: ModernTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _startChat(BuildContext context) async {
    final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Please log in to start a chat'),
            ],
          ),
          backgroundColor: ModernTheme.warningAmber,
        ),
      );
      return;
    }
    
    // Check if user is trying to chat with themselves
    if (userId == widget.item['seller_id']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('You cannot chat with yourself'),
            ],
          ),
          backgroundColor: ModernTheme.infoBlue,
        ),
      );
      return;
    }
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final chatId = await ChatService.createOrGetChat(
        itemId: widget.item['id'].toString(),
        buyerId: userId,
        sellerId: widget.item['seller_id'],
        itemTitle: widget.item['title'] ?? 'Unknown Item',
      );
      
      Navigator.pop(context); // Close loading dialog
      
      if (chatId != null) {
        // Create chat object for navigation
        final chatData = {
          'id': chatId,
          'item_id': widget.item['id'],
          'buyer_id': userId,
          'seller_id': widget.item['seller_id'],
          'item_title': widget.item['title'],
          'items': widget.item,
          'buyer': {
            'id': userId,
            'name': authProvider.displayName,
            'email': authProvider.user?.email,
          },
          'seller': {
            'id': widget.item['seller_id'],
            'name': widget.item['seller_name'],
            'email': widget.item['seller_email'],
          },
        };
        
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                ChatDetailScreen(chat: chatData),
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
        );
      } else {
        throw Exception('Failed to create chat');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error starting chat: $e')),
            ],
          ),
          backgroundColor: ModernTheme.errorRed,
        ),
      );
    }
  }

  void _openImageLightbox(List<String> images, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            ImageLightbox(
              imageUrls: images,
              initialIndex: initialIndex,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
        opaque: false,
      ),
    );
  }

  void _shareItem() {
    final title = widget.item['title'] ?? 'Unknown Item';
    final price = widget.item['price']?.toString() ?? '0';
    final description = widget.item['description'] ?? '';
    final images = List<String>.from(widget.item['images'] ?? []);
    
    String shareText = '''
🛍️ Check out this item on MarketISM!

📦 ${title}
💰 ₹${price}

${description.isNotEmpty ? '📝 ${description}\n' : ''}
🏫 Available at IIT ISM Campus

#MarketISM #IITISM #CampusMarketplace
''';

    if (images.isNotEmpty) {
      shareText += '\n🖼️ Image: ${images[0]}';
    }

    Share.share(
      shareText,
      subject: 'Check out this item on MarketISM - $title',
    );
  }
}