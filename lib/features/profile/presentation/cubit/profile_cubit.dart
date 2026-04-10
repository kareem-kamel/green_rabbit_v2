import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileState {
  final String name;
  final String email;
  final String phone;
  final String countryName;
  final String countryFlag;
  final String avatarUrl;

  ProfileState({
    this.name = 'Mahmoud Ali',
    this.email = 'Content@gamil.com',
    this.phone = '+201287659400',
    this.countryName = 'Egypt',
    this.countryFlag = '🇪🇬',
    this.avatarUrl = 'https://i.pravatar.cc/150?u=mahmoud',
  });

  ProfileState copyWith({
    String? name,
    String? email,
    String? phone,
    String? countryName,
    String? countryFlag,
    String? avatarUrl,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      countryName: countryName ?? this.countryName,
      countryFlag: countryFlag ?? this.countryFlag,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileState());

  void updateProfile({
    String? name,
    String? email,
    String? phone,
    String? countryName,
    String? countryFlag,
    String? avatarUrl,
  }) {
    emit(state.copyWith(
      name: name,
      email: email,
      phone: phone,
      countryName: countryName,
      countryFlag: countryFlag,
      avatarUrl: avatarUrl,
    ));
  }
}
