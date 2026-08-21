import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/due_entity.dart';
import '../../domain/entities/payment_record_entity.dart';
import '../../domain/repositories/dues_repository.dart';
import '../../data/repositories/dues_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final duesRepositoryProvider = Provider<DuesRepository>((ref) {
  return DuesRepositoryImpl();
});

final duesListStreamProvider = StreamProvider<List<DueEntity>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.id.isEmpty) {
    return Stream.value([]);
  }
  final repo = ref.watch(duesRepositoryProvider);
  return repo.watchDues(user.id);
});

class DuesState {
  final List<DueEntity> dues;
  final List<PaymentRecordEntity> payments;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String duesFilter; // 'All', 'Today', 'Upcoming', 'Overdue'
  final String searchQuery;

  const DuesState({
    this.dues = const [],
    this.payments = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.duesFilter = 'All',
    this.searchQuery = '',
  });

  DuesState copyWith({
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
  final Ref _ref;
  StreamSubscription<List<DueEntity>>? _streamSubscription;

  DuesController(this._repository, this._ref) : super(const DuesState()) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authControllerProvider, (_, authState) {
      final user = authState.user;
      if (user != null && user.id.isNotEmpty) {
        _subscribeToDues(user.id);
      } else {
        _streamSubscription?.cancel();
        state = const DuesState();
      }
    });

    final initialUser = _ref.read(authControllerProvider).user;
    if (initialUser != null && initialUser.id.isNotEmpty) {
      _subscribeToDues(initialUser.id);
    }
  }

  void _subscribeToDues(String ownerId) {
    _streamSubscription?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);

    _streamSubscription = _repository.watchDues(ownerId).listen(
      (list) {
        state = state.copyWith(
          dues: list,
          isLoading: false,
          clearError: true,
        );
      },
      onError: (err) {
        state = state.copyWith(
          isLoading: false,
          error: _cleanErrorMessage(err),
        );
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> loadDues() async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final duesList = await _repository.getDues(user.id);
      state = state.copyWith(
        dues: duesList,
        isLoading: false,
      );
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
      final derivedStatus =
          DueEntity.deriveStatus(dueDate: dueDate, isCancelled: false);

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
      final derivedStatus = due.status == DueStatus.cancelled
          ? DueStatus.cancelled
          : DueEntity.deriveStatus(dueDate: due.dueDate, isCancelled: false);

      final updated = due.copyWith(
        ownerId: user.id,
        businessId: user.id,
        status: derivedStatus,
        updatedAt: DateTime.now(),
      );

      await _repository.updateDue(updated);
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

  Future<PaymentRecordEntity> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    return _repository.recordPayment(
      dueId: dueId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
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
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final duesControllerProvider =
    StateNotifierProvider<DuesController, DuesState>((ref) {
  final repo = ref.watch(duesRepositoryProvider);
  return DuesController(repo, ref);
});
