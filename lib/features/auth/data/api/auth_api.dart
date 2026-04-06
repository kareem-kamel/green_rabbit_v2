class AuthApi {

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    // Fake network delay
    await Future.delayed(const Duration(seconds: 2));

    // Basic validation
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      throw Exception('All fields are required.');
    }
    if (password != confirmPassword) {
      throw Exception('Passwords do not match.');
    }

    // Fake Success Response
    return {
      'message': 'Registration Successful',
      'email': email,
      'token': 'fake_jwt_token_new_user',
    };
  }
  // Fake network call based on the JSON you provided
  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    // 1. Simulate network delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 2. Simulate basic validation rules
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password cannot be empty.');
    }

    // 3. Fake success/failure (let's say password must be "123456" for testing)
    if (password == '123456') {
      // Fake Success Response
      return {
        'message': 'Login Successful',
        'email': email,
        'token': 'fake_jwt_token_8829301_abc',
      };
    } else {
      // Fake Error Response
      throw Exception('Invalid email or password.');
    }
  }
}