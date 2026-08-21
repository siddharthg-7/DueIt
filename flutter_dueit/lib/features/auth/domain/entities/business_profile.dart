class BusinessProfile {
  final String id;
  final String ownerId;
  final String businessName;
  final String businessType;
  final String? ownerName;
  final String? phone;
  final String? upiId;
  final String currencySymbol;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BusinessProfile({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.businessType,
    this.ownerName,
    this.phone,
    this.upiId,
    this.currencySymbol = '₹',
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  BusinessProfile copyWith({
    String? id,
    String? ownerId,
    String? businessName,
    String? businessType,
    String? ownerName,
    String? phone,
    String? upiId,
    String? currencySymbol,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      upiId: upiId ?? this.upiId,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'businessName': businessName,
      'businessType': businessType,
      'ownerName': ownerName ?? '',
      'phone': phone ?? '',
      'upiId': upiId ?? '',
      'currencySymbol': currencySymbol,
      'description': description ?? '',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BusinessProfile.fromMap(Map<String, dynamic> map, {String? docId}) {
    return BusinessProfile(
      id: docId ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      businessName: map['businessName'] as String? ?? '',
      businessType: map['businessType'] as String? ?? 'General',
      ownerName: map['ownerName'] as String?,
      phone: map['phone'] as String?,
      upiId: map['upiId'] as String?,
      currencySymbol: map['currencySymbol'] as String? ?? '₹',
      description: map['description'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
