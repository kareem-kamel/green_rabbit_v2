import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:green_rabbit/features/auth/data/repository/auth_repository.dart';

enum PreferencesStatus { initial, loading, success, error }

// --- STATE ---
class PreferencesState {
  final List<String> selectedInterests;
  final String experienceLevel;
  final PreferencesStatus status;
  final String? errorMessage;

  PreferencesState({
    this.selectedInterests = const [],
    this.experienceLevel = '',
    this.status = PreferencesStatus.initial,
    this.errorMessage,
  });

  PreferencesState copyWith({
    List<String>? selectedInterests,
    String? experienceLevel,
    PreferencesStatus? status,
    String? errorMessage,
  }) {
    return PreferencesState(
      selectedInterests: selectedInterests ?? this.selectedInterests,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// --- CUBIT ---
class PreferencesCubit extends Cubit<PreferencesState> {
  final AuthRepository repository;

  PreferencesCubit({required this.repository}) : super(PreferencesState());

  // Toggles an interest on or off (Multiple Selection)
  void toggleInterest(String interest) {
    final currentList = List<String>.from(state.selectedInterests);
    if (currentList.contains(interest)) {
      currentList.remove(interest); // Deselect
    } else {
      currentList.add(interest); // Select
    }
    emit(state.copyWith(selectedInterests: currentList));
  }

  // Sets the experience level (Single Selection)
  void setExperience(String level) {
    emit(state.copyWith(experienceLevel: level));
  }

  // The final method to send data to your API
  Future<void> savePreferences() async {
    if (state.experienceLevel.isEmpty || state.selectedInterests.isEmpty) {
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: "Please select your preferences."));
      return;
    }

    emit(state.copyWith(status: PreferencesStatus.loading, errorMessage: null));

    debugPrint('=========================================');
    debugPrint('🚀 REAL API CALL: SAVING USER PREFERENCES');
    debugPrint('📊 Selected Interests: ${state.selectedInterests}');
    debugPrint('🧠 Experience Level: ${state.experienceLevel}');
    debugPrint('=========================================');

    try {
      await repository.saveUserOnboarding(
        experienceLevel: state.experienceLevel,
        interestedIn: state.selectedInterests,
      );
      
      emit(state.copyWith(status: PreferencesStatus.success));
    } catch (e) {
      emit(state.copyWith(status: PreferencesStatus.error, errorMessage: e.toString().replaceAll('Exception: ', '')));
    }
  }
}