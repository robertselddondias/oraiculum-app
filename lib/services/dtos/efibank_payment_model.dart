class EfibankPaymentModel {
  final int amountInCents;
  final String customerId;
  final String orderId;
  final String description;
  final String paymentMethod; // credit_card, debit_card, pix
  final String? cardId;
  final int? installments;
  final bool? capture;
  final int? pixExpirationMinutes;

  EfibankPaymentModel({
    required this.amountInCents,
    required this.customerId,
    required this.orderId,
    required this.description,
    required this.paymentMethod,
    this.cardId,
    this.installments = 1,
    this.capture = true,
    this.pixExpirationMinutes = 30,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "customer_id": customerId,
      "order_id": orderId,
      "items": [
        {
          "amount": amountInCents,
          "description": description,
          "quantity": 1,
          "code": orderId,
        }
      ],
      "payment": {
        "payment_method": paymentMethod,
        "amount": amountInCents,
      }
    };

    // Adicionar campos específicos para cada método de pagamento
    if (paymentMethod == 'credit_card' && cardId != null) {
      data["payment"]["credit_card"] = {
        "card_id": cardId,
        "installments": installments,
        "capture": capture,
      };
    } else if (paymentMethod == 'debit_card' && cardId != null) {
      data["payment"]["debit_card"] = {
        "card_id": cardId,
      };
    } else if (paymentMethod == 'pix') {
      data["payment"]["pix"] = {
        "expires_in": pixExpirationMinutes! * 60, // Conversão para segundos
      };
    }

    return data;
  }
}