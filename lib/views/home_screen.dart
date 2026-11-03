import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../viewmodels/notification_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import 'courts/court_list_page.dart';
import 'map/map_page.dart';
import 'chat/chat_list_page.dart';
import 'notification/notification_page.dart';
import 'profile/profile_page.dart';

/// HomeScreen với BottomNavigationBar 5 tabs
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _pages = [
    CourtListPage(),
    MapPage(),
    ChatListPage(),
    NotificationPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Load notifications sau khi user đã login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthViewModel>().currentUser;
      if (user != null) {
        context.read<NotificationViewModel>().loadNotifications(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<NotificationViewModel>(
        builder: (_, notifVm, __) => Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            elevation: 0,
            backgroundColor: AppColors.surface,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.primaryLight,
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Sân',
              ),
              const NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon:
                    Icon(Icons.map, color: AppColors.primary),
                label: 'Bản đồ',
              ),
              const NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                selectedIcon: Icon(Icons.chat_bubble,
                    color: AppColors.primary),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: _NotifIcon(unreadCount: notifVm.unreadCount),
                selectedIcon: _NotifIcon(
                    unreadCount: notifVm.unreadCount, selected: true),
                label: 'Thông báo',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon:
                    Icon(Icons.person, color: AppColors.primary),
                label: 'Hồ sơ',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifIcon extends StatelessWidget {
  final int unreadCount;
  final bool selected;
  const _NotifIcon({required this.unreadCount, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          selected
              ? Icons.notifications
              : Icons.notifications_outlined,
          color: selected ? AppColors.primary : null,
        ),
        if (unreadCount > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
