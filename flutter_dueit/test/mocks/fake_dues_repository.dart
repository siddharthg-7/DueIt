import 'dart:async';
import 'package:dueit/features/dues/domain/entities/due_entity.dart';
import 'package:dueit/features/dues/domain/entities/payment_record_entity.dart';
import 'package:dueit/features/dues/domain/repositories/dues_repository.dart';

class FakeDuesRepository implements DuesRepository {
  final Map<String, List<DueEntity>> _duesByOwner = {};
  final StreamController<List<DueEntity>> _streamController =
      StreamController<List<DueEntity>>.broadcast();

  bool shouldFail = false;

  FakeDuesRepository(
      {List<DueEntity>? initialDues, String ownerId = 'user_1'}) {
    if (initialDues != null) {
      _duesByOwner[ownerId] = List.from(initialDues);
    }
  }

  @override
  Stream<List<DueEntity>> watchDues(String ownerId) async* {
    yield List.unmodifiable(_duesByOwner[ownerId] ?? []);
    yield* _streamController.stream;
  }

  @override
  Future<List<DueEntity>> getDues(String ownerId) async {
    if (shouldFail) {
      throw Exception('Failed to load dues from database.');
    }
    return List.unmodifiable(_duesByOwner[ownerId] ?? []);
  }

  @override
  Future<DueEntity?> getDue({
    required String ownerId,
    required String dueId,
  }) async {
    if (shouldFail) {
      throw Exception('Failed to get due.');
    }
    final list = _duesByOwner[ownerId] ?? [];
    return list.where((d) => d.id == dueId).firstOrNull;
  }

  @override
  Future<DueEntity> createDue(DueEntity due) async {
    if (shouldFail) {
      throw Exception('Failed to create due in Firestore.');
    }
    final list = _duesByOwner.putIfAbsent(due.ownerId, () => []);
    final saved = due.copyWith(
      id: due.id.isEmpty ? 'due_${list.length + 1}' : due.id,
      updatedAt: DateTime.now(),
    );
    list.insert(0, saved);
    _streamController.add(List.unmodifiable(list));
    return saved;
  }

  @override
  Future<DueEntity> updateDue(DueEntity due) async {
    if (shouldFail) {
      throw Exception('Failed to update due in Firestore.');
    }
    final list = _duesByOwner[due.ownerId] ?? [];
    final index = list.indexWhere((d) => d.id == due.id);
    if (index != -1) {
      list[index] = due;
      _streamController.add(List.unmodifiable(list));
    }
    return due;
  }

  @override
  Future<void> deleteDue({
    required String ownerId,
    required String dueId,
  }) async {
    if (shouldFail) {
      throw Exception('Failed to delete due from Firestore.');
    }
    final list = _duesByOwner[ownerId] ?? [];
    list.removeWhere((d) => d.id == dueId);
    _streamController.add(List.unmodifiable(list));
  }

  @override
  Future<void> cancelDue({
    required String ownerId,
    required String dueId,
  }) async {
    if (shouldFail) {
      throw Exception('Failed to cancel due in Firestore.');
    }
    final list = _duesByOwner[ownerId] ?? [];
    final index = list.indexWhere((d) => d.id == dueId);
    if (index != -1) {
      list[index] = list[index].copyWith(status: DueStatus.cancelled);
      _streamController.add(List.unmodifiable(list));
    }
  }

  @override
  Future<List<PaymentRecordEntity>> getPayments([String? ownerId]) async {
    return [];
  }

  @override
  Future<PaymentRecordEntity> recordPayment({
    required String dueId,
    required double amount,
    required PaymentMethod paymentMethod,
    String? notes,
  }) async {
    throw UnimplementedError();
  }

  void dispose() {
    _streamController.close();
  }
}
