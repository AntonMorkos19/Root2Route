class PaymentResultModel {
  final String redirectUrl;
  final String transactionReference;

  const PaymentResultModel({
    required this.redirectUrl,
    required this.transactionReference,
  });

  factory PaymentResultModel.fromJson(Map<String, dynamic> json) {
    return PaymentResultModel(
      redirectUrl: json['redirectUrl'] ?? '',
      transactionReference: json['transactionReference'] ?? '',
    );
  }
}

class PaymentVerifyModel {
  final String status;
  final String orderId;
  final double amount;
  final String paidAt;

  const PaymentVerifyModel({
    required this.status,
    required this.orderId,
    required this.amount,
    required this.paidAt,
  });

  factory PaymentVerifyModel.fromJson(Map<String, dynamic> json) {
    return PaymentVerifyModel(
      status: json['status'] ?? '',
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paidAt: json['paidAt'] ?? '',
    );
  }
}
