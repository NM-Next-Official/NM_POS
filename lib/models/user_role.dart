enum UserRole {
  admin,
  owner,
  basic;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value.toLowerCase(),
      orElse: () => UserRole.basic,
    );
  }

  String get key => name;
}