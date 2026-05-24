
abstract class AuthState {}

class AuthInitial extends AuthState {}

// Used when app first starts to check auth status
class AuthChecking extends AuthState {}

// Used when a login/register request is actively processing
class AuthLoading extends AuthState {}

class AuthFirstTime extends AuthState {}

// Emitted when a user has registered but needs to verify their email
class AuthNeedsVerification extends AuthState {}

// Emitted when a user has logged in successfully, but needs to complete the Preferences flow
class AuthNeedsPreferences extends AuthState {}

class AuthSuccess extends AuthState {
  // final UserModel user;
  // AuthSuccess({required this.user});
}


class AuthFailure extends AuthState {
  final String errorMessage;
  AuthFailure({required this.errorMessage});
}