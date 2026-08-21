import 'dart:async';
import 'package:dueit/features/customers/domain/entities/customer_entity.dart';
import 'package:dueit/features/customers/domain/repositories/customer_repository.dart';

class FakeCustomerRepository implements CustomerRepository {
  final Map<String, List<CustomerEntity>> _customersByOwner = {};
  final StreamController<List<CustomerEntity>> _streamController =
      StreamController<List<CustomerEntity>>.broadcast();

  bool shouldFail = false;

  FakeCustomerRepository(
      {List<CustomerEntity>? initialCustomers, String ownerId = 'user_1'}) {
    if (initialCustomers != null) {
      _customersByOwner[ownerId] = List.from(initialCustomers);
    }
  }

  @override
  Stream<List<CustomerEntity>> watchCustomers(String ownerId) async* {
    yield List.unmodifiable(_customersByOwner[ownerId] ?? []);
    yield* _streamController.stream;
  }

  @override
  Future<List<CustomerEntity>> getCustomers(String ownerId) async {
    if (shouldFail) {
      throw Exception('Failed to load customers from database.');
    }
    return List.unmodifiable(_customersByOwner[ownerId] ?? []);
  }

  @override
  Future<CustomerEntity?> getCustomer({
    required String ownerId,
    required String customerId,
  }) async {
    if (shouldFail) {
      throw Exception('Failed to get customer.');
    }
    final list = _customersByOwner[ownerId] ?? [];
    return list.where((c) => c.id == customerId).firstOrNull;
  }

  @override
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    if (shouldFail) {
      throw Exception('Failed to create customer in Firestore.');
    }
    final list = _customersByOwner.putIfAbsent(customer.ownerId, () => []);
    final saved = customer.copyWith(
      id: customer.id.isEmpty ? 'cust_${list.length + 1}' : customer.id,
      updatedAt: DateTime.now(),
    );
    list.insert(0, saved);
    _streamController.add(List.unmodifiable(list));
    return saved;
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) async {
    if (shouldFail) {
      throw Exception('Failed to update customer in Firestore.');
    }
    final list = _customersByOwner[customer.ownerId] ?? [];
    final index = list.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      list[index] = customer;
      _streamController.add(List.unmodifiable(list));
    }
    return customer;
  }

  @override
  Future<void> deleteCustomer({
    required String ownerId,
    required String customerId,
  }) async {
    if (shouldFail) {
      throw Exception('Failed to delete customer from Firestore.');
    }
    final list = _customersByOwner[ownerId] ?? [];
    list.removeWhere((c) => c.id == customerId);
    _streamController.add(List.unmodifiable(list));
  }

  void dispose() {
    _streamController.close();
  }
}
