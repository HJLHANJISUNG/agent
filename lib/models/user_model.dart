class User {
  final String userId;
  final String username;
  final String email;
  final DateTime registerDate;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.registerDate,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['user_id'],
      username: map['username'],
      email: map['email'],
      registerDate: DateTime.parse(map['register_date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'register_date': registerDate.toIso8601String(),
    };
  }
}
