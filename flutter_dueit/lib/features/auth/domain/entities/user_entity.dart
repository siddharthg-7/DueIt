import 'business_profile.dart';

class UserEntity {
  final String id;
  final String email;
  final String businessName;
  final String businessType;
  final String ownerName;
  final String? phone;
  final String? upiId;
  final String currencySymbol;
  final bool isSetupComplete;
  final BusinessProfile? profile;

  const UserEntity({
    required this.id,
    required this.email,
    this.businessName = '',
    this.businessType = 'General',
    this.ownerName = '',
    this.phone,
    this.upiId,
    this.currencySymbol = '₹',
    this.isSetupComplete = false,
    this.profile,
  });

  factory UserEntity.fromFirebaseUser({
    required String uid,
    required String email,
    BusinessProfile? profile,
  }) {
    return UserEntity(
      id: uid,
      email: email,
      businessName: profile?.businessName ?? '',
      businessType: profile?.businessType ?? 'General',
      ownerName: profile?.ownerName ?? '',
      phone: profile?.phone,
      upiId: profile?.upiId,
      currencySymbol: profile?.currencySymbol ?? '₹',
      isSetupComplete: profile != null && profile.businessName.isNotEmpty,
      profile: profile,
    );
  }

  UserEntity copyWith({
    String? id,
    String? email,
    String? businessName,
    String? businessType,
    String? ownerName,
    String? phone,
    String? upiId,
    String? currencySymbol,
    bool? isSetupComplete,
    BusinessProfile? profile,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      upiId: upiId ?? this.upiId,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      profile: profile ?? this.profile,
    );
  }
}
