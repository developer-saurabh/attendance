class AppUser {
  final String uid;
  final String email;
  final String? name;
  final String role; // "master" or "faculty"

  AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'],
      role: data['role'] ?? 'faculty',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
    };
  }
}
