class User {
  final int id;
  final String name;
  final String email;
  final String role;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json["User_id"],
      name: json["User_name"],
      email: json["User_mail"],
      role: json["Role_name"],
    );
  }
}
