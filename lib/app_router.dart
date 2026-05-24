import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router_refresh.dart';
import 'layout/admin_shell.dart';
import 'providers/auth_providers.dart';
import 'features/auth/login_page.dart';
import 'features/auth/access_denied_page.dart';
import 'features/auth/change_password_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/prices/prices_page.dart';
import 'features/calculator_presets/calculator_presets_page.dart';
import 'features/users/users_page.dart';
import 'features/subscriptions/subscriptions_page.dart';
import 'features/zakat/zakat_page.dart';
import 'features/settings/settings_page.dart';
import 'features/reports/reports_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.read(authServiceProvider);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authService.authStateChanges()),
    redirect: (context, state) {
      final loggedIn = authService.currentUser != null;
      final location = state.uri.path;
      final isLogin = location == '/login';
      final isAccessDenied = location == '/access-denied';

      if (!loggedIn && !isLogin && !isAccessDenied) {
        return '/login';
      }
      if (loggedIn && isLogin) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/access-denied',
        builder: (context, state) => const AccessDeniedPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/prices',
            builder: (context, state) => const PricesPage(),
          ),
          GoRoute(
            path: '/calculator-presets',
            builder: (context, state) => const CalculatorPresetsPage(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionsPage(),
          ),
          GoRoute(
            path: '/zakat',
            builder: (context, state) => const ZakatPage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/change-password',
            builder: (context, state) => const ChangePasswordPage(),
          ),
        ],
      ),
    ],
  );
});
