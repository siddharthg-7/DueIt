import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/shared/widgets/app_bottom_nav_bar.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/auth/presentation/screens/splash_screen.dart';
import 'package:dueit/features/auth/presentation/screens/welcome_screen.dart';
import 'package:dueit/features/auth/presentation/screens/login_screen.dart';
import 'package:dueit/features/auth/presentation/screens/business_setup_screen.dart';
import 'package:dueit/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:dueit/features/customers/presentation/screens/customers_screen.dart';
import 'package:dueit/features/customers/presentation/screens/customer_details_screen.dart';
import 'package:dueit/features/dues/presentation/screens/dues_screen.dart';
import 'package:dueit/features/dues/presentation/screens/due_details_screen.dart';
import 'package:dueit/features/dues/presentation/screens/add_due_screen.dart';
import 'package:dueit/features/insights/presentation/screens/insights_screen.dart';
import 'package:dueit/features/reminders/presentation/screens/notifications_screen.dart';
import 'package:dueit/features/settings/presentation/screens/settings_screen.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Centralized route guard pure function evaluating redirect destination
String? appRouteGuard({
  required AuthState authState,
  required String location,
}) {
  // 1. If still loading initial auth status and on splash, let splash handle initialization
  if (!authState.isInitialized && location == RouteNames.splash) {
    return null;
  }

  final isAuthenticated = authState.isAuthenticated;
  final isSetupComplete = authState.isBusinessSetupComplete;

  final isSplash = location == RouteNames.splash;
  final isAuthRoute =
      location == RouteNames.welcome || location == RouteNames.login;
  final isBusinessSetupRoute = location == RouteNames.businessSetup;

  // 2. Splash resolution after initialization
  if (isSplash) {
    if (!isAuthenticated) return RouteNames.welcome;
    if (!isSetupComplete) return RouteNames.businessSetup;
    return RouteNames.dashboard;
  }

  // 3. Unauthenticated User attempting to access protected routes
  if (!isAuthenticated) {
    if (isAuthRoute) return null;
    return RouteNames.welcome;
  }

  // 4. Authenticated User without completed business profile
  if (isAuthenticated && !isSetupComplete) {
    if (isBusinessSetupRoute) return null;
    return RouteNames.businessSetup;
  }

  // 5. Authenticated User with completed business profile attempting to visit auth screens
  if (isAuthenticated && isSetupComplete) {
    if (isAuthRoute || isBusinessSetupRoute) {
      return RouteNames.dashboard;
    }
  }

  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authStateListenableProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      return appRouteGuard(
        authState: authState,
        location: state.matchedLocation,
      );
    },
    routes: [
      // Splash
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Welcome / Onboarding
      GoRoute(
        path: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Login / Create Account
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) {
          final isSignUpParam = state.uri.queryParameters['tab'] == 'register';
          return LoginScreen(initialIsSignUp: isSignUpParam);
        },
      ),

      // Business Setup
      GoRoute(
        path: RouteNames.businessSetup,
        builder: (context, state) => const BusinessSetupScreen(),
      ),

      // Stateful Navigation Shell for 4 Main Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: AppBottomNavBar(
              currentIndex: navigationShell.currentIndex,
              onIndexChanged: (index) {
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            ),
          );
        },
        branches: [
          // Tab 0: Home / Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),

          // Tab 1: Dues / History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.dues,
                builder: (context, state) => const DuesScreen(),
              ),
            ],
          ),

          // Tab 2: People / Clients
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.customers,
                builder: (context, state) => const CustomersScreen(),
              ),
            ],
          ),

          // Tab 3: Insights
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.insights,
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Standalone & Drilldown Sub-Routes
      GoRoute(
        path: RouteNames.customerDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return CustomerDetailsScreen(customerId: id);
        },
      ),
      GoRoute(
        path: RouteNames.dueDetails,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return DueDetailsScreen(dueId: id);
        },
      ),
      GoRoute(
        path: RouteNames.addDue,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final customerId = state.uri.queryParameters['customerId'];
          return AddDueScreen(preselectedCustomerId: customerId);
        },
      ),
      GoRoute(
        path: RouteNames.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
