class UserModel {
  final String token;
  final String username;
  final String email;
  final String role;

  const UserModel({
    required this.token,
    required this.username,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    token:    json['token']    as String,
    username: json['username'] as String,
    email:    json['email']    as String,
    role:     json['role']     as String,
  );

  Map<String, dynamic> toJson() => {
    'token':    token,
    'username': username,
    'email':    email,
    'role':     role,
  };
}
