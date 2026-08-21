import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/app.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'mocks/fake_auth_repository.dart';

void main() {
  testWidgets('Splash screen brand presence test', (WidgetTester tester) async {
    final fakeRepo = FakeAuthRepository();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const DueItApp(),
      ),
    );

    // Initial frame verify
    expect(find.text('DueIt'), findsWidgets);

    // Settle all animations
    await tester.pumpAndSettle();
  });
}
