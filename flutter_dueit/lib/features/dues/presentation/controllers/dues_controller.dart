import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dueit/core/utils/date_formatter.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../../domain/repositories/dues_repository.dart';
import '../../domain/services/due_payment_calculator.dart';
import '../../data/repositories/dues_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../reminders/data/services/local_notification_service.dart';

final duesRepositoryProvider = Provider<DuesRepository>((ref) {
  return DuesRepositoryImpl();
});

class DuesState {
  final List<DueEntity> rawDues;
  final List<DueEntity> dues; // Enriched with payments
  final List<PaymentRecordEntity> payments;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String duesFilter; // 'All', 'Today', 'Upcoming', 'Overdue', 'Paid'
  final String searchQuery;

  const DuesState({
    this.rawDues = const [],
    this.dues = const [],
    this.payments = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.duesFilter = 'All',
    this.searchQuery = '',
  });

  DuesState copyWith({
    List<DueEntity>? rawDues,
    List<DueEntity>? dues,
    List<PaymentRecordEntity>? payments,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? duesFilter,
    String? searchQuery,
    bool clearError = false,
  }) {
    return DuesState(
      rawDues: rawDues ?? this.rawDues,
      dues: dues ?? this.dues,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      duesFilter: duesFilter ?? this.duesFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class DuesController extends StateNotifier<DuesState> {
  final DuesRepository _repository;
  final NotificationService _notificationService;
  final Ref _ref;
  StreamSubscription<List<DueEntity>>? _duesSubscription;
  StreamSubscription<List<PaymentRecordEntity>>? _paymentsSubscription;

  List<DueEntity> _currentRawDues = [];
  List<PaymentRecordEntity> _currentPayments = [];

  DuesController(
    this._repository,
    this._notificationService,
    this._ref,
  ) : super(const DuesState()) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authControllerProvider, (_, authState) {
      final user = authState.user;
      if (user != null && user.id.isNotEmpty) {
        _subscribeToUserData(user.id);
      } else {
        _cancelSubscriptions();
        _currentRawDues = [];
        _currentPayments = [];
        state = const DuesState();
      }
    });

    final initialUser = _ref.read(authControllerProvider).user;
    if (initialUser != null && initialUser.id.isNotEmpty) {
      _subscribeToUserData(initialUser.id);
    }
  }

  void _subscribeToUserData(String ownerId) {
    _cancelSubscriptions();
    state = state.copyWith(isLoading: true, clearError: true);

    _duesSubscription = _repository.watchDues(ownerId).listen(
      (rawList) {
        _currentRawDues = rawList;
        _recalculateAndEmit();
      },
      onError: (e) {
        state = state.copyWith(
          error: _cleanErrorMessage(e),
          isLoading: false,
        );
      },
    );

    _paymentsSubscription = _repository.watchPayments(ownerId).listen(
      (payList) {
        _currentPayments = payList;
        _recalculateAndEmit();
      },
      onError: (e) {
        state = state.copyWith(
          error: _cleanErrorMessage(e),
          isLoading: false,
        );
      },
    );
  }

  void _recalculateAndEmit() {
    // 1. Group payments by dueId for O(1) balance lookup
    final paymentsByDueId = <String, List<PaymentRecordEntity>>{};
    for (final payment in _currentPayments) {
      paymentsByDueId.putIfAbsent(payment.dueId, () => []).add(payment);
    }

    // 2. Enrich each due with real-time calculated total paid, remaining, and derived status
    final enrichedDues = _currentRawDues.map((rawDue) {
      final duePayments = paymentsByDueId[rawDue.id] ?? const [];
      return DuePaymentCalculator.enrichDue(rawDue, duePayments);
    }).toList();

    state = state.copyWith(
      rawDues: _currentRawDues,
      dues: enrichedDues,
      payments: _currentPayments,
      isLoading: false,
      clearError: true,
    );
  }

  void _cancelSubscriptions() {
    _duesSubscription?.cancel();
    _duesSubscription = null;
    _paymentsSubscription?.cancel();
    _paymentsSubscription = null;
  }

  Future<void> loadDues() async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final duesList = await _repository.getDues(user.id);
      final paymentsList = await _repository.getPayments(user.id);
      _currentRawDues = duesList;
      _currentPayments = paymentsList;
      _recalculateAndEmit();
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
      );
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(duesFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  bool hasActiveDuesForCustomer(String customerId) {
    return state.dues.any((d) =>
        d.customerId == customerId &&
        d.status != DueStatus.cancelled &&
        d.status != DueStatus.paid);
  }

  bool hasFinancialRecordsForCustomer(String customerId) {
    final hasDues = state.dues.any((d) => d.customerId == customerId);
    final hasPayments = state.payments.any((p) => p.customerId == customerId);
    return hasDues || hasPayments;
  }

  Future<DueEntity?> addDue({
    required String customerId,
    String? customerName,
    required double amount,
    required String description,
    required String dueDate,
    ReminderType reminderType = ReminderType.oneDayBefore,
    bool reminderEnabled = true,
    RecurrenceType recurrence = RecurrenceType.none,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return null;
    }

    if (customerId.isEmpty) {
      state = state.copyWith(error: 'Please select a customer.');
      return null;
    }

    if (amount <= 0) {
      state = state.copyWith(error: 'Due amount must be greater than ₹0.');
      return null;
    }

    final trimmedDesc = description.trim();
    if (trimmedDesc.isEmpty) {
      state =
          state.copyWith(error: 'Please enter a description for this payment.');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final now = DateTime.now();
      final derivedStatus = DuePaymentCalculator.calculateDueStatus(
        amount: amount,
        totalPaid: 0.0,
        dueDate: dueDate,
        isCancelled: false,
      );

      final newDue = DueEntity(
        id: '',
        ownerId: user.id,
        businessId: user.id,
        customerId: customerId,
        customerName: customerName ?? '',
        amount: amount,
        paidAmount: 0.0,
        description: trimmedDesc,
        dueDate: dueDate,
        status: derivedStatus,
        reminderType: reminderType,
        reminderEnabled: reminderEnabled,
        recurrence: recurrence,
        createdAt: now,
        updatedAt: now,
      );

      final created = await _repository.createDue(newDue);

      // Schedule local notification reminder if enabled
      if (created.reminderEnabled &&
          created.reminderType != ReminderType.none) {
        try {
          await _notificationService.scheduleDueReminder(
            created,
            customerName: created.customerName,
          );
        } catch (e) {
          // Notification failure should not fail due creation
        }
      }

      state = state.copyWith(isSaving: false);
      return created;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isSaving: false,
      );
      return null;
    }
  }

