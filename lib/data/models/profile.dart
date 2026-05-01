// lib/data/models/profile.dart

class Profile {
  final String id;
  final String role; // 'admin' | 'staff'
  final String fullName;

  const Profile({
    required this.id,
    required this.role,
    required this.fullName,
  });

  bool get isAdmin => role == 'admin';

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id:       json['id'] as String,
        role:     json['role'] as String,
        fullName: json['full_name'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id':        id,
        'role':      role,
        'full_name': fullName,
      };
}
