import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dueit/shared/widgets/app_bottom_nav_bar.dart';
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

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: RouteNames.splash,
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

    // Login
    GoRoute(
      path: RouteNames.login,
      builder: (context, state) => const LoginScreen(),
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
