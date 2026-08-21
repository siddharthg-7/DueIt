import '../entities/user_entity.dart';
import '../entities/business_profile.dart';

abstract class AuthRepository {
  Stream<UserEntity?> authStateChanges();
  UserEntity? getCurrentUser();
  Future<UserEntity?> reloadCurrentUser();
  Future<UserEntity> signIn(String email, String password);
  Future<UserEntity> signUp({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<BusinessProfile?> getBusinessProfile(String uid);
  Future<BusinessProfile> saveBusinessProfile(BusinessProfile profile);
  Future<UserEntity> updateBusinessProfile(UserEntity profile);
}
