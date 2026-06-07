import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_outlined,     activeIcon: Icons.dashboard,          label: 'Dashboard',  path: '/dashboard'),
    (icon: Icons.search_outlined,        activeIcon: Icons.search,             label: 'Screener',   path: '/screener'),
    (icon: Icons.bookmark_border,        activeIcon: Icons.bookmark,           label: 'Watchlist',  path: '/watchlist'),
    (icon: Icons.notifications_outlined, activeIcon: Icons.notifications,      label: 'Alerts',     path: '/alerts'),
    (icon: Icons.bar_chart_outlined,     activeIcon: Icons.bar_chart,          label: 'Backtest',   path: '/backtest'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => t.path == location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF3B82F6).withOpacity(0.2),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs.map((t) => NavigationDestination(
          icon:         Icon(t.icon,       color: const Color(0xFF94A3B8)),
          selectedIcon: Icon(t.activeIcon, color: const Color(0xFF3B82F6)),
          label:        t.label,
        )).toList(),
      ),
    );
  }
}
