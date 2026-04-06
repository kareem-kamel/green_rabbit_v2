import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool notificationsEnabled;
  final bool lightModeEnabled;
  final bool preventScreenAwake;
  final bool aiAlertsEnabled;
  final bool appLockEnabled;
  final bool rememberPassword;
  final String alertFrequency; // Instant, Digest, Important
  final String currency;

  SettingsState({
    this.notificationsEnabled = true,
    this.lightModeEnabled = false,
    this.preventScreenAwake = false,
    this.aiAlertsEnabled = true,
    this.appLockEnabled = false,
    this.rememberPassword = true,
    this.alertFrequency = 'Instant (Real-time)',
    this.currency = 'USD',
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? lightModeEnabled,
    bool? preventScreenAwake,
    bool? aiAlertsEnabled,
    bool? appLockEnabled,
    bool? rememberPassword,
    String? alertFrequency,
    String? currency,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lightModeEnabled: lightModeEnabled ?? this.lightModeEnabled,
      preventScreenAwake: preventScreenAwake ?? this.preventScreenAwake,
      aiAlertsEnabled: aiAlertsEnabled ?? this.aiAlertsEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      rememberPassword: rememberPassword ?? this.rememberPassword,
      alertFrequency: alertFrequency ?? this.alertFrequency,
      currency: currency ?? this.currency,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    emit(state.copyWith(
      notificationsEnabled: prefs.getBool('notificationsEnabled') ?? true,
      lightModeEnabled: prefs.getBool('lightModeEnabled') ?? false,
      preventScreenAwake: prefs.getBool('preventScreenAwake') ?? false,
      aiAlertsEnabled: prefs.getBool('aiAlertsEnabled') ?? true,
      appLockEnabled: prefs.getBool('appLockEnabled') ?? false,
      rememberPassword: prefs.getBool('rememberPassword') ?? true,
      alertFrequency: prefs.getString('alertFrequency') ?? 'Instant (Real-time)',
      currency: prefs.getString('currency') ?? 'USD',
    ));
  }

  Future<void> toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', value);
    emit(state.copyWith(notificationsEnabled: value));
  }

  Future<void> toggleLightMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lightModeEnabled', value);
    emit(state.copyWith(lightModeEnabled: value));
  }

  Future<void> togglePreventScreenAwake(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preventScreenAwake', value);
    emit(state.copyWith(preventScreenAwake: value));
  }

  Future<void> toggleAiAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('aiAlertsEnabled', value);
    emit(state.copyWith(aiAlertsEnabled: value));
  }

  Future<void> toggleAppLock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('appLockEnabled', value);
    emit(state.copyWith(appLockEnabled: value));
  }

  Future<void> toggleRememberPassword(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberPassword', value);
    emit(state.copyWith(rememberPassword: value));
  }

  Future<void> setAlertFrequency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('alertFrequency', value);
    emit(state.copyWith(alertFrequency: value));
  }

  Future<void> setCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', value);
    emit(state.copyWith(currency: value));
  }
}
