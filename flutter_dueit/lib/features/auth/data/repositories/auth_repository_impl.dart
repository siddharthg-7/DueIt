import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  UserEntity? _currentUser;

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Delay to simulate disk/API load
    await Future.delayed(const Duration(milliseconds: 300));
    return _currentUser;
  }

  @override
  Future<UserEntity> updateBusinessProfile(UserEntity profile) async {
    _currentUser = profile;
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }

  @override
  Future<UserEntity> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Create a mock user on successful sign in
    _currentUser = UserEntity(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      businessName: 'Apex Martial Arts Academy',
      businessType: 'Karate / Martial Arts',
      ownerName: 'Sensei Alex Rivera',
      phone: '+91 98765 43210',
      upiId: 'apexkarate@okhdfcbank',
      currencySymbol: '₹',
      isSetupComplete: true,
    );
    return _currentUser!;
  }

  @override
  Future<UserEntity> signUp(UserEntity user) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _currentUser = user.copyWith(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      isSetupComplete: true,
    );
    return _currentUser!;
  }
}
