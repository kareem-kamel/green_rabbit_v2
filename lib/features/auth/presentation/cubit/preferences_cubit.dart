import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- STATE ---
class PreferencesState {
  final List<String> selectedInterests;
  final String experienceLevel;

  PreferencesState({
    this.selectedInterests = const [],
    this.experienceLevel = '',
  });

  PreferencesState copyWith({
    List<String>? selectedInterests,
    String? experienceLevel,
  }) {
    return PreferencesState(
      selectedInterests: selectedInterests ?? this.selectedInterests,
      experienceLevel: experienceLevel ?? this.experienceLevel,
    );
  }
}

// --- CUBIT ---
class PreferencesCubit extends Cubit<PreferencesState> {
  PreferencesCubit() : super(PreferencesState());

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
    // TODO: Call your API here using state.selectedInterests and state.experienceLevel
    debugPrint('=========================================');
    debugPrint('🚀 MOCK API CALL: SAVING USER PREFERENCES');
    debugPrint('📊 Selected Interests: ${state.selectedInterests}');
    debugPrint('🧠 Experience Level: ${state.experienceLevel}');
    debugPrint('=========================================');

    // 3. Simulate network delay (like we did for Sign Up)
    await Future.delayed(const Duration(seconds: 1));
  }
}