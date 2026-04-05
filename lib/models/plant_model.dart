class PlantModel {
  final String id;
  final String name;
  final String? scientificName;
  final String? description;
  final String? idealSoil;
  final String? medicalBenefits;
  final String? plantingSeason;
  final String? imageUrl;

  PlantModel({
    required this.id,
    required this.name,
    this.scientificName,
    this.description,
    this.idealSoil,
    this.medicalBenefits,
    this.plantingSeason,
    this.imageUrl,
  });

  /// Cleans a field: if null or the literal word "string", returns null.
  static String? _clean(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'string') return null;
    return s;
  }

  /// Full image URL prefixed with the base server URL.
  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    const baseServer = 'https://root2route.runasp.net';
    return imageUrl!.startsWith('http') ? imageUrl : '$baseServer$imageUrl';
  }

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id']?.toString() ?? '',
      name: (json['name']?.toString() ?? '').trim(),
      scientificName: _clean(json['scientificName']),
      description: _clean(json['description']),
      idealSoil: _clean(json['idealSoil']),
      medicalBenefits: _clean(json['medicalBenefits']),
      plantingSeason: _clean(json['plantingSeason']),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'scientificName': scientificName,
        'description': description,
        'idealSoil': idealSoil,
        'medicalBenefits': medicalBenefits,
        'plantingSeason': plantingSeason,
        'imageUrl': imageUrl,
      };
}
