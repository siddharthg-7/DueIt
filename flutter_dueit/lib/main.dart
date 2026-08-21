import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/routing/app_router.dart';
import 'features/reminders/data/services/local_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // 2. Initialize Local Notifications Service
  final notificationService = LocalNotificationServiceImpl();
  try {
    await notificationService.initialize(
      onNotificationTap: (payload) {
        if (payload != null && payload.isNotEmpty) {
          final dueId =
              payload.startsWith('/due/') ? payload.substring(5) : payload;
          navigateToDue(dueId);
        }
      },
    );
  } catch (e) {
    debugPrint('Local notification initialization notice: $e');
  }

  // 3. Set preferred orientation to portrait for mobile UX
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 4. Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const DueItApp(),
    ),
  );
}
