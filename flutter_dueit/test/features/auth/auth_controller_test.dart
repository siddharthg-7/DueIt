import 'package:flutter_test/flutter_test.dart';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/domain/entities/business_profile.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import '../../mocks/fake_auth_repository.dart';

void main() {
  group('AuthController Tests', () {
    late FakeAuthRepository fakeRepo;
    late AuthController controller;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      controller = AuthController(fakeRepo);
    });

    tearDown(() {
      controller.dispose();
      fakeRepo.dispose();
    });

    test('1. Initial unauthenticated state is recognized', () {
      expect(controller.state.isAuthenticated, isFalse);
      expect(controller.state.isBusinessSetupComplete, isFalse);
      expect(controller.state.user, isNull);
    });

    test('2. Authenticated state with profile is recognized', () async {
      final profile = BusinessProfile(
        id: 'u1',
        ownerId: 'u1',
        businessName: 'Apex Karate',
        businessType: 'Karate / Martial Arts',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final repoWithUser = FakeAuthRepository(
        initialUser: UserEntity(
          id: 'u1',
          email: 'u1@test.com',
          businessName: 'Apex Karate',
          isSetupComplete: true,
          profile: profile,
        ),
        initialProfile: profile,
      );
      final ctrl = AuthController(repoWithUser);
      await ctrl.reloadUser();

      expect(ctrl.state.isAuthenticated, isTrue);
      expect(ctrl.state.isBusinessSetupComplete, isTrue);
      expect(ctrl.state.user?.email, 'u1@test.com');
      expect(ctrl.state.user?.businessName, 'Apex Karate');

      ctrl.dispose();
      repoWithUser.dispose();
    });

    test('3. Registration succeeds and sets uncompleted business setup state',
        () async {
      final success = await controller.signUp(
        email: 'newuser@dueit.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(controller.state.isAuthenticated, isTrue);
      expect(controller.state.isBusinessSetupComplete, isFalse);
      expect(controller.state.user?.email, 'newuser@dueit.com');
    });

    test(
        '4. Registration failure handles error gracefully with friendly message',
        () async {
      fakeRepo.shouldFailSignUp = true;
      final success = await controller.signUp(
        email: 'duplicate@dueit.com',
        password: 'password123',
      );

      expect(success, isFalse);
      expect(controller.state.isAuthenticated, isFalse);
      expect(
          controller.state.error, 'An account with this email already exists.');
    });

    test('5. Sign In succeeds and populates user state', () async {
      final success = await controller.signIn(
        'alex@karateacademy.com',
        'password123',
      );

      expect(success, isTrue);
      expect(controller.state.isAuthenticated, isTrue);
      expect(controller.state.user?.email, 'alex@karateacademy.com');
    });

    test('6. Sign In failure shows friendly error message', () async {
      fakeRepo.shouldFailSignIn = true;
      final success = await controller.signIn(
        'wrong@domain.com',
        'wrongpass',
      );

      expect(success, isFalse);
      expect(controller.state.isAuthenticated, isFalse);
      expect(controller.state.error, 'Email or password is incorrect.');
    });

    test('7. Password reset triggers repository and provides success message',
        () async {
      final success =
          await controller.sendPasswordResetEmail('reset@domain.com');

      expect(success, isTrue);
      expect(fakeRepo.lastResetEmailSent, 'reset@domain.com');
      expect(controller.state.successMessage, contains('sent instructions'));
    });

    test('8. Business setup saves profile and marks setup complete', () async {
      // First sign in
      await controller.signUp(
        email: 'sensei@dojo.com',
        password: 'password123',
      );

      // Now save business profile
      final saveSuccess = await controller.saveBusinessProfile(
        businessName: 'Cobra Kai Academy',
        businessType: 'Karate / Martial Arts',
        description: 'Strike First, Strike Hard, No Mercy',
      );

      expect(saveSuccess, isTrue);
      expect(controller.state.isBusinessSetupComplete, isTrue);
      expect(controller.state.user?.businessName, 'Cobra Kai Academy');
      expect(controller.state.user?.businessType, 'Karate / Martial Arts');
    });

    test('9. Business setup fails when user is unauthenticated', () async {
      final saveSuccess = await controller.saveBusinessProfile(
        businessName: 'Ghost Academy',
        businessType: 'Other',
      );

      expect(saveSuccess, isFalse);
      expect(controller.state.error, 'User is not authenticated.');
    });

    test('10. Logout clears authentication state', () async {
      await controller.signIn('user@test.com', 'password123');
      expect(controller.state.isAuthenticated, isTrue);

      await controller.signOut();
      expect(controller.state.isAuthenticated, isFalse);
      expect(controller.state.user, isNull);
    });
  });
}
