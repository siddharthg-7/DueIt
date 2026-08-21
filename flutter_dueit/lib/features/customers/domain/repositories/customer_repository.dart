import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Stream<List<CustomerEntity>> watchCustomers(String ownerId);
  Future<List<CustomerEntity>> getCustomers(String ownerId);
  Future<CustomerEntity?> getCustomer({
    required String ownerId,
    required String customerId,
  });
  Future<CustomerEntity> createCustomer(CustomerEntity customer);
  Future<CustomerEntity> updateCustomer(CustomerEntity customer);
  Future<void> deleteCustomer({
    required String ownerId,
    required String customerId,
  });
}
