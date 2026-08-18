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

  const UserEntity({
    required this.id,
    required this.email,
    required this.businessName,
    required this.businessType,
    required this.ownerName,
    this.phone,
    this.upiId,
    this.currencySymbol = '₹',
    this.isSetupComplete = false,
  });

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
    );
  }
}
