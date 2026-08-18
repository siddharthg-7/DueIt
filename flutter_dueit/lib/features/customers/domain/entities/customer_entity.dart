class CustomerEntity {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String? initials;
  final String? notes;
  final String clientSince;
  final String createdAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.avatarUrl,
    this.initials,
    this.notes,
    required this.clientSince,
    required this.createdAt,
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

  CustomerEntity copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
    String? initials,
    String? notes,
    String? clientSince,
    String? createdAt,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      initials: initials ?? this.initials,
      notes: notes ?? this.notes,
      clientSince: clientSince ?? this.clientSince,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
