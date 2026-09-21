enum UserRole { user, owner }

UserRole roleFromString(String value) {
  return value == 'owner' ? UserRole.owner : UserRole.user;
}

String roleToString(UserRole role) {
  return role == UserRole.owner ? 'owner' : 'user';
}

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isOwner => role == UserRole.owner;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: roleFromString(data['role'] ?? 'user'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': roleToString(role),
    };
  }
}