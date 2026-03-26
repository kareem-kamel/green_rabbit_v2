import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart'; // We'll create this next

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoggedIn extends AuthState {
  final UserEntity user;
  const AuthLoggedIn(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthLoggedOut extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
