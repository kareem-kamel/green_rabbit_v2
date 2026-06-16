import 'package:flutter/foundation.dart';

@immutable
abstract class ChangePasswordState {}

class ChangePasswordInitial extends ChangePasswordState {}

class ChangePasswordLoading extends ChangePasswordState {}

class ChangePasswordSuccess extends ChangePasswordState {}

class ChangePasswordError extends ChangePasswordState {
  final String message;
  final bool isOffline;
  ChangePasswordError(this.message, {this.isOffline = false});
}
