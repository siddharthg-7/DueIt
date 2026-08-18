import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/app.dart';

void main() {
  testWidgets('Splash screen brand presence test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: DueItApp(),
      ),
    );

    // Initial frame verify
    expect(find.text('DueIt'), findsOneWidget);

    // Fast-forward past all timers to settle
    await tester.pump(const Duration(seconds: 3));
  });
}
