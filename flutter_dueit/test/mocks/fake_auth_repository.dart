import 'dart:async';
import 'package:dueit/features/auth/domain/entities/user_entity.dart';
import 'package:dueit/features/auth/domain/entities/business_profile.dart';
import 'package:dueit/features/auth/domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  UserEntity? _currentUser;
  final Map<String, BusinessProfile> _profiles = {};
  final StreamController<UserEntity?> _authController =
      StreamController<UserEntity?>.broadcast();

  bool shouldFailSignIn = false;
  bool shouldFailSignUp = false;
  bool shouldFailReset = false;
  bool shouldFailSaveProfile = false;

  String? lastResetEmailSent;

  FakeAuthRepository(
      {UserEntity? initialUser, BusinessProfile? initialProfile}) {
    if (initialUser != null) {
      _currentUser = initialUser;
      if (initialProfile != null) {
        _profiles[initialUser.id] = initialProfile;
      }
    }
  }

  @override
  Stream<UserEntity?> authStateChanges() async* {
    yield _currentUser;
    yield* _authController.stream;
  }

  @override
  UserEntity? getCurrentUser() => _currentUser;

  @override
  Future<UserEntity?> reloadCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserEntity> signIn(String email, String password) async {
    if (shouldFailSignIn) {
      throw Exception('Email or password is incorrect.');
    }
    final uid = 'user_${email.hashCode.abs()}';
    final profile = _profiles[uid];
    _currentUser = UserEntity(
      id: uid,
      email: email,
      businessName: profile?.businessName ?? '',
      businessType: profile?.businessType ?? 'General',
      ownerName: profile?.ownerName ?? '',
      phone: profile?.phone,
      upiId: profile?.upiId,
      isSetupComplete: profile != null && profile.businessName.isNotEmpty,
      profile: profile,
    );
    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserEntity> signUp({
    required String email,
    required String password,
  }) async {
    if (shouldFailSignUp) {
      throw Exception('An account with this email already exists.');
    }
    final uid = 'user_${email.hashCode.abs()}';
    _currentUser = UserEntity(
      id: uid,
      email: email,
      isSetupComplete: false,
    );
    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldFailReset) {
      throw Exception('Unable to send password reset email. Please try again.');
    }
    lastResetEmailSent = email;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<BusinessProfile?> getBusinessProfile(String uid) async {
    return _profiles[uid];
  }

  @override
  Future<BusinessProfile> saveBusinessProfile(BusinessProfile profile) async {
    if (shouldFailSaveProfile) {
      throw Exception('Failed to save business profile.');
    }
    _profiles[profile.ownerId] = profile;
    if (_currentUser != null && _currentUser!.id == profile.ownerId) {
      _currentUser = _currentUser!.copyWith(
        businessName: profile.businessName,
        businessType: profile.businessType,
        ownerName: profile.ownerName,
        phone: profile.phone,
        upiId: profile.upiId,
        isSetupComplete: true,
        profile: profile,
      );
      _authController.add(_currentUser);
    }
    return profile;
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveBusinessProfile(businessProfile);
    return profile.copyWith(isSetupComplete: true, profile: businessProfile);
  }

  void dispose() {
    _authController.close();
  }
}
