import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import '../../domain/services/reminder_calculator.dart';

/// Abstract Notification Service contract allowing clean testability and mocking.
abstract class NotificationService {
  Future<void> initialize({void Function(String? payload)? onNotificationTap});
  Future<bool> requestPermissions();
  Future<bool> scheduleDueReminder(DueEntity due, {String? customerName});
  Future<void> cancelReminderForDue(String dueId);
  Future<void> cancelAllReminders();
  Future<List<PendingNotificationRequest>> getPendingNotifications();
}

/// Production implementation of NotificationService using flutter_local_notifications
class LocalNotificationServiceImpl implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;
  void Function(String? payload)? _onNotificationTap;

  LocalNotificationServiceImpl({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'payment_reminders';
  static const String channelName = 'Payment Reminders';
  static const String channelDesc =
      'Timely reminders for upcoming and due customer payments.';

  @override
  Future<void> initialize({
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (_isInitialized) {
      if (onNotificationTap != null) _onNotificationTap = onNotificationTap;
      return;
    }

    _onNotificationTap = onNotificationTap;

    // 1. Initialize timezone database for zoned scheduling
    try {
      tz.initializeTimeZones();
    } catch (e) {
      debugPrint('Timezone initialization notice: $e');
    }

    // 2. Android Initialization Settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS/Darwin Initialization Settings
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onNotificationTap?.call(payload);
        }
      },
    );

    // 4. Create Notification Channel on Android
    final androidNotificationPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      const channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDesc,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );
      await androidNotificationPlugin.createNotificationChannel(channel);
    }

    // 5. Check if app was launched via notification tap from terminated state
    try {
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse?.payload != null) {
        final payload = launchDetails.notificationResponse!.payload;
        if (payload != null && payload.isNotEmpty) {
          // Defer callback slightly to allow widget tree and router setup
          Future.microtask(() {
            _onNotificationTap?.call(payload);
          });
        }
      }
    } catch (e) {
      debugPrint('Error retrieving notification launch details: $e');
    }

    _isInitialized = true;
  }

  @override
  Future<bool> requestPermissions() async {
    // Android 13+ (API 33+) permission request
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final granted =
          await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS Darwin permission request
    final iosImplementation = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final granted = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  @override
  Future<bool> scheduleDueReminder(
    DueEntity due, {
    String? customerName,
  }) async {
    if (!due.reminderEnabled || due.reminderType == ReminderType.none) {
      await cancelReminderForDue(due.id);
      return false;
    }

    if (due.status == DueStatus.paid || due.status == DueStatus.cancelled) {
      await cancelReminderForDue(due.id);
      return false;
    }

    final scheduledDateTime = ReminderCalculator.calculateReminderDateTime(
      due.dueDate,
      due.reminderType,
    );

    if (scheduledDateTime == null) {
      await cancelReminderForDue(due.id);
      return false;
    }

    // Do NOT schedule notifications in the past
    if (ReminderCalculator.isPastReminder(scheduledDateTime)) {
      debugPrint(
        'Reminder datetime $scheduledDateTime is in the past for due ${due.id}. Skipping scheduling.',
      );
      await cancelReminderForDue(due.id);
      return false;
    }

    final notificationId = ReminderCalculator.generateNotificationId(due.id);
    final title = ReminderCalculator.buildNotificationTitle(
      dueDateStr: due.dueDate,
      reminderType: due.reminderType,
    );
    final resolvedCustomerName = customerName ??
        (due.customerName.isNotEmpty ? due.customerName : 'Client');
    final body = ReminderCalculator.buildNotificationBody(
      customerName: resolvedCustomerName,
      remainingAmount: due.remainingAmount,
      description: due.description,
    );

    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzDateTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: due.id,
      );

      debugPrint(
        'Successfully scheduled reminder for due ${due.id} at $tzDateTime (id: $notificationId)',
      );
      return true;
    } catch (e) {
      debugPrint('Exact scheduling fallback due to: $e');
      try {
        final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          tzDateTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: due.id,
        );
        return true;
      } catch (fallbackError) {
        debugPrint('Failed to schedule reminder notification: $fallbackError');
        return false;
      }
    }
  }

  @override
  Future<void> cancelReminderForDue(String dueId) async {
    final notificationId = ReminderCalculator.generateNotificationId(dueId);
    try {
      await _plugin.cancel(notificationId);
      debugPrint('Cancelled notification $notificationId for due $dueId');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  @override
  Future<void> cancelAllReminders() async {
    try {
      await _plugin.cancelAll();
      debugPrint('Cancelled all scheduled notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('Error fetching pending notifications: $e');
      return [];
    }
  }
}

/// Global Riverpod Provider for NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return LocalNotificationServiceImpl();
});
