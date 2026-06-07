import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/screener/screener_screen.dart';
import '../screens/stock_detail/stock_detail_screen.dart';
import '../screens/watchlist/watchlist_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/backtest/backtest_screen.dart';
import '../screens/shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn  = authState.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
                          state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn  && isAuthRoute)  return '/dashboard';
      return null;
    },
    routes: [
      // Auth
      GoRoute(path: '/login',    builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),

      // App shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
          GoRoute(path: '/screener',  builder: (c, s) => const ScreenerScreen()),
          GoRoute(path: '/watchlist', builder: (c, s) => const WatchlistScreen()),
          GoRoute(path: '/alerts',    builder: (c, s) => const AlertsScreen()),
          GoRoute(path: '/backtest',  builder: (c, s) => const BacktestScreen()),
        ],
      ),

      // Stock detail — accessed from multiple tabs
      GoRoute(
        path: '/stocks/:symbol',
        builder: (c, s) => StockDetailScreen(symbol: s.pathParameters['symbol']!),
      ),
    ],
  );
});
