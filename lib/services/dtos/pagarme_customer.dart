class PagarmeCustomer {
  final String name;
  final String email;
  final String document;
  final String type; // individual ou company
  final String phone;

  PagarmeCustomer({
    required this.name,
    required this.email,
    required this.document,
    required this.type,
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "email": email,
      "type": type,
      "document": document,
      "phones": {
        "mobile_phone": {
          "country_code": "55",
          "number": phone,
          "area_code": phone.substring(0, 2)
        }
      }
    };
  }
}