import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supabase_auth_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/modern_theme.dart';
import '../screens/settings/supabase_settings_screen.dart';
import '../screens/item/supabase_post_item_screen.dart';
import '../screens/item/item_detail_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../models/item.dart';
import '../config/supabase_config.dart';
import '../widgets/cached_network_image.dart';
import '../services/notification_service.dart';

class MainScreenSupabase extends StatefulWidget {
  const MainScreenSupabase({super.key});

  @override
  State<MainScreenSupabase> createState() => _MainScreenSupabaseState();
}

class _MainScreenSupabaseState extends State<MainScreenSupabase> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SupabaseHomeTab(),
    SupabaseSearchTab(),
    SupabaseSellTab(),
    SupabaseChatTab(),
    SupabaseProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: ModernTheme.primaryBlue,
            unselectedItemColor: ModernTheme.secondaryTextColor,
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded), label: 'Sell'),
              BottomNavigationBarItem(icon: Icon(Icons.chat_rounded), label: 'Chat'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
            ],
          );
        },
      ),
    );
  }
}

// ---------------- HOME TAB ----------------
class SupabaseHomeTab extends StatelessWidget {
  const SupabaseHomeTab({super.key});

  Future<List<Map<String, dynamic>>> _loadRecentItems() async {
    try {
      final response = await SupabaseConfig.client
          .from('items')
          .select()
          .eq('status', 'available')
          .order('created_at', ascending: false)
          .limit(10);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading recent items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<SupabaseAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MarketISM'),
        backgroundColor: ModernTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Debug')),
                    body: const Center(child: Text('Debug screen removed')),
                  ),
                ),
              );
            },
          ),
          _buildNotificationBell(context, authProvider.user?.id),
        ],
      ),
      body: Container(
        color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[50],
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(authProvider),
              _buildQuickActions(context, themeProvider),
              _buildRecentItems(themeProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(SupabaseAuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ModernTheme.primaryBlue, ModernTheme.primaryPurple],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
          Text(authProvider.displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Find great deals from your campus community', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _quickActionCard(context, 'Browse Items', Icons.shopping_bag_rounded, ModernTheme.primaryBlue, () {
              final mainState = context.findAncestorStateOfType<_MainScreenSupabaseState>();
              mainState?._currentIndex = 1;
              mainState?.setState(() {});
            }, themeProvider.isDarkMode),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _quickActionCard(context, 'Sell Items', Icons.sell_rounded, ModernTheme.accentTeal, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SupabasePostItemScreen()));
            }, themeProvider.isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap, bool isDarkMode) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [Icon(icon, color: color, size: 32), const SizedBox(height: 8), Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600))],
        ),
      ),
    );
  }

  Widget _buildRecentItems(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadRecentItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          final items = snapshot.data ?? [];
          if (items.isEmpty) return SizedBox(height: 200, child: Center(child: Text('No items yet', style: TextStyle(color: Colors.grey[600]))));

          return SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) => _itemCard(context, items[index], themeProvider.isDarkMode),
            ),
          );
        },
      ),
    );
  }

  Widget _itemCard(BuildContext context, Map<String, dynamic> item, bool isDarkMode) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item))),
      child: Hero(
        tag: 'home-item-${item['id']}',
        child: Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? ModernTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ItemImage(imageUrl: (item['images'] as List?)?.first ?? '', width: double.infinity, height: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] ?? 'No Title', style: TextStyle(fontWeight: FontWeight.w600, color: isDarkMode ? ModernTheme.textPrimaryDark : Colors.black, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('₹${item['price'] ?? 0}', style: TextStyle(color: ModernTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(BuildContext context, String? userId) {
    if (userId == null) return IconButton(icon: const Icon(Icons.notifications_rounded), onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to view notifications'))));

    return FutureBuilder<int>(
      future: NotificationService.getUnreadMessageCount(userId),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return Stack(
          children: [
            IconButton(icon: const Icon(Icons.notifications_rounded), onPressed: () {}),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: ModernTheme.errorRed, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(unread > 99 ? '99+' : '$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              )
          ],
        );
      },
    );
  }
}

// ---------------- SEARCH TAB ----------------
class SupabaseSearchTab extends StatefulWidget {
  const SupabaseSearchTab({super.key});
  @override
  State<SupabaseSearchTab> createState() => _SupabaseSearchTabState();
}

class _SupabaseSearchTabState extends State<SupabaseSearchTab> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseConfig.client.from('items').select().eq('status', 'available').order('created_at', ascending: false);
      _items = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Search tab load items error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Items'), backgroundColor: ModernTheme.primaryBlue, foregroundColor: Colors.white),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => _items = _items.where((item) => (item['title']?.toLowerCase() ?? '').contains(value.toLowerCase())).toList());
              },
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: _items[index]))),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          children: [
                            Expanded(child: ItemImage(imageUrl: (_items[index]['images'] as List?)?.first ?? '', width: double.infinity, height: double.infinity)),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(_items[index]['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.w600)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                )
        ],
      ),
    );
  }
}

// ---------------- SELL TAB ----------------
class SupabaseSellTab extends StatelessWidget {
  const SupabaseSellTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sell'), backgroundColor: ModernTheme.primaryBlue, foregroundColor: Colors.white),
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupabasePostItemScreen())),
          child: const Text('Post Item'),
        ),
      ),
    );
  }
}

// ---------------- CHAT TAB ----------------
class SupabaseChatTab extends StatelessWidget {
  const SupabaseChatTab({super.key});
  @override
  Widget build(BuildContext context) => const ChatListScreen();
}

// ---------------- PROFILE TAB ----------------
class SupabaseProfileTab extends StatelessWidget {
  const SupabaseProfileTab({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<SupabaseAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: ModernTheme.primaryBlue, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 50, child: Text(authProvider.displayName.isNotEmpty ? authProvider.displayName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32))),
            const SizedBox(height: 16),
            Text(authProvider.displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(authProvider.user?.email ?? ''),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupabaseSettingsScreen())),
              child: const Text('Settings'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async => await authProvider.signOut(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
