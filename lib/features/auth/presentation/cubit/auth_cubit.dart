import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  // Check current auth status on app start
  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      // TODO: Implement actual check using repository
      await Future.delayed(const Duration(seconds: 2));
      emit(AuthLoggedOut());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      // TODO: Implement login
      // emit(AuthLoggedIn(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    // TODO: Implement logout
    emit(AuthLoggedOut());
  }
}
