import 'user_role.dart';

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String firstName;
  final String lastName;
  final UserRole role;
  final String? businessName;
  final String? businessAddress;
  final List<String> outletIds;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.email,
    this.phone,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.businessName,
    this.businessAddress,
    this.outletIds = const [],
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isOwner => role == UserRole.owner;
  bool get isBasic => role == UserRole.basic;
  bool get hasMultipleOutlets => outletIds.length > 1;
  String get displayName => '$firstName $lastName'.trim();

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? firstName,
    String? lastName,
    UserRole? role,
    String? businessName,
    String? businessAddress,
    List<String>? outletIds,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      outletIds: outletIds ?? this.outletIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'phone': phone,
        'firstName': firstName,
        'lastName': lastName,
        'role': role.key,
        'businessName': businessName,
        'businessAddress': businessAddress,
        'outletIds': outletIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        role: UserRole.fromString(json['role'] as String? ?? 'basic'),
        businessName: json['businessName'] as String?,
        businessAddress: json['businessAddress'] as String?,
        outletIds: (json['outletIds'] as List?)?.cast<String>() ?? const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}