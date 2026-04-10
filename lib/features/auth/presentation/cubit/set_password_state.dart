abstract class SetPasswordState {}

class SetPasswordInitial extends SetPasswordState {}

class SetPasswordLoading extends SetPasswordState {}

class SetPasswordSuccess extends SetPasswordState {}

class SetPasswordError extends SetPasswordState {
  final String message;
  SetPasswordError(this.message);
}