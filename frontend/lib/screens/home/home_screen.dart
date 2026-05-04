import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/enrollment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/responsive.dart';
import '../dashboard/dashboard_screen.dart';
import '../support/support_screen.dart';
import '../notifications/notifications_screen.dart';
import '../calendar/calendar_screen.dart';
import '../more/more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Tabs that require login (by index)
  static const _authRequiredTabs = {1, 2, 3}; // Support, Alerts, Calendar

  final List<Widget> _pages = const [
    DashboardScreen(),
    SupportScreen(),
    NotificationsScreen(),
    CalendarScreen(),
    MoreScreen(),
  ];

  void _onTabTap(int index) {
    final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
    if (_authRequiredTabs.contains(index) && !isLoggedIn) {
      _showLoginPrompt();
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _showLoginPrompt() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.loginRequired),
        content: Text(l10n.pleaseSignIn),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamed(context, '/login');
            },
            child: Text(l10n.signIn),
          ),
        ],
      ),
    );
  }

  bool _socketListening = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CourseProvider>().fetchCourses(refresh: true);
      if (context.read<AuthProvider>().isLoggedIn) {
        context.read<EnrollmentProvider>().fetchEnrollments();
        if (!_socketListening) {
          _socketListening = true;
          context.read<NotificationProvider>().listenToSocket();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isTabletLayout = AppResponsive.isTablet(context);
    final body = IndexedStack(index: _currentIndex, children: _pages);

    final destinations = [
      _HomeTabDestination(label: l10n.dashboard, icon: Icons.home_outlined, activeIcon: Icons.home),
      _HomeTabDestination(label: 'Support', icon: Icons.support_agent, activeIcon: Icons.support_agent),
      _HomeTabDestination(label: l10n.alerts, icon: Icons.notifications_none, activeIcon: Icons.notifications),
      _HomeTabDestination(label: l10n.calendar, icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
      _HomeTabDestination(label: l10n.more, icon: Icons.more_horiz, activeIcon: Icons.more_horiz),
    ];

    if (isTabletLayout) {
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: _onTabTap,
                labelType: NavigationRailLabelType.all,
                useIndicator: true,
                indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                selectedIconTheme: const IconThemeData(size: 24),
                destinations: destinations
                    .asMap()
                    .entries
                    .map((e) {
                      final isLoggedIn = context.read<AuthProvider>().isLoggedIn;
                      final disabled = _authRequiredTabs.contains(e.key) && !isLoggedIn;
                      final color = disabled ? Colors.grey[400] : null;
                      return NavigationRailDestination(
                        icon: Icon(e.value.icon, color: color),
                        selectedIcon: Icon(e.value.activeIcon, color: color),
                        label: Text(e.value.label,
                            style: TextStyle(color: color)),
                      );
                    })
                    .toList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: Row(
              children: List.generate(destinations.length, (index) {
                final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
                final disabled = _authRequiredTabs.contains(index) && !isLoggedIn;
                return _NavItem(
                  icon: destinations[index].icon,
                  activeIcon: destinations[index].activeIcon,
                  isActive: _currentIndex == index,
                  disabled: disabled,
                  onTap: () => _onTabTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTabDestination {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _HomeTabDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final bool disabled;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? Colors.grey[400]
        : isActive
            ? AppTheme.primaryColor
            : Colors.grey[600];

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: color,
                  size: 26,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: 32,
                  decoration: BoxDecoration(
                    color: isActive && !disabled
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            // Lock badge for disabled tabs
            if (disabled)
              Positioned(
                top: 6,
                right: 12,
                child: Icon(Icons.lock, size: 10, color: Colors.grey[400]),
              ),
          ],
        ),
      ),
    );
  }
}
