import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/business_profile.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserEntity?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((fbUser) async {
      if (fbUser == null) return null;
      try {
        final profile = await getBusinessProfile(fbUser.uid);
        return UserEntity.fromFirebaseUser(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          profile: profile,
        );
      } catch (_) {
        return UserEntity.fromFirebaseUser(
          uid: fbUser.uid,
          email: fbUser.email ?? '',
          profile: null,
        );
      }
    });
  }

  @override
  UserEntity? getCurrentUser() {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return UserEntity.fromFirebaseUser(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
    );
  }

  @override
  Future<UserEntity?> reloadCurrentUser() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    try {
      await fbUser.reload();
      final profile = await getBusinessProfile(fbUser.uid);
      return UserEntity.fromFirebaseUser(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        profile: profile,
      );
    } catch (_) {
      return getCurrentUser();
    }
  }

  @override
  Future<UserEntity> signIn(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Unable to sign in. Please try again.');
      }

      final profile = await getBusinessProfile(fbUser.uid);
      return UserEntity.fromFirebaseUser(
        uid: fbUser.uid,
        email: fbUser.email ?? email.trim(),
        profile: profile,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to sign in. Please try again.');
    }
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) {
        throw Exception('Unable to create your account. Please try again.');
      }

      return UserEntity.fromFirebaseUser(
        uid: fbUser.uid,
        email: fbUser.email ?? email.trim(),
        profile: null,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to create your account. Please try again.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on fb_auth.FirebaseAuthException catch (e) {
      // In accordance with security best practices, avoid leaking whether the user exists or not.
      if (e.code == 'invalid-email') {
        throw Exception('Please enter a valid email address.');
      }
      // For user-not-found, don't throw an error to prevent user enumeration
    } catch (e) {
      throw Exception('Unable to send password reset email. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  @override
  Future<BusinessProfile?> getBusinessProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return BusinessProfile.fromMap(doc.data()!, docId: doc.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BusinessProfile> saveBusinessProfile(BusinessProfile profile) async {
    try {
      final uid = profile.ownerId;
      final data = profile.toMap();
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
      return profile;
    } catch (e) {
      throw Exception(
          'Failed to save business profile. Please check your connection.');
    }
  }

  @override
  Future<UserEntity> updateBusinessProfile(UserEntity profile) async {
    final businessProfile = BusinessProfile(
      id: profile.id,
      ownerId: profile.id,
      businessName: profile.businessName,
      businessType: profile.businessType,
      ownerName: profile.ownerName,
      phone: profile.phone,
      upiId: profile.upiId,
      currencySymbol: profile.currencySymbol,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await saveBusinessProfile(businessProfile);
    return profile.copyWith(
      isSetupComplete: true,
      profile: businessProfile,
    );
  }

  String _mapAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Your password is too weak. Please use at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few moments.';
      case 'operation-not-allowed':
        return 'Email/Password sign-in is not enabled in Firebase Console.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
}
