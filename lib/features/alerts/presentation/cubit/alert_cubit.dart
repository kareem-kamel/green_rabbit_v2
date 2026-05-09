import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repository/alert_repository.dart';
import '../../data/models/alert_model.dart';
import 'alert_state.dart';

class AlertCubit extends Cubit<AlertState> {
  final AlertRepository repository;

  AlertCubit({required this.repository}) : super(const AlertState());

  void updateTab(String tab) => emit(state.copyWith(selectedTab: tab));

  void updateCondition(String condition) {
    if (state.selectedTab == "Price") {
      emit(state.copyWith(priceCondition: condition));
    } else if (state.selectedTab == "Charge %") emit(state.copyWith(gainCondition: condition));
    else emit(state.copyWith(volumeCondition: condition));
  }

  void toggleEmail(bool value) => emit(state.copyWith(emailNotification: value));
  void toggleRecurring(bool value) => emit(state.copyWith(recurringAlert: value));
  void toggleReminder(bool value) => emit(state.copyWith(tradingReminder: value));

  Future<void> fetchAlerts() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final alerts = await repository.fetchAlerts();
      emit(state.copyWith(isLoading: false, alerts: alerts));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> createAlert(String instrumentId, double targetPrice, String type, {DateTime? expiresAt}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final alertData = {
        "instrumentId": instrumentId,
        "targetPrice": targetPrice,
        "type": type,
      };
      if (expiresAt != null) {
        alertData["expiresAt"] = expiresAt.toIso8601String();
      }
      
      final newAlert = await repository.createAlert(alertData);
      if (newAlert != null) {
        emit(state.copyWith(
          isLoading: false,
          alerts: [newAlert, ...state.alerts],
        ));
      } else {
        emit(state.copyWith(isLoading: false, error: 'Failed to create alert'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> deleteAlert(String id) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final success = await repository.deleteAlert(id);
      if (success) {
        emit(state.copyWith(
          isLoading: false,
          alerts: state.alerts.where((a) => a.id != id).toList(),
        ));
      } else {
        emit(state.copyWith(isLoading: false, error: 'Failed to delete alert'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}