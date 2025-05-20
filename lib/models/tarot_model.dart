class TarotCard {
  final String id;
  final String name;
  final String suit; // Arcano Maior, Espadas, Copas, Ouros, Paus
  final int number;
  final String imageUrl;
  final String uprightMeaning;
  final String reversedMeaning;
  final List<String> keywords;
  final String description;

  TarotCard({
    required this.id,
    required this.name,
    required this.suit,
    required this.number,
    required this.imageUrl,
    required this.uprightMeaning,
    required this.reversedMeaning,
    required this.keywords,
    required this.description,
  });

  factory TarotCard.fromMap(Map<String, dynamic> map, String docId) {
    return TarotCard(
      id: docId,
      name: map['name'] ?? '',
      suit: map['suit'] ?? '',
      number: map['number'] ?? 0,
      imageUrl: map['imageUrl'] ?? '',
      uprightMeaning: map['uprightMeaning'] ?? '',
      reversedMeaning: map['reversedMeaning'] ?? '',
      keywords: List<String>.from(map['keywords'] ?? []),
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'suit': suit,
      'number': number,
      'imageUrl': imageUrl,
      'uprightMeaning': uprightMeaning,
      'reversedMeaning': reversedMeaning,
      'keywords': keywords,
      'description': description,
    };
  }

  // Método para criar cópia com algumas propriedades alteradas
  TarotCard copyWith({
    String? name,
    String? suit,
    int? number,
    String? imageUrl,
    String? uprightMeaning,
    String? reversedMeaning,
    List<String>? keywords,
    String? description,
  }) {
    return TarotCard(
      id: id,
      name: name ?? this.name,
      suit: suit ?? this.suit,
      number: number ?? this.number,
      imageUrl: imageUrl ?? this.imageUrl,
      uprightMeaning: uprightMeaning ?? this.uprightMeaning,
      reversedMeaning: reversedMeaning ?? this.reversedMeaning,
      keywords: keywords ?? this.keywords,
      description: description ?? this.description,
    );
  }

  // Métodos de ajuda para identificar o tipo de carta
  bool get isMajorArcana => suit.toLowerCase().contains('maior');
  bool get isMinorArcana => !isMajorArcana;

  // Obter o elemento associado à carta (para arcanos menores)
  String get element {
    if (isMajorArcana) return 'N/A';

    switch (suit.toLowerCase()) {
      case 'espadas':
        return 'Ar';
      case 'copas':
        return 'Água';
      case 'ouros':
      case 'pentáculos':
        return 'Terra';
      case 'paus':
      case 'bastões':
        return 'Fogo';
      default:
        return 'Desconhecido';
    }
  }

  // Obter versão resumida do significado
  String getShortMeaning(bool isReversed) {
    final fullMeaning = isReversed ? reversedMeaning : uprightMeaning;

    // Se o significado for menor que 100 caracteres, retornar completo
    if (fullMeaning.length <= 100) {
      return fullMeaning;
    }

    // Caso contrário, retornar os primeiros 100 caracteres
    return '${fullMeaning.substring(0, 97)}...';
  }

  // Verificar se a carta contém a palavra-chave na pesquisa
  bool containsKeyword(String keyword) {
    final searchTerm = keyword.toLowerCase();

    return name.toLowerCase().contains(searchTerm) ||
        suit.toLowerCase().contains(searchTerm) ||
        uprightMeaning.toLowerCase().contains(searchTerm) ||
        reversedMeaning.toLowerCase().contains(searchTerm) ||
        keywords.any((k) => k.toLowerCase().contains(searchTerm)) ||
        description.toLowerCase().contains(searchTerm);
  }
}