class User {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final bool isSecOpsAdmin;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'Security Analyst',
    this.avatarUrl,
    this.isSecOpsAdmin = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? 'usr_default',
      name: json['name'] as String? ?? 'Security Officer',
      email: json['email'] as String? ?? 'officer@scamshield.io',
      role: json['role'] as String? ?? 'SecOps Lead',
      avatarUrl: json['avatar_url'] as String?,
      isSecOpsAdmin: json['is_secops_admin'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'avatar_url': avatarUrl,
    'is_secops_admin': isSecOpsAdmin,
  };
}
