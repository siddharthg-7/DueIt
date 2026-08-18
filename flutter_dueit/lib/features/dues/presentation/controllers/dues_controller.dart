import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../../domain/repositories/dues_repository.dart';
import '../../data/repositories/dues_repository_impl.dart';

final duesRepositoryProvider = Provider<DuesRepository>((ref) {
  return DuesRepositoryImpl();
});

class DuesState {
  final List<DueEntity> dues;
  final List<PaymentRecordEntity> payments;
  final bool isLoading;
  final String? error;
  final String duesFilter; // 'All', 'Today', 'Upcoming', 'Overdue', 'Paid'
  final String searchQuery;

  const DuesState({
    this.dues = const [],
    this.payments = const [],
    this.isLoading = false,
    this.error,
    this.duesFilter = 'All',
    this.searchQuery = '',
  });

  DuesState copyWith({
    List<DueEntity>? dues,
    List<PaymentRecordEntity>? payments,
    bool? isLoading,
    String? error,
    String? duesFilter,
    String? searchQuery,
  }) {
    return DuesState(
      dues: dues ?? this.dues,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      duesFilter: duesFilter ?? this.duesFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class DuesController extends StateNotifier<DuesState> {
  final DuesRepository _repository;

  DuesController(this._repository) : super(const DuesState()) {
    loadDues();
  }

  Future<void> loadDues() async {
    state = state.copyWith(isLoading: true);
    try {
      final duesList = await _repository.getDues();
      final paymentsList = await _repository.getPayments();
      state = state.copyWith(
        dues: duesList,
        payments: paymentsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(duesFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<DueEntity> addDue({
    required String customerId,
    required String customerName,
    required double amount,
    required String description,
    required String dueDate,
    ReminderType reminderType = ReminderType.oneDayBefore,
    bool reminderEnabled = true,
    RecurrenceType recurrence = RecurrenceType.none,
  }) async {
    final now = DateTime.now();
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final newDue = DueEntity(
      id: 'due_${const Uuid().v4().substring(0, 8)}',
      customerId: customerId,
      customerName: customerName,
      amount: amount,
      paidAmount: 0,
      description:
          description.trim().isEmpty ? 'Payment Due' : description.trim(),
      dueDate: dueDate,
      status: dueDate == todayStr ? DueStatus.due : DueStatus.upcoming,
      reminderType: reminderType,
      reminderEnabled: reminderEnabled,
      recurrence: recurrence,
    );

    final created = await _repository.createDue(newDue);
    await loadDues();
    return created;
  }

  Future<PaymentRecordEntity> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    final payment = await _repository.recordPayment(
      dueId: dueId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
    await loadDues();
    return payment;
  }

  Future<void> updateDue(DueEntity due) async {
    await _repository.updateDue(due);
    await loadDues();
  }

  Future<void> cancelDue(String dueId) async {
    await _repository.cancelDue(dueId);
    await loadDues();
  }

  Future<void> deleteDue(String dueId) async {
    await _repository.deleteDue(dueId);
    await loadDues();
  }
}

final duesControllerProvider =
    StateNotifierProvider<DuesController, DuesState>((ref) {
  final repo = ref.watch(duesRepositoryProvider);
  return DuesController(repo);
});
