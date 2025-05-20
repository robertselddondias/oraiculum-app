class PagarmeCreditCardPaymentModel {
  final int amountInCents;
  final String cardToken;
  final String customerId;
  final int installments;
  final bool capture;

  PagarmeCreditCardPaymentModel({
    required this.amountInCents,
    required this.cardToken,
    required this.customerId,
    this.installments = 1,
    this.capture = true,
  });

  Map<String, dynamic> toJson() {
    return {
      "amount": amountInCents,
      "customer_id": customerId,
      "payments": [
        {
          "payment_method": "credit_card",
          "credit_card": {
            "installments": installments,
            "statement_descriptor": "FLUTTERPAGAMENTO",
            "card_id": cardToken,
            "capture": capture,
          }
        }
      ],
      "items": [
        {
          "description": "Compra no Flutter",
          "quantity": 1,
          "amount": amountInCents,
        }
      ]
    };
  }
}