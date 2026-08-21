import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final FirebaseFirestore _firestore;

  CustomerRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _customerCollection(
      String ownerId) {
    return _firestore.collection('users').doc(ownerId).collection('customers');
  }

  @override
  Stream<List<CustomerEntity>> watchCustomers(String ownerId) {
    if (ownerId.isEmpty) {
      return Stream.value([]);
    }

    try {
      return _customerCollection(ownerId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return CustomerEntity.fromMap(doc.data(), docId: doc.id);
        }).toList();
      }).handleError((error) {
        // Fallback for cases where index or network is initializing
        return <CustomerEntity>[];
      });
    } catch (_) {
      return Stream.value([]);
    }
  }

  @override
  Future<List<CustomerEntity>> getCustomers(String ownerId) async {
    if (ownerId.isEmpty) return [];
    try {
      final snapshot = await _customerCollection(ownerId)
          .orderBy('updatedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        return CustomerEntity.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<CustomerEntity?> getCustomer({
    required String ownerId,
    required String customerId,
  }) async {
    if (ownerId.isEmpty || customerId.isEmpty) return null;
    try {
      final doc = await _customerCollection(ownerId).doc(customerId).get();
      if (!doc.exists || doc.data() == null) return null;
      return CustomerEntity.fromMap(doc.data()!, docId: doc.id);
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<CustomerEntity> createCustomer(CustomerEntity customer) async {
    if (customer.ownerId.isEmpty) {
      throw Exception('Cannot create customer without authenticated owner.');
    }
    try {
      final collection = _customerCollection(customer.ownerId);
      final docRef = customer.id.isNotEmpty
          ? collection.doc(customer.id)
          : collection.doc();

      final customerToSave = customer.copyWith(
        id: docRef.id,
        createdAt: customer.createdAt,
        updatedAt: DateTime.now(),
      );

      await docRef.set(customerToSave.toMap());
      return customerToSave;
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<CustomerEntity> updateCustomer(CustomerEntity customer) async {
    if (customer.ownerId.isEmpty || customer.id.isEmpty) {
      throw Exception('Customer identification missing.');
    }
    try {
      final updatedCustomer = customer.copyWith(
        updatedAt: DateTime.now(),
      );
      await _customerCollection(customer.ownerId)
          .doc(customer.id)
          .set(updatedCustomer.toMap(), SetOptions(merge: true));
      return updatedCustomer;
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  @override
  Future<void> deleteCustomer({
    required String ownerId,
    required String customerId,
  }) async {
    if (ownerId.isEmpty || customerId.isEmpty) {
      throw Exception('Customer identification missing for deletion.');
    }
    try {
      await _customerCollection(ownerId).doc(customerId).delete();
    } catch (e) {
      throw Exception(_mapFirestoreError(e));
    }
  }

  String _mapFirestoreError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Permission denied. Please verify your login status.';
        case 'unavailable':
          return 'Firestore is temporarily unavailable. Please check your connection.';
        default:
          return error.message ??
              'A database error occurred. Please try again.';
      }
    }
    var msg = error.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }
    return msg;
  }
}
