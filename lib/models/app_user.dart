import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, owner, admin }

UserRole roleFromString(String value) {
  switch (value.toLowerCase().trim()) {
    case 'admin':
      return UserRole.admin;
    case 'owner':
      return UserRole.owner;
    default:
      return UserRole.user;
  }
}

String roleToString(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return 'admin';
    case UserRole.owner:
      return 'owner';
    case UserRole.user:
      return 'user';
  }
}

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phone = '',
    required this.role,
    this.createdAt,
    this.updatedAt,
  });

  bool get isOwner => role == UserRole.owner;
  bool get isAdmin => role == UserRole.admin;
  bool get isBorrower => role == UserRole.user;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: roleFromString(data['role'] ?? 'user'),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'role': roleToString(role),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}