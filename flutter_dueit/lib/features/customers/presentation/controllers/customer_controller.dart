import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../data/repositories/customer_repository_impl.dart';

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl();
});

class CustomerState {
  final List<CustomerEntity> customers;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String filterTab; // 'All', 'With Balance', 'Overdue'

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.filterTab = 'All',
  });

  CustomerState copyWith({
    List<CustomerEntity>? customers,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? filterTab,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      filterTab: filterTab ?? this.filterTab,
    );
  }
}

class CustomerController extends StateNotifier<CustomerState> {
  final CustomerRepository _repository;

  CustomerController(this._repository) : super(const CustomerState()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true);
    try {
      final list = await _repository.getCustomers();
      state = state.copyWith(customers: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilterTab(String tab) {
    state = state.copyWith(filterTab: tab);
  }

  Future<CustomerEntity> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? notes,
  }) async {
    final now = DateTime.now();
    final newCustomer = CustomerEntity(
      id: 'cust_${const Uuid().v4().substring(0, 8)}',
      name: name.trim(),
      phone: phone.trim(),
      email: email?.trim(),
      notes: notes?.trim(),
      clientSince: 'Aug 2026',
      createdAt: '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
    );

    final created = await _repository.createCustomer(newCustomer);
    await loadCustomers();
    return created;
  }

  Future<void> updateCustomer(CustomerEntity customer) async {
    await _repository.updateCustomer(customer);
    await loadCustomers();
  }

  Future<void> deleteCustomer(String id) async {
    await _repository.deleteCustomer(id);
    await loadCustomers();
  }
}

final customerControllerProvider =
    StateNotifierProvider<CustomerController, CustomerState>((ref) {
  final repo = ref.watch(customerRepositoryProvider);
  return CustomerController(repo);
});
