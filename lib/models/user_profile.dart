import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { user, admin, banned }

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String department;
  final int year;
  final String? photoUrl;
  final String? bio;
  final DateTime createdAt;
  final UserRole role;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.department,
    required this.year,
    this.photoUrl,
    this.bio,
    required this.createdAt,
    this.role = UserRole.user,
  });

  // 🧠 Validation
  bool get isValidEmail => email.endsWith('@iitism.ac.in');
  bool get isAdmin => role == UserRole.admin;
  bool get isBanned => role == UserRole.banned;
  bool get isActive => role == UserRole.user || role == UserRole.admin;

  // 🧾 Convert to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': uid,
      'name': name,
      'email': email,
      'department': department,
      'year': year,
      'photo_url': photoUrl,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
      'role': role.name,
    };
  }

  // 🧩 Create from Supabase record
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['id'] as String,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      department: json['department'] ?? '',
      year: json['year'] ?? 1,
      photoUrl: json['photo_url'],
      bio: json['bio'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      role: UserRole.values.firstWhere(
        (e) => e.name == (json['role'] ?? 'user'),
        orElse: () => UserRole.user,
      ),
    );
  }

  // 🛠 Copy with method
  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? department,
    int? year,
    String? photoUrl,
    String? bio,
    DateTime? createdAt,
    UserRole? role,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      year: year ?? this.year,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }

  @override
  String toString() {
    return 'UserProfile(uid: $uid, name: $name, email: $email, dept: $department, year: $year, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.uid == uid &&
        other.name == name &&
        other.email == email &&
        other.department == department &&
        other.year == year &&
        other.photoUrl == photoUrl &&
        other.bio == bio &&
        other.createdAt == createdAt &&
        other.role == role;
  }

  @override
  int get hashCode =>
      Object.hash(uid, name, email, department, year, photoUrl, bio, createdAt, role);
}

// 🧱 Seller Info (for showing in items)
class SellerInfo {
  final String name;
  final String dept;
  final int year;

  const SellerInfo({
    required this.name,
    required this.dept,
    required this.year,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dept': dept,
      'year': year,
    };
  }

  factory SellerInfo.fromJson(Map<String, dynamic> json) {
    return SellerInfo(
      name: json['name'] ?? '',
      dept: json['dept'] ?? '',
      year: json['year'] ?? 1,
    );
  }

  factory SellerInfo.fromUserProfile(UserProfile profile) {
    return SellerInfo(
      name: profile.name,
      dept: profile.department,
      year: profile.year,
    );
  }

  @override
  String toString() => 'SellerInfo(name: $name, dept: $dept, year: $year)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SellerInfo &&
        other.name == name &&
        other.dept == dept &&
        other.year == year;
  }

  @override
  int get hashCode => Object.hash(name, dept, year);
}
