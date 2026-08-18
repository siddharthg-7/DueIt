import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final List<CustomerEntity> _customers = [
    const CustomerEntity(
      id: 'cust_1',
      name: 'Rahul Kumar',
      phone: '+91 98765 43210',
      email: 'rahul.k@example.com',
      notes: 'Karate Advanced Batch (Mon-Wed-Fri)',
      clientSince: 'Jan 2024',
      createdAt: '2024-01-15',
    ),
    const CustomerEntity(
      id: 'cust_2',
      name: 'Arjun Sharma',
      phone: '+91 98222 33445',
      email: 'arjun.s@example.com',
      notes: 'Monthly Gym Membership',
      clientSince: 'Feb 2024',
      createdAt: '2024-02-01',
    ),
    const CustomerEntity(
      id: 'cust_3',
      name: 'Sneha Reddy',
      phone: '+91 98111 22334',
      email: 'sneha.r@example.com',
      notes: 'August Tuition Batch',
      clientSince: 'Mar 2024',
      createdAt: '2024-03-10',
    ),
    const CustomerEntity(
      id: 'cust_4',
      name: 'Vikram Rao',
      phone: '+91 99333 44556',
      email: 'vikram.rao@example.com',
      notes: 'Personal Training Retainer',
      clientSince: 'Nov 2023',
      createdAt: '2023-11-01',
    ),
    const CustomerEntity(
      id: 'cust_5',
      name: 'Pooja Sharma',
      phone: '+91 98333 44556',
      email: 'pooja.s@example.com',
      notes: 'Yoga Evening Session',
      clientSince: 'Feb 2024',
      createdAt: '2024-02-20',
    ),
    const CustomerEntity(
      id: 'cust_6',
      name: 'Amitabh Sen',
      phone: '+91 97444 55667',
      email: 'amitabh.sen@example.com',
      notes: 'Karate Evening Batch',
      clientSince: 'Apr 2024',
      createdAt: '2024-04-05',
    ),
  ];

  @override
  Future<List<CustomerEntity>> getCustomers() async {
    return List.unmodifiable(_customers);
  }

  @override
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    _customers.insert(0, customer);
    return customer;
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index != -1) {
      _customers[index] = customer;
    }
    return customer;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    _customers.removeWhere((c) => c.id == id);
  }
}
