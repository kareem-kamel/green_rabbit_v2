import 'package:flutter_bloc/flutter_bloc.dart';
import 'alert_state.dart';

class AlertCubit extends Cubit<AlertState> {
  AlertCubit() : super(const AlertState());

  void updateTab(String tab) => emit(state.copyWith(selectedTab: tab));

  void updateCondition(String condition) {
    if (state.selectedTab == "Price") emit(state.copyWith(priceCondition: condition));
    else if (state.selectedTab == "Charge %") emit(state.copyWith(gainCondition: condition));
    else emit(state.copyWith(volumeCondition: condition));
  }

  void toggleEmail(bool value) => emit(state.copyWith(emailNotification: value));
  void toggleRecurring(bool value) => emit(state.copyWith(recurringAlert: value));
  void toggleReminder(bool value) => emit(state.copyWith(tradingReminder: value));
}