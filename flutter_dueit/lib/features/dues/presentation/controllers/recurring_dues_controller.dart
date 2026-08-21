import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import 'package:dueit/features/auth/presentation/controllers/auth_controller.dart';
import 'package:dueit/features/reminders/data/services/local_notification_service.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/recurring_due_schedule_entity.dart';
import '../../domain/repositories/dues_repository.dart';
import '../../domain/repositories/recurring_due_repository.dart';
import '../../domain/services/recurrence_calculator.dart';
import '../../domain/services/recurring_due_generation_service.dart';
import 'dues_controller.dart';

/// State for the Recurring Dues feature
class RecurringDuesState {
  final List<RecurringDueScheduleEntity> schedules;
  final bool isLoading;
  final String? error;

  const RecurringDuesState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
  });

  RecurringDuesState copyWith({
    List<RecurringDueScheduleEntity>? schedules,
    bool? isLoading,
    String? error,
  }) {
    return RecurringDuesState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<RecurringDueScheduleEntity> get activeSchedules =>
      schedules.where((s) => s.isActive).toList();

  List<RecurringDueScheduleEntity> get pausedSchedules =>
      schedules.where((s) => s.isPaused).toList();

  List<RecurringDueScheduleEntity> get endedSchedules =>
      schedules.where((s) => s.isEnded).toList();
}

/// Global provider for RecurringDueGenerationService
final recurringDueGenerationServiceProvider =
    Provider<RecurringDueGenerationService>((ref) {
  final duesRepo = ref.watch(duesRepositoryProvider);
  final recurringRepo = ref.watch(recurringDueRepositoryProvider);
  final notifService = ref.watch(notificationServiceProvider);

  return RecurringDueGenerationService(
    duesRepository: duesRepo,
    recurringRepository: recurringRepo,
    notificationService: notifService,
  );
});

/// StateNotifier for managing Recurring Dues
class RecurringDuesController extends StateNotifier<RecurringDuesState> {
  final RecurringDueRepository _repository;
  final DuesRepository _duesRepository;
  final NotificationService _notificationService;
  final RecurringDueGenerationService _generationService;
  final Ref _ref;
  StreamSubscription<List<RecurringDueScheduleEntity>>? _subscription;

  RecurringDuesController({
    required RecurringDueRepository repository,
    required DuesRepository duesRepository,
    required NotificationService notificationService,
    required RecurringDueGenerationService generationService,
    required Ref ref,
  })  : _repository = repository,
        _duesRepository = duesRepository,
        _notificationService = notificationService,
        _generationService = generationService,
        _ref = ref,
        super(const RecurringDuesState()) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        final currentUid = next.user?.id;
        final previousUid = previous?.user?.id;

