import '../api/auth_api.dart';
import '../models/user_model.dart';

class AuthRepository {

  final AuthApi api;

  AuthRepository({required this.api});
  Future<UserModel> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await api.registerUser(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      return UserModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      // Call the fake API
      final response = await api.loginUser(
        email: email, 
        password: password, 
        rememberMe: rememberMe,
      );
      
      // Convert JSON Map into our Dart UserModel
      return UserModel.fromJson(response);
    } catch (e) {
      // Pass the error up to the Cubit
      rethrow; 
    }
  }
}