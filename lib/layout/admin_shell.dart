import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_providers.dart';
import '../features/auth/access_denied_page.dart';
import 'app_navigation.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  bool _signedOutForAccess = false;
  bool _checkingAccess = true;
  bool _isAdmin = false;
  String? _accessError;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isAdmin = false;
          _checkingAccess = false;
        });
        return;
      }

      final data = await ref
          .read(adminFirestoreServiceProvider)
          .getDoc('users', user.uid)
          .timeout(const Duration(seconds: 15));
      final isAdmin = data?['role'] == 'admin';
      if (!isAdmin && !_signedOutForAccess) {
        _signedOutForAccess = true;
        await authService.signOut();
      }
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _checkingAccess = false;
        _accessError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _accessError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_accessError != null) {
      return Scaffold(
        body: Center(child: Text('Failed to load admin access: $_accessError')),
      );
    }
    if (!_isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go('/access-denied');
        }
      });
      return const AccessDeniedPage();
    }
    return _AdminScaffold(child: widget.child);
  }
}

class _AdminScaffold extends ConsumerWidget {
  const _AdminScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final title = navTitleForLocation(location);
    final selectedIndex = navIndexForLocation(location);
    final isCompact = MediaQuery.of(context).size.width < 980;
    final authService = ref.watch(authServiceProvider);
    final userEmail = authService.currentUser?.email ?? 'Unknown user';

    final drawer = Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Swarnakar Admin',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(userEmail, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          for (final item in adminNavItems)
            ListTile(
              leading: Icon(item.icon),
              title: Text(item.label),
              selected: item.route == adminNavItems[selectedIndex].route,
              onTap: () {
                Navigator.of(context).pop();
                context.go(item.route);
              },
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              Navigator.of(context).pop();
              await authService.signOut();
            },
          ),
        ],
      ),
    );

    final rail = NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) {
        context.go(adminNavItems[index].route);
      },
      destinations: [
        for (final item in adminNavItems)
          NavigationRailDestination(
            icon: Icon(item.icon),
            label: Text(item.label),
          ),
      ],
      labelType: NavigationRailLabelType.all,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(userEmail)),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async => authService.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: isCompact ? drawer : null,
      body: SafeArea(
        child: Row(
          children: [
            if (!isCompact)
              Container(
                width: 260,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: rail,
              ),
            Expanded(
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ],
        ),
      ),
    );
  }
}
