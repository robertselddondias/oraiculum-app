import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime birthDate;
  final String? profileImageUrl;
  final List<String> favoriteReadings;
  final List<String> favoriteReaders;
  final double credits;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final String? gender;
  final bool registrationCompleted;
  final String? loginProvider;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.birthDate,
    this.profileImageUrl,
    required this.favoriteReadings,
    required this.favoriteReaders,
    required this.credits,
    required this.createdAt,
    this.lastLogin,
    this.gender,
    required this.registrationCompleted,
    this.loginProvider,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      birthDate: (map['birthDate'] as Timestamp).toDate(),
      profileImageUrl: map['profileImageUrl'],
      favoriteReadings: List<String>.from(map['favoriteReadings'] ?? []),
      favoriteReaders: List<String>.from(map['favoriteReaders'] ?? []),
      credits: (map['credits'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as Timestamp).toDate()
          : null,
      gender: map['gender'],
      registrationCompleted: map['registrationCompleted'] ?? false,
      loginProvider: map['loginProvider'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'birthDate': Timestamp.fromDate(birthDate),
      'profileImageUrl': profileImageUrl,
      'favoriteReadings': favoriteReadings,
      'favoriteReaders': favoriteReaders,
      'credits': credits,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'gender': gender,
      'registrationCompleted': registrationCompleted,
      'loginProvider': loginProvider,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    DateTime? birthDate,
    String? profileImageUrl,
    List<String>? favoriteReadings,
    List<String>? favoriteReaders,
    double? credits,
    DateTime? lastLogin,
    String? gender,
    bool? registrationCompleted,
    String? loginProvider,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      favoriteReadings: favoriteReadings ?? this.favoriteReadings,
      favoriteReaders: favoriteReaders ?? this.favoriteReaders,
      credits: credits ?? this.credits,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      gender: gender ?? this.gender,
      registrationCompleted: registrationCompleted ?? this.registrationCompleted,
      loginProvider: loginProvider ?? this.loginProvider,
    );
  }

  // Métodos de conveniência

  /// Retorna a idade do usuário baseada na data de nascimento
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Retorna o signo zodiacal baseado na data de nascimento
  String get zodiacSign {
    final day = birthDate.day;
    final month = birthDate.month;

    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquário';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Peixes';
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Áries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Touro';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gêmeos';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Câncer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leão';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgem';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Escorpião';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagitário';

    return 'Capricórnio';
  }

  /// Retorna um texto amigável para o gênero
  String get genderDisplay {
    switch (gender?.toLowerCase()) {
      case 'masculino':
        return 'Masculino';
      case 'feminino':
        return 'Feminino';
      case 'outros':
        return 'Outros';
      default:
        return 'Não informado';
    }
  }

  /// Verifica se o usuário é maior de idade
  bool get isAdult {
    return age >= 18;
  }

  /// Retorna o primeiro nome do usuário
  String get firstName {
    return name.split(' ').first;
  }

  /// Retorna as iniciais do nome do usuário
  String get initials {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '?';

    if (nameParts.length == 1) {
      return nameParts[0].isNotEmpty ? nameParts[0][0].toUpperCase() : '?';
    }

    final firstInitial = nameParts[0].isNotEmpty ? nameParts[0][0] : '';
    final lastInitial = nameParts[nameParts.length - 1].isNotEmpty
        ? nameParts[nameParts.length - 1][0]
        : '';

    return (firstInitial + lastInitial).toUpperCase();
  }

  /// Verifica se o perfil está completo
  bool get isProfileComplete {
    return registrationCompleted &&
        name.isNotEmpty &&
        email.isNotEmpty &&
        gender != null;
  }

  /// Retorna a porcentagem de completude do perfil
  double get profileCompleteness {
    int completedFields = 0;
    int totalFields = 5; // name, email, birthDate, gender, profileImage

    if (name.isNotEmpty) completedFields++;
    if (email.isNotEmpty) completedFields++;
    if (gender != null && gender!.isNotEmpty) completedFields++;
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) completedFields++;
    completedFields++; // birthDate sempre existe

    return completedFields / totalFields;
  }

  /// Retorna os campos que ainda precisam ser preenchidos
  List<String> get missingFields {
    final missing = <String>[];

    if (name.isEmpty) missing.add('Nome');
    if (email.isEmpty) missing.add('Email');
    if (gender == null || gender!.isEmpty) missing.add('Gênero');
    if (profileImageUrl == null || profileImageUrl!.isEmpty) missing.add('Foto de perfil');
    if (!registrationCompleted) missing.add('Completar cadastro');

    return missing;
  }

  /// Verifica se o usuário pode receber notificações personalizadas
  bool get canReceivePersonalizedContent {
    return registrationCompleted && gender != null;
  }

  /// Retorna uma saudação personalizada baseada no horário
  String getPersonalizedGreeting() {
    final hour = DateTime.now().hour;
    final firstName = this.firstName;

    String greeting;
    if (hour < 12) {
      greeting = 'Bom dia';
    } else if (hour < 18) {
      greeting = 'Boa tarde';
    } else {
      greeting = 'Boa noite';
    }

    return '$greeting, $firstName!';
  }

  /// Retorna informações de debug úteis
  Map<String, dynamic> get debugInfo {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'zodiacSign': zodiacSign,
      'gender': genderDisplay,
      'registrationCompleted': registrationCompleted,
      'loginProvider': loginProvider,
      'profileCompleteness': '${(profileCompleteness * 100).toInt()}%',
      'missingFields': missingFields,
      'credits': credits,
      'isAdult': isAdult,
      'canReceivePersonalizedContent': canReceivePersonalizedContent,
    };
  }

  /// Valida se os dados básicos do usuário estão corretos
  List<String> validate() {
    final errors = <String>[];

    if (name.trim().length < 2) {
      errors.add('Nome deve ter pelo menos 2 caracteres');
    }

    if (!email.contains('@') || !email.contains('.')) {
      errors.add('Email deve ter um formato válido');
    }

    if (age < 13) {
      errors.add('Usuário deve ter pelo menos 13 anos');
    }

    if (age > 120) {
      errors.add('Data de nascimento parece incorreta');
    }

    if (credits < 0) {
      errors.add('Créditos não podem ser negativos');
    }

    return errors;
  }

  /// Converte para JSON string para logging
  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, email: $email, age: $age, '
        'zodiacSign: $zodiacSign, gender: $genderDisplay, '
        'registrationCompleted: $registrationCompleted, '
        'loginProvider: $loginProvider, credits: $credits)';
  }

  /// Operador de igualdade
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.birthDate == birthDate &&
        other.gender == gender &&
        other.registrationCompleted == registrationCompleted;
  }

  /// Hash code
  @override
  int get hashCode {
    return id.hashCode ^
    name.hashCode ^
    email.hashCode ^
    birthDate.hashCode ^
    gender.hashCode ^
    registrationCompleted.hashCode;
  }
}