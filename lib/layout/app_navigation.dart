import 'package:flutter/material.dart';

class NavItem {
  const NavItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

const List<NavItem> adminNavItems = [
  NavItem(label: 'Dashboard', route: '/', icon: Icons.dashboard_outlined),
  NavItem(label: 'Prices', route: '/prices', icon: Icons.price_change_outlined),
  NavItem(
    label: 'Calculator Presets',
    route: '/calculator-presets',
    icon: Icons.calculate_outlined,
  ),
  NavItem(label: 'Users', route: '/users', icon: Icons.people_outline),
  NavItem(
    label: 'Subscriptions',
    route: '/subscriptions',
    icon: Icons.subscriptions_outlined,
  ),
  NavItem(label: 'Zakat', route: '/zakat', icon: Icons.balance_outlined),
  NavItem(label: 'Settings', route: '/settings', icon: Icons.settings_outlined),
  NavItem(label: 'Reports', route: '/reports', icon: Icons.receipt_long_outlined),
  NavItem(
    label: 'Change Password',
    route: '/change-password',
    icon: Icons.lock_outline,
  ),
];

int navIndexForLocation(String location) {
  for (var i = 0; i < adminNavItems.length; i++) {
    final item = adminNavItems[i];
    if (item.route == '/') {
      if (location == '/') {
        return i;
      }
      continue;
    }
    if (location.startsWith(item.route)) {
      return i;
    }
  }
  return 0;
}

String navTitleForLocation(String location) {
  final index = navIndexForLocation(location);
  return adminNavItems[index].label;
}