        if (currentUid != previousUid) {
          if (currentUid != null && currentUid.isNotEmpty) {
            _subscribeToSchedules(currentUid);
          } else {
            _unsubscribe();
          }
        }
      },
      fireImmediately: true,
    );
  }

  void _subscribeToSchedules(String ownerId) {
    _subscription?.cancel();
    state = state.copyWith(isLoading: true, error: null);

    _subscription = _repository.watchSchedules(ownerId).listen(
      (schedules) async {
        state = state.copyWith(
          schedules: schedules,
          isLoading: false,
          error: null,
        );

        // Run catch-up generation for any active schedules due today or earlier
        if (schedules.any((s) => s.isActive)) {
          await _generationService.generatePendingDues(
            ownerId: ownerId,
            schedules: schedules,
          );
        }
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          error: err.toString(),
        );
      },
    );
  }

  void _unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    state = const RecurringDuesState();
  }

  String get _currentUserId {
    return _ref.read(authControllerProvider).user?.id ?? '';
  }

  /// Creates a new Recurring Schedule, generates its initial Due, and schedules its reminder.
  Future<RecurringDueScheduleEntity?> createSchedule({
    required String customerId,
    required String customerName,
    required double amount,
    required String description,
    required RecurrenceFrequency frequency,
    required int dayOfMonth,
    int? dayOfWeek,
    required String startDate,
    String? endDate,
    ReminderType reminderType = ReminderType.oneDayBefore,
    bool reminderEnabled = true,
  }) async {
    final ownerId = _currentUserId;
    if (ownerId.isEmpty) {
      state = state.copyWith(error: 'User not authenticated.');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final scheduleId = 'rec_${DateTime.now().millisecondsSinceEpoch}';
      final effectiveDayOfWeek =
          dayOfWeek ?? DateFormatter.parseLocalDate(startDate).weekday;

      // 1. Calculate nextDueDate for the following period
      final nextOccurrenceDate = RecurrenceCalculator.calculateNextDueDate(
        currentDueDateStr: startDate,
        frequency: frequency,
        originalDayOfMonth: dayOfMonth,
        dayOfWeek: effectiveDayOfWeek,
      );

      final schedule = RecurringDueScheduleEntity(
        id: scheduleId,
        ownerId: ownerId,
        businessId: ownerId,
        customerId: customerId,
        customerName: customerName,
        amount: amount,
        description: description,
        frequency: frequency,
        dayOfMonth: dayOfMonth,
        dayOfWeek: effectiveDayOfWeek,
        startDate: startDate,
        endDate: endDate,
        status: RecurringScheduleStatus.active,
        nextDueDate: nextOccurrenceDate,
        reminderType: reminderType,
        reminderEnabled: reminderEnabled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save schedule
      await _repository.createSchedule(ownerId, schedule);

      // 2. Generate initial Due for startDate
      final initialDueId = RecurrenceCalculator.generateOccurrenceDueId(
        scheduleId,
        startDate,
      );

      final initialDue = DueEntity(
        id: initialDueId,
        ownerId: ownerId,
        businessId: ownerId,
        customerId: customerId,
        customerName: customerName,
        amount: amount,
        paidAmount: 0.0,
        description: description,
        dueDate: startDate,
        status: DueEntity.deriveStatus(dueDate: startDate),
        reminderType: reminderType,
        reminderEnabled: reminderEnabled,
        recurrence: RecurrenceType.none,
        recurringScheduleId: scheduleId,
        occurrenceDate: startDate,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _duesRepository.createDue(initialDue);

      // 3. Schedule notification for initial due
      if (reminderEnabled && reminderType != ReminderType.none) {
        await _notificationService.scheduleDueReminder(
          initialDue,
          customerName: customerName,
        );
      }

      state = state.copyWith(isLoading: false);
      return schedule;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Updates an existing Recurring Schedule (future dues use the new values, historical dues stay preserved)
  Future<bool> updateSchedule(RecurringDueScheduleEntity schedule) async {
    final ownerId = _currentUserId;
    if (ownerId.isEmpty) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.updateSchedule(ownerId, schedule);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Pauses a recurring schedule
  Future<bool> pauseSchedule(String scheduleId) async {
    final ownerId = _currentUserId;
    if (ownerId.isEmpty) return false;

    try {
      await _repository.pauseSchedule(ownerId, scheduleId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Resumes a paused recurring schedule and catches up any pending dues
  Future<bool> resumeSchedule(String scheduleId) async {
    final ownerId = _currentUserId;
    if (ownerId.isEmpty) return false;

    try {
      await _repository.resumeSchedule(ownerId, scheduleId);
      // Run generation for the resumed schedule
      await _generationService.generatePendingDues(ownerId: ownerId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Stops / Ends a recurring schedule permanently
  Future<bool> stopSchedule(String scheduleId) async {
    final ownerId = _currentUserId;
    if (ownerId.isEmpty) return false;

    try {
      await _repository.stopSchedule(ownerId, scheduleId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Deletes a recurring schedule
  Future<bool> deleteSchedule(String scheduleId) async {
    final ownerId = _currentUserId;
    if (ownerId.isEmpty) return false;

    try {
      await _repository.deleteSchedule(ownerId, scheduleId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Manually triggers pending due generation (e.g. on screen refresh)
  Future<int> triggerGeneration() async {
    final ownerId = _currentUserId;
    if (ownerId.isEmpty) return 0;
    return await _generationService.generatePendingDues(ownerId: ownerId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Global provider for RecurringDuesController
final recurringDuesControllerProvider =
    StateNotifierProvider<RecurringDuesController, RecurringDuesState>((ref) {
  final repository = ref.watch(recurringDueRepositoryProvider);
  final duesRepository = ref.watch(duesRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final generationService = ref.watch(recurringDueGenerationServiceProvider);

  return RecurringDuesController(
    repository: repository,
    duesRepository: duesRepository,
    notificationService: notificationService,
    generationService: generationService,
    ref: ref,
  );
});
