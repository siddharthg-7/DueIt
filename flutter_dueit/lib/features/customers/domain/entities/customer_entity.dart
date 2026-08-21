import 'package:intl/intl.dart';

class CustomerEntity {
  final String id;
  final String ownerId;
  final String businessId;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? initials;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerEntity({
    required this.id,
    this.ownerId = '',
    this.businessId = '',
    required this.name,
    this.phone = '',
    this.email,
    this.avatarUrl,
    this.initials,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  String get calculatedInitials {
    if (initials != null && initials!.isNotEmpty) return initials!;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'C';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed[0].toUpperCase();
  }

  String get clientSince {
    return DateFormat('MMM yyyy').format(createdAt);
  }

  CustomerEntity copyWith({
    String? id,
    String? ownerId,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? initials,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'businessId': businessId,
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email?.trim(),
      'avatarUrl': avatarUrl,
      'initials': initials,
      'notes': notes?.trim(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory CustomerEntity.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return CustomerEntity(
      id: docId ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      businessId: map['businessId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      initials: map['initials'] as String?,
      notes: map['notes'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
