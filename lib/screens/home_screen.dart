import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_providers.dart';
import '../providers/university_provider.dart';
import '../services/notification_service.dart';
import '../widgets/cozy_background.dart';
import 'chat_list.dart';
import 'favorites_screen.dart';
import 'filters_screen.dart';
import 'marketplace_screen.dart';
import 'match_feed.dart';
import 'profile_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabController;

  late final List<_NavItem> _tabs;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tabs = const [
      _NavItem(label: 'Home', icon: Icons.home_rounded, widget: MatchFeedScreen()),
      _NavItem(label: 'Filters', icon: Icons.tune_rounded, widget: FiltersScreen()),
      _NavItem(label: 'Market', icon: Icons.shopping_bag_outlined, widget: MarketplaceScreen()),
      _NavItem(label: 'Saved', icon: Icons.favorite_rounded, widget: FavoritesScreen()),
      _NavItem(label: 'Chat', icon: Icons.chat_bubble_rounded, widget: ChatListScreen()),
      _NavItem(label: 'Profile', icon: Icons.person_rounded, widget: ProfileViewScreen()),
    ];
    
    // Set up notification listeners for current user
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId != null) {
      NotificationService().setupRealtimeListeners(currentUserId);
    }
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sure'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final auth = ref.read(authServiceProvider);
      // Clear selected university so the next unauthenticated session
      // starts from the select-university screen again.
      ref.read(selectedUniversityProvider.notifier).state = null;
      await auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs[_currentIndex];
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(currentTab.label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmLogout,
            tooltip: 'Log out',
          ),
        ],
      ),
      body: CozyBackground(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(_currentIndex),
            child: _tabs[_currentIndex].widget,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _fabController.forward(from: 0);
        },
        backgroundColor: Colors.white,
        elevation: 3,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.icon, required this.widget});

  final String label;
  final IconData icon;
  final Widget widget;
}
