class CardTokenRequest {
  final String number;
  final String holderName;
  final String expMonth;
  final String expYear;
  final String cvv;

  CardTokenRequest({
    required this.number,
    required this.holderName,
    required this.expMonth,
    required this.expYear,
    required this.cvv,
  });

  Map<String, dynamic> toJson() {
    return {
      "number": number,
      "holder_name": holderName,
      "exp_month": expMonth,
      "exp_year": expYear,
      "cvv": cvv,
    };
  }
}