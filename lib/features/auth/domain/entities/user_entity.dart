import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String? avatarUrl;
  final String tier;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatarUrl,
    required this.tier,
  });

  @override
  List<Object?> get props => [id, fullName, email, avatarUrl, tier];
}
