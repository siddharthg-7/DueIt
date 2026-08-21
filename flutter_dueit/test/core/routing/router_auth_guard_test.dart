import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/core/routing/app_router.dart';
import 'package:dueit/core/routing/route_names.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/domain/entities/business_profile.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('Router Auth Guard Unit Tests', () {
    test('1. Uninitialized state on splash remains on splash to finish loading',
        () {
      const authState = AuthState(isInitialized: false);
      final redirect = appRouteGuard(
        authState: authState,
        location: RouteNames.splash,
      );
      expect(redirect, isNull);
    });

    test('2. Initialized unauthenticated state on splash redirects to /welcome',
        () {
      const authState = AuthState(isInitialized: true, user: null);
      final redirect = appRouteGuard(
        authState: authState,
        location: RouteNames.splash,
      );
      expect(redirect, RouteNames.welcome);
    });

    test(
        '3. Unauthenticated user accessing protected route (/dashboard) redirects to /welcome',
        () {
      const authState = AuthState(isInitialized: true, user: null);
      final redirect = appRouteGuard(
        authState: authState,
        location: RouteNames.dashboard,
      );
      expect(redirect, RouteNames.welcome);
    });

    test(
        '4. Unauthenticated user accessing protected route (/settings) redirects to /welcome',
        () {
      const authState = AuthState(isInitialized: true, user: null);
      final redirect = appRouteGuard(
        authState: authState,
        location: RouteNames.settings,
      );
      expect(redirect, RouteNames.welcome);
    });

    test('5. Unauthenticated user on /login or /welcome is allowed', () {
      const authState = AuthState(isInitialized: true, user: null);

      expect(
        appRouteGuard(authState: authState, location: RouteNames.welcome),
        isNull,
      );
      expect(
        appRouteGuard(authState: authState, location: RouteNames.login),
        isNull,
      );
    });

    test(
        '6. Authenticated user without business profile is redirected to /business-setup',
        () {
      const user = UserEntity(
        id: 'u_new',
        email: 'new@dueit.com',
        isSetupComplete: false,
      );
      const authState = AuthState(isInitialized: true, user: user);

      // Accessing dashboard
      expect(
        appRouteGuard(authState: authState, location: RouteNames.dashboard),
        RouteNames.businessSetup,
      );

      // Accessing splash
      expect(
        appRouteGuard(authState: authState, location: RouteNames.splash),
        RouteNames.businessSetup,
      );

      // Accessing business setup itself is allowed
      expect(
        appRouteGuard(authState: authState, location: RouteNames.businessSetup),
        isNull,
      );
    });

    test(
        '7. Authenticated user with completed profile is guarded from auth screens',
        () {
      final profile = BusinessProfile(
        id: 'u_done',
        ownerId: 'u_done',
        businessName: 'Apex Karate Academy',
        businessType: 'Karate / Martial Arts',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final user = UserEntity(
        id: 'u_done',
        email: 'sensei@dueit.com',
        businessName: 'Apex Karate Academy',
        isSetupComplete: true,
        profile: profile,
      );
      final authState = AuthState(isInitialized: true, user: user);

      // Accessing login redirects to dashboard
      expect(
        appRouteGuard(authState: authState, location: RouteNames.login),
        RouteNames.dashboard,
      );

      // Accessing welcome redirects to dashboard
      expect(
        appRouteGuard(authState: authState, location: RouteNames.welcome),
        RouteNames.dashboard,
      );

      // Accessing business setup redirects to dashboard
      expect(
        appRouteGuard(authState: authState, location: RouteNames.businessSetup),
        RouteNames.dashboard,
      );

      // Accessing dashboard is allowed
      expect(
        appRouteGuard(authState: authState, location: RouteNames.dashboard),
        isNull,
      );
    });
  });
}
