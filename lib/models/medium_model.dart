class MediumModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> specialties;
  final double rating;
  final int reviewsCount;
  final double pricePerMinute;
  final bool isActive;
  final bool isAvailable;
  final Map<String, dynamic> availability;
  final String biography;
  final int yearsOfExperience;
  final List<String> languages;

  MediumModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.specialties,
    required this.rating,
    required this.reviewsCount,
    required this.pricePerMinute,
    required this.isActive,
    required this.isAvailable,
    required this.availability,
    required this.biography,
    required this.yearsOfExperience,
    required this.languages,
  });

  factory MediumModel.fromMap(Map<String, dynamic> map, String id) {
    return MediumModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      specialties: List<String>.from(map['specialties'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewsCount: map['reviewsCount'] ?? 0,
      pricePerMinute: (map['pricePerMinute'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? false,
      isAvailable: map['isAvailable'] ?? false,
      availability: Map<String, dynamic>.from(map['availability'] ?? {}),
      biography: map['biography'] ?? '',
      yearsOfExperience: map['yearsOfExperience'] ?? 0,
      languages: List<String>.from(map['languages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'specialties': specialties,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'pricePerMinute': pricePerMinute,
      'isActive': isActive,
      'isAvailable': isAvailable,
      'availability': availability,
      'biography': biography,
      'yearsOfExperience': yearsOfExperience,
      'languages': languages,
    };
  }
}