  Future<bool> updateDue(DueEntity due) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return false;
    }

    if (due.amount <= 0) {
      state = state.copyWith(error: 'Due amount must be greater than ₹0.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final totalPaid =
          DuePaymentCalculator.calculateTotalPaid(due.id, _currentPayments);
      final derivedStatus = due.status == DueStatus.cancelled
          ? DueStatus.cancelled
          : DuePaymentCalculator.calculateDueStatus(
              amount: due.amount,
              totalPaid: totalPaid,
              dueDate: due.dueDate,
              isCancelled: false,
            );

      final updated = due.copyWith(
        ownerId: user.id,
        businessId: user.id,
        paidAmount: totalPaid,
        status: derivedStatus,
        updatedAt: DateTime.now(),
      );

      await _repository.updateDue(updated);

      // Reschedule or cancel local reminder
      try {
        await _notificationService.cancelReminderForDue(updated.id);
        if (updated.reminderEnabled &&
            updated.reminderType != ReminderType.none &&
            updated.status != DueStatus.paid &&
            updated.status != DueStatus.cancelled) {
          await _notificationService.scheduleDueReminder(
            updated,
            customerName: updated.customerName,
          );
        }
      } catch (e) {
        // Notification failure should not fail due update
      }

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isSaving: false,
      );
      return false;
    }
  }

  Future<bool> cancelDue(String dueId) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.cancelDue(
        ownerId: user.id,
        dueId: dueId,
      );
      // Cancel pending local notification reminder
      await _notificationService.cancelReminderForDue(dueId);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isSaving: false,
      );
      return false;
    }
  }

  Future<bool> deleteDue(String dueId) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deleteDue(
        ownerId: user.id,
        dueId: dueId,
      );
      // Cancel pending local notification reminder
      await _notificationService.cancelReminderForDue(dueId);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isSaving: false,
      );
      return false;
    }
  }

  // ==========================================
  // Payment Recording & Deletion
  // ==========================================

  Future<PaymentRecordEntity?> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
    String? paidAt,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return null;
    }

    if (amount <= 0) {
      state =
          state.copyWith(error: 'Please enter a valid amount greater than ₹0.');
      return null;
    }

    final due = state.dues.where((d) => d.id == dueId).firstOrNull;
    if (due == null) {
      state = state.copyWith(error: 'Associated due record not found.');
      return null;
    }

    if (due.isCancelled) {
      state =
          state.copyWith(error: 'Cannot record payment for a cancelled due.');
      return null;
    }

    if (amount > due.remainingAmount + 0.001) {
      state = state.copyWith(
          error: 'Payment cannot be greater than the remaining amount.');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final paymentToSave = PaymentRecordEntity(
        id: '',
        ownerId: user.id,
        businessId: user.id,
        dueId: dueId,
        customerId: due.customerId,
        customerName: due.customerName,
        amount: amount,
        paymentMethod: paymentMethod,
        paidAt: paidAt ?? DateFormatter.todayIsoDate(),
        receiptNumber:
            'REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        notes: notes,
        createdAt: DateTime.now(),
      );

      final recorded = await _repository.recordPayment(paymentToSave);

      // Status change interaction with reminder
      try {
        final remainingAfterPayment = due.remainingAmount - amount;
        if (remainingAfterPayment <= 0.001) {
          // Due is now PAID -> Cancel pending reminder
          await _notificationService.cancelReminderForDue(dueId);
        } else {
          // PARTIALLY_PAID -> Keep reminder active with updated remaining balance
          if (due.reminderEnabled && due.reminderType != ReminderType.none) {
            final partiallyPaidDue = due.copyWith(
              paidAmount: due.paidAmount + amount,
              status: DueStatus.partiallyPaid,
            );
            await _notificationService.scheduleDueReminder(
              partiallyPaidDue,
              customerName: due.customerName,
            );
          }
        }
      } catch (e) {
        // Notification failure should not fail payment recording
      }

      state = state.copyWith(isSaving: false);
      return recorded;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isSaving: false,
      );
      return null;
    }
  }

  Future<bool> deletePayment(String paymentId) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deletePayment(
        ownerId: user.id,
        paymentId: paymentId,
      );
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isSaving: false,
      );
      return false;
    }
  }

  String _cleanErrorMessage(Object error) {
    var msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }
    return msg;
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}

final duesControllerProvider =
    StateNotifierProvider<DuesController, DuesState>((ref) {
  final repo = ref.watch(duesRepositoryProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return DuesController(repo, notificationService, ref);
});
