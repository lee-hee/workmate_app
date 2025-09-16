class User {
  const User({required this.id, required this.name, required this.role});
  final int id;
  final String name;
  final String role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      role: json['role'],
    );
  }
}
