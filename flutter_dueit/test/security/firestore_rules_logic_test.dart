import 'package:flutter_test/flutter_test.dart';

/// Simulates and verifies the mathematical/logical invariants enforced by
/// the hardened Firestore Security Rules in [firestore.rules].
class MockFirestoreSecurityContext {
  final String? authUid;

  MockFirestoreSecurityContext({this.authUid});

  bool get isAuthenticated => authUid != null && authUid!.isNotEmpty;

  bool isOwner(String userId) => isAuthenticated && authUid == userId;

  // Rule for /users/{userId}
  bool canReadUserDoc(String userId) => isOwner(userId);
  bool canWriteUserDoc(String userId) => isOwner(userId);

  // Rule for /users/{userId}/customers/{customerId} - CREATE
  bool canCreateCustomer({
    required String pathUserId,
    String? requestOwnerId,
  }) {
    if (!isOwner(pathUserId)) return false;
    if (requestOwnerId != null && requestOwnerId != pathUserId) return false;
    return true;
  }

  // Rule for /users/{userId}/customers/{customerId} - READ
  bool canReadCustomer({required String pathUserId}) {
    return isOwner(pathUserId);
  }

  // Rule for /users/{userId}/customers/{customerId} - UPDATE
  bool canUpdateCustomer({
    required String pathUserId,
    required String currentOwnerId,
    String? newOwnerId,
  }) {
    if (!isOwner(pathUserId)) return false;
    if (newOwnerId != null &&
        newOwnerId != currentOwnerId &&
        newOwnerId != pathUserId) {
      return false;
    }
    return true;
  }

  // Rule for /users/{userId}/customers/{customerId} - DELETE
  bool canDeleteCustomer({required String pathUserId}) {
    return isOwner(pathUserId);
  }

  // Rule for /users/{userId}/dues/{dueId} - CREATE
  bool canCreateDue({
    required String pathUserId,
    String? requestOwnerId,
  }) {
    if (!isOwner(pathUserId)) return false;
    if (requestOwnerId != null && requestOwnerId != pathUserId) return false;
    return true;
  }

  // Rule for /users/{userId}/dues/{dueId} - READ
  bool canReadDue({required String pathUserId}) {
    return isOwner(pathUserId);
  }

  // Rule for /users/{userId}/dues/{dueId} - UPDATE
  bool canUpdateDue({
    required String pathUserId,
    required String currentOwnerId,
    String? newOwnerId,
  }) {
    if (!isOwner(pathUserId)) return false;
    if (newOwnerId != null &&
        newOwnerId != currentOwnerId &&
        newOwnerId != pathUserId) {
      return false;
    }
    return true;
  }

  // Rule for /users/{userId}/dues/{dueId} - DELETE
  bool canDeleteDue({required String pathUserId}) {
    return isOwner(pathUserId);
  }

  // Rule for arbitrary wildcard / other collection
  bool canAccessUndeclaredPath(String path) {
    return false;
  }
}

void main() {
  group('Hardened Firestore Security Rules Logic Tests', () {
    const userA = 'user_A';
    const userB = 'user_B';

    test('1. User A accessing own user document, customers, and dues -> ALLOW',
        () {
      final contextA = MockFirestoreSecurityContext(authUid: userA);

      expect(contextA.canReadUserDoc(userA), isTrue);
      expect(contextA.canWriteUserDoc(userA), isTrue);
      expect(contextA.canReadCustomer(pathUserId: userA), isTrue);
      expect(contextA.canDeleteCustomer(pathUserId: userA), isTrue);
      expect(
        contextA.canCreateCustomer(
          pathUserId: userA,
          requestOwnerId: userA,
        ),
        isTrue,
      );

      expect(contextA.canReadDue(pathUserId: userA), isTrue);
      expect(contextA.canDeleteDue(pathUserId: userA), isTrue);
      expect(
        contextA.canCreateDue(
          pathUserId: userA,
          requestOwnerId: userA,
        ),
        isTrue,
      );
    });

    test('2. User A accessing User B customers and dues -> DENY', () {
      final contextA = MockFirestoreSecurityContext(authUid: userA);

      expect(contextA.canReadUserDoc(userB), isFalse);
      expect(contextA.canWriteUserDoc(userB), isFalse);
      expect(contextA.canReadCustomer(pathUserId: userB), isFalse);
      expect(contextA.canDeleteCustomer(pathUserId: userB), isFalse);
      expect(
        contextA.canCreateCustomer(
          pathUserId: userB,
          requestOwnerId: userB,
        ),
        isFalse,
      );

      expect(contextA.canReadDue(pathUserId: userB), isFalse);
      expect(contextA.canDeleteDue(pathUserId: userB), isFalse);
      expect(
        contextA.canCreateDue(
          pathUserId: userB,
          requestOwnerId: userB,
        ),
        isFalse,
      );
    });

    test('3. Unauthenticated request to any resource -> DENY', () {
      final unauthenticated = MockFirestoreSecurityContext(authUid: null);

      expect(unauthenticated.canReadUserDoc(userA), isFalse);
      expect(unauthenticated.canWriteUserDoc(userA), isFalse);
      expect(unauthenticated.canReadCustomer(pathUserId: userA), isFalse);
      expect(
        unauthenticated.canCreateCustomer(
          pathUserId: userA,
          requestOwnerId: userA,
        ),
        isFalse,
      );
      expect(unauthenticated.canDeleteCustomer(pathUserId: userA), isFalse);

      expect(unauthenticated.canReadDue(pathUserId: userA), isFalse);
      expect(
        unauthenticated.canCreateDue(
          pathUserId: userA,
          requestOwnerId: userA,
        ),
        isFalse,
      );
      expect(unauthenticated.canDeleteDue(pathUserId: userA), isFalse);
    });

    test(
        '4. User A attempting to forge ownerId on customer/due creation -> DENY',
        () {
      final contextA = MockFirestoreSecurityContext(authUid: userA);

      // Path is user_A, but payload claims ownerId is user_B
      expect(
        contextA.canCreateCustomer(
          pathUserId: userA,
          requestOwnerId: userB,
        ),
        isFalse,
      );

      expect(
        contextA.canCreateDue(
          pathUserId: userA,
          requestOwnerId: userB,
        ),
        isFalse,
      );
    });

    test(
        '5. User A attempting to hijack/transfer customer or due ownerId on update -> DENY',
        () {
      final contextA = MockFirestoreSecurityContext(authUid: userA);

      // Attempting to change existing customer owner from user_A to user_B
      expect(
        contextA.canUpdateCustomer(
          pathUserId: userA,
          currentOwnerId: userA,
          newOwnerId: userB,
        ),
        isFalse,
      );

      expect(
        contextA.canUpdateDue(
          pathUserId: userA,
          currentOwnerId: userA,
          newOwnerId: userB,
        ),
        isFalse,
      );

      // Updating without changing ownerId -> ALLOW
      expect(
        contextA.canUpdateCustomer(
          pathUserId: userA,
          currentOwnerId: userA,
          newOwnerId: userA,
        ),
        isTrue,
      );

      expect(
        contextA.canUpdateDue(
          pathUserId: userA,
          currentOwnerId: userA,
          newOwnerId: userA,
        ),
        isTrue,
      );
    });

    test('6. Accessing unmapped collections / wildcard removal -> DENY', () {
      final contextA = MockFirestoreSecurityContext(authUid: userA);

      expect(
          contextA.canAccessUndeclaredPath('system_configs/global'), isFalse);
      expect(contextA.canAccessUndeclaredPath('arbitrary_collection/item'),
          isFalse);
    });
  });
}
