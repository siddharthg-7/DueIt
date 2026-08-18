import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> updateBusinessProfile(UserEntity profile);
  Future<void> signOut();
  Future<UserEntity> signIn(String email, String password);
  Future<UserEntity> signUp(UserEntity user);
}
