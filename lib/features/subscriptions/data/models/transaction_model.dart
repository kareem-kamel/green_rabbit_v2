class TransactionModel {
  final String id;
  final String planName;
  final DateTime date;
  final double amount;
  final String status;
  final String paymentMethod;
  final String transactionId;
  final double discount;

  TransactionModel({
    required this.id,
    required this.planName,
    required this.date,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.transactionId,
    this.discount = 0.0,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      planName: json['planName'] ?? '',
      date: DateTime.parse(json['date']),
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      transactionId: json['transactionId'] ?? '',
      discount: (json['discount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'date': date.toIso8601String(),
      'amount': amount,
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'discount': discount,
    };
  }
}
