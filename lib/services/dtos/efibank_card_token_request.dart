class EfibankCardTokenRequest {
  final String number;
  final String holderName;
  final String expMonth;
  final String expYear;
  final String cvv;
  final String? brand;

  EfibankCardTokenRequest({
    required this.number,
    required this.holderName,
    required this.expMonth,
    required this.expYear,
    required this.cvv,
    this.brand,
  });

  Map<String, dynamic> toJson() {
    return {
      "number": number.replaceAll(' ', ''),
      "holder_name": holderName,
      "exp_month": expMonth,
      "exp_year": expYear.length == 2 ? '20$expYear' : expYear,
      "cvv": cvv,
      if (brand != null) "brand": brand,
    };
  }
}