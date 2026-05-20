
abstract class AuthState {}

class AuthInitial extends AuthState {}

// Used when app first starts to check auth status
class AuthChecking extends AuthState {}

// Used when a login/register request is actively processing
class AuthLoading extends AuthState {}

class AuthFirstTime extends AuthState {}

class AuthSuccess extends AuthState {
  // final UserModel user;
  // AuthSuccess({required this.user});
}


class AuthFailure extends AuthState {
  final String errorMessage;
  AuthFailure({required this.errorMessage});
}