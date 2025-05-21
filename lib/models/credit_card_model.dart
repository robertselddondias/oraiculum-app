class CreditCardUserModel {

  String? id;
  String? cardHolderName;
  String? cardAliasName;

  String? customerId;
  String? lastFourDigits;
  String? transationalType;
  String? brandType;
  String? expirationDate;
  String? userId;
  String? cardId;
  String? cvv;
  DateTime? createdAt;
  bool? isDefault;

  String? email;
  String? cpf;
  String? birthDate;
  String? phone;

  CreditCardUserModel({
    this.id,
    this.cardHolderName,
    this.customerId,
    this.lastFourDigits,
    this.transationalType,
    this.brandType,
    this.expirationDate,
    this.userId,
    this.cardId,
    this.cardAliasName,
    this.cvv,
    this.createdAt,
    this.isDefault,
    this.phone,
    this.email,
    this.birthDate,
    this.cpf
  });

  CreditCardUserModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cardHolderName = json['cardName'];
    customerId = json['customerId'];
    lastFourDigits = json['lastFourDigits'];
    transationalType = json['transationalType'];
    brandType = json['cardType'];
    expirationDate = json['expirationDate'];
    userId = json['userId'];
    cardId = json['cardId'];
    cvv = json['cvv'];
    cardAliasName = json['cardAliasName'];
    createdAt = json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null;
    isDefault = json['isDefault'];

    phone = json['phone'];
    email = json['email'];
    birthDate = json['birthDate'];
    cpf = json['cpf'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['cardName'] = cardHolderName;
    data['customerId'] = customerId;
    data['lastFourDigits'] = lastFourDigits;
    data['transationalType'] = transationalType;
    data['cardType'] = brandType;
    data['expirationDate'] = expirationDate;
    data['userId'] = userId;
    data['cardId'] = cardId;
    data['cardAliasName'] = cardAliasName;
    data['cvv'] = cvv;
    data['createdAt'] = DateTime.now().toIso8601String();
    data['isDefault'] = isDefault;

    data['phone'] = phone;
    data['email'] = email;
    data['birthDate'] = birthDate;
    data['cpf'] = cpf;
    return data;
  }
}
