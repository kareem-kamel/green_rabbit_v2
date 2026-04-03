class UserModel {
  final String email;
  final String token; // The fake access token

  UserModel({required this.email, required this.token});

  // Later, we will use this to parse real backend data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      email: json['email'] ?? '',
      token: json['token'] ?? '',
    );
  }
}