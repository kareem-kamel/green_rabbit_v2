import 'package:equatable/equatable.dart';

class AlertState extends Equatable {
  final String selectedTab;
  final String priceCondition;
  final String gainCondition;
  final String volumeCondition;
  final bool emailNotification;
  final bool recurringAlert;
  final bool tradingReminder;

  const AlertState({
    this.selectedTab = "Price",
    this.priceCondition = "Move Above",
    this.gainCondition = "Gain",
    this.volumeCondition = "Exceeds",
    this.emailNotification = true,
    this.recurringAlert = false,
    this.tradingReminder = false,
  });

  AlertState copyWith({
    String? selectedTab,
    String? priceCondition,
    String? gainCondition,
    String? volumeCondition,
    bool? emailNotification,
    bool? recurringAlert,
    bool? tradingReminder,
  }) {
    return AlertState(
      selectedTab: selectedTab ?? this.selectedTab,
      priceCondition: priceCondition ?? this.priceCondition,
      gainCondition: gainCondition ?? this.gainCondition,
      volumeCondition: volumeCondition ?? this.volumeCondition,
      emailNotification: emailNotification ?? this.emailNotification,
      recurringAlert: recurringAlert ?? this.recurringAlert,
      tradingReminder: tradingReminder ?? this.tradingReminder,
    );
  }

  @override
  List<Object> get props => [
        selectedTab,
        priceCondition,
        gainCondition,
        volumeCondition,
        emailNotification,
        recurringAlert,
        tradingReminder,
      ];
}