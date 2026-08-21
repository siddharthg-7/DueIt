import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl();
});

final customerListStreamProvider = StreamProvider<List<CustomerEntity>>((ref) {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.id.isEmpty) {
    return Stream.value([]);
  }
  final repo = ref.watch(customerRepositoryProvider);
  return repo.watchCustomers(user.id);
});

class CustomerState {
  final List<CustomerEntity> customers;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String searchQuery;
  final String filterTab; // 'All', 'With Balance', 'Overdue'

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.searchQuery = '',
    this.filterTab = 'All',
  });

  CustomerState copyWith({
    List<CustomerEntity>? customers,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? searchQuery,
    String? filterTab,
    bool clearError = false,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      filterTab: filterTab ?? this.filterTab,
    );
  }
}

class CustomerController extends StateNotifier<CustomerState> {
  final CustomerRepository _repository;
  final Ref _ref;
  StreamSubscription<List<CustomerEntity>>? _streamSubscription;

  CustomerController(this._repository, this._ref)
      : super(const CustomerState()) {
    _init();
  }

  void _init() {
    _ref.listen<AuthState>(authControllerProvider, (_, authState) {
      final user = authState.user;
      if (user != null && user.id.isNotEmpty) {
        _subscribeToCustomers(user.id);
      } else {
        _streamSubscription?.cancel();
        state = const CustomerState();
      }
    });

    final initialUser = _ref.read(authControllerProvider).user;
    if (initialUser != null && initialUser.id.isNotEmpty) {
      _subscribeToCustomers(initialUser.id);
    }
  }

  void _subscribeToCustomers(String ownerId) {
    _streamSubscription?.cancel();
    state = state.copyWith(isLoading: true, clearError: true);

    _streamSubscription = _repository.watchCustomers(ownerId).listen(
      (list) {
        state = state.copyWith(
          customers: list,
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

  Future<void> loadCustomers() async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) return;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repository.getCustomers(user.id);
      state = state.copyWith(customers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: _cleanErrorMessage(e),
        isLoading: false,
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilterTab(String tab) {
    state = state.copyWith(filterTab: tab);
  }

  Future<CustomerEntity?> addCustomer({
    required String name,
    String? phone,
    String? email,
    String? notes,
  }) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return null;
    }

    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      state = state.copyWith(error: 'Client name is required.');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final now = DateTime.now();
      final newCustomer = CustomerEntity(
        id: '',
        ownerId: user.id,
        businessId: user.id,
        name: trimmedName,
        phone: phone?.trim() ?? '',
        email: email?.trim().isEmpty == true ? null : email?.trim(),
        notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final created = await _repository.createCustomer(newCustomer);
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

  Future<bool> updateCustomer(CustomerEntity customer) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final updated = customer.copyWith(
        ownerId: user.id,
        businessId: user.id,
        updatedAt: DateTime.now(),
      );
      await _repository.updateCustomer(updated);
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

  Future<bool> deleteCustomer(String customerId) async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null || user.id.isEmpty) {
      state = state.copyWith(error: 'User is not authenticated.');
      return false;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deleteCustomer(
        ownerId: user.id,
        customerId: customerId,
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
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final customerControllerProvider =
    StateNotifierProvider<CustomerController, CustomerState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomerController(repo, ref);
});
