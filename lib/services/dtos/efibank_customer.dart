class EfibankCustomer {
  final String name;
  final String email;
  final String document;
  final String type; // individual ou company
  final String phone;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  EfibankCustomer({
    required this.name,
    required this.email,
    required this.document,
    required this.type,
    required this.phone,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country = 'BR',
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      "name": name,
      "email": email,
      "type": type,
      "document": document,
      "phone": {
        "country_code": "55",
        "area_code": phone.substring(0, 2),
        "number": phone.substring(2),
      },
    };

    // Adicionar endereço se disponível
    if (address != null || city != null || state != null || postalCode != null) {
      data["address"] = {
        if (address != null) "street": address,
        if (city != null) "city": city,
        if (state != null) "state": state,
        if (postalCode != null) "postal_code": postalCode,
        if (country != null) "country": country,
      };
    }

    return data;
  }
}