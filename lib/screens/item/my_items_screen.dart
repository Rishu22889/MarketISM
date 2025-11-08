import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../theme/modern_theme.dart';
import '../../config/supabase_config.dart';
import '../../services/image_service.dart';
import '../../widgets/cached_network_image.dart';
import 'edit_item_screen.dart';
import 'item_detail_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _myItems = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  
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
    _loadMyItems();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMyItems() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var queryBuilder = SupabaseConfig.client
          .from('items')
          .select()
          .eq('seller_id', userId);

      // Apply filter
      if (_selectedFilter != 'all') {
        queryBuilder = queryBuilder.eq('status', _selectedFilter);
      } else {
        queryBuilder = queryBuilder.neq('status', 'deleted');
      }

      final response = await queryBuilder.order('created_at', ascending: false);
      setState(() {
        _myItems = List<Map<String, dynamic>>.from(response);
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
              Expanded(child: Text('Error loading items: $e')),
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
        title: const Text('My Items'),
        backgroundColor: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyItems,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(ModernTheme.spacing16),
            decoration: BoxDecoration(
              color: isDarkMode ? ModernTheme.surfaceDark : ModernTheme.surfaceLight,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _getItemCount('all')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Available', 'available', _getItemCount('available')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Sold', 'sold', _getItemCount('sold')),
                  const SizedBox(width: 8),
                  _buildFilterChip('Reserved', 'reserved', _getItemCount('reserved')),
                ],
              ),
            ),
          ),
          
          // Items List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading your items...'),
                      ],
                    ),
                  )
                : _myItems.isEmpty
                    ? _buildEmptyState()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: _loadMyItems,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(ModernTheme.spacing16),
                            itemCount: _myItems.length,
                            itemBuilder: (context, index) {
                              return _buildItemCard(_myItems[index], index);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _selectedFilter == value;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        _loadMyItems();
      },
      child: AnimatedContainer(
        duration: ModernTheme.animationFast,
        padding: const EdgeInsets.symmetric(
          horizontal: ModernTheme.spacing16,
          vertical: ModernTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? ModernTheme.primaryBlue 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(ModernTheme.radiusXXL),
          border: Border.all(
            color: isSelected 
                ? ModernTheme.primaryBlue 
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Colors.white.withOpacity(0.2) 
                      : ModernTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : ModernTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final status = item['status'] ?? 'available';
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 150 + (index * 50)),
      margin: const EdgeInsets.only(bottom: ModernTheme.spacing12),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => 
                    ItemDetailScreen(item: item),
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
          },
          borderRadius: BorderRadius.circular(ModernTheme.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(ModernTheme.spacing16),
            child: Row(
              children: [
                // Item Image with debugging
                Builder(
                  builder: (context) {
                    final imageUrl = (item['images'] as List?)?.isNotEmpty == true 
                        ? item['images'][0] 
                        : '';
                    debugPrint('🖼️ My items image URL: $imageUrl');
                    debugPrint('🖼️ My items raw images: ${item['images']}');
                    return ItemImage(
                      imageUrl: imageUrl,
                      width: 80,
                      height: 80,
                    );
                  },
                ),
                
                const SizedBox(width: ModernTheme.spacing16),
                
                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['title'] ?? 'No Title',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        '₹${item['price']?.toString() ?? '0'}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: ModernTheme.primaryBlue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item['views'] ?? 0} views',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(item['created_at']),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Action Buttons
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _editItem(item),
                      icon: Icon(
                        Icons.edit,
                        color: ModernTheme.primaryBlue,
                      ),
                      tooltip: 'Edit Item',
                    ),
                    IconButton(
                      onPressed: () => _showDeleteDialog(item),
                      icon: Icon(
                        Icons.delete_outline,
                        color: ModernTheme.errorRed,
                      ),
                      tooltip: 'Delete Item',
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'available':
        color = ModernTheme.successGreen;
        text = 'Available';
        break;
      case 'sold':
        color = ModernTheme.errorRed;
        text = 'Sold';
        break;
      case 'reserved':
        color = ModernTheme.warningAmber;
        text = 'Reserved';
        break;
      default:
        color = Colors.grey;
        text = 'Unknown';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ModernTheme.radiusS),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
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
              Icons.inventory_2_outlined,
              size: 60,
              color: ModernTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: ModernTheme.spacing24),
          Text(
            'No items found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: ModernTheme.spacing8),
          Text(
            _selectedFilter == 'all' 
                ? 'You haven\'t posted any items yet'
                : 'No ${_selectedFilter} items found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ModernTheme.spacing32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to post item screen
            },
            icon: const Icon(Icons.add),
            label: const Text('Post Your First Item'),
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

  int _getItemCount(String filter) {
    if (filter == 'all') {
      return _myItems.where((item) => item['status'] != 'deleted').length;
    }
    return _myItems.where((item) => item['status'] == filter).length;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> _editItem(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            EditItemScreen(item: item),
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
    
    // Refresh the list if item was updated
    if (result == true) {
      _loadMyItems();
    }
  }

  void _showDeleteDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.radiusXL),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: ModernTheme.errorRed),
            const SizedBox(width: 8),
            const Text('Delete Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this item?'),
            const SizedBox(height: 8),
            Text(
              'Item: ${item['title']}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteItem(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    try {
      final authProvider = Provider.of<SupabaseAuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Verify user owns this item
      if (item['seller_id'] != userId) {
        throw Exception('You can only delete your own items');
      }

      // Delete associated images first
      final images = List<String>.from(item['images'] ?? []);
      if (images.isNotEmpty) {
        await ImageService.deleteImages(images);
      }
      
      // Delete the item from database using proper RLS-compliant method
      final response = await SupabaseConfig.client
          .from('items')
          .delete()
          .eq('id', item['id'])
          .eq('seller_id', userId); // Ensure RLS compliance
      
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
      
      _loadMyItems(); // Refresh the list
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
    }
  }
}