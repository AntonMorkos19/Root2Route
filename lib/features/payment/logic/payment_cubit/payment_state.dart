abstract class PaymentState {
  const PaymentState();
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentWebViewReady extends PaymentState {
  final String redirectUrl;
  final String transactionReference;

  const PaymentWebViewReady({
    required this.redirectUrl,
    required this.transactionReference,
  });
}

class PaymentVerifying extends PaymentState {
  const PaymentVerifying();
}

class PaymentCaptured extends PaymentState {
  const PaymentCaptured();
}

class PaymentFailed extends PaymentState {
  final String message;

  const PaymentFailed(this.message);
}
