import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getCustomers();
  Future<CustomerEntity> createCustomer(CustomerEntity customer);
  Future<CustomerEntity> updateCustomer(CustomerEntity customer);
  Future<void> deleteCustomer(String id);
}
