/// Model đại diện cho người dùng trong hệ thống
class User {
  final int id;
  final String name;
  final String email;
  final String password; // SHA-256 hash
  final String? phone;
  final String? avatar; // local file path hoặc URL
  final String role; // 'user' | 'owner' | 'admin'
  final String createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.avatar,
    this.role = 'user',
    required this.createdAt,
  });

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get isUser => role == 'user';

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as int,
        name: map['name'] as String,
        email: map['email'] as String,
        password: map['password'] as String,
        phone: map['phone'] as String?,
        avatar: map['avatar'] as String?,
        role: (map['role'] as String?) ?? 'user',
        createdAt: map['created_at'] as String,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'avatar': avatar,
        'role': role,
        'created_at': createdAt,
      };

  factory User.fromFirestore(Map<String, dynamic> data) => User(
        id: data['id'] as int,
        name: data['name'] as String,
        email: data['email'] as String,
        password: data['password'] as String,
        phone: data['phone'] as String?,
        avatar: data['avatar'] as String?,
        role: (data['role'] as String?) ?? 'user',
        createdAt: data['createdAt'] as String,
      );

  Map<String, dynamic> toFirestore() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'avatar': avatar,
        'role': role,
        'createdAt': createdAt,
      };

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? phone,
    String? avatar,
    String? role,
    String? createdAt,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        phone: phone ?? this.phone,
        avatar: avatar ?? this.avatar,
        role: role ?? this.role,
        createdAt: createdAt ?? this.createdAt,
      );
}
