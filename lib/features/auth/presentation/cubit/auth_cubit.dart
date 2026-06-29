import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

<<<<<<< Updated upstream
=======
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // iOS OAuth 2.0 client ID (client_type 2, ios_info bundle: com.greenrabbit.app)
    clientId:
        '963276687646-g6htuquf3okdg29auu9qe0cj2uhefpt7.apps.googleusercontent.com',
    // Web/server OAuth 2.0 client ID (client_type 3) — needed to get an idToken
    serverClientId:
        '963276687646-9ijmelnsmq6752a0fr64lk6q05l9sgoa.apps.googleusercontent.com',
  );

>>>>>>> Stashed changes
  AuthCubit({required this.repository}) : super(AuthInitial());
  Future<void> register({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    emit(AuthLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      // final user = await repository.register(
      //   email: email, 
      //   password: password, 
      //   confirmPassword: confirmPassword,
      // );
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    // 1. Tell UI to show loading spinner
    emit(AuthLoading());
    debugPrint('🚀 MOCK API CALL: Logging in $email');

    try {
      // 2. Try to log in via repository
      // final user = await repository.login(
      //   email: email, 
      //   password: password, 
      //   rememberMe: rememberMe,
      // );
      await Future.delayed(const Duration(seconds: 2));
      
      // 3. Mock Test Validation
      if (email.trim() == 'Ahmed@gamil.com' && password == '123456') {
        emit(AuthSuccess()); // Success!
      } else {
        emit(AuthFailure(errorMessage: "Invalid email or password."));
      }
      
      // 3. Tell UI it was a success!
      // emit(AuthSuccess());
    } catch (e) {
      // 4. Tell UI it failed, and pass the error message (removing the "Exception:" text)
      emit(AuthFailure(errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }

  void logout() {
    repository.logout();
    emit(AuthInitial());
  }
}