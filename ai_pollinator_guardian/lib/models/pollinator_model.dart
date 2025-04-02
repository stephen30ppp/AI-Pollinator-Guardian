class PollinatorModel {
  final String id;
  final String commonName;
  final String scientificName;
  final String description;
  final String imageUrl;
  final String type; // e.g., 'bee', 'butterfly', 'other'
  final List<String> preferredPlants;
  final String conservationStatus;
  final Map<String, dynamic> additionalInfo;

  PollinatorModel({
    required this.id,
    required this.commonName,
    required this.scientificName,
    required this.description,
    required this.imageUrl,
    required this.type,
    this.preferredPlants = const [],
    this.conservationStatus = 'Unknown',
    this.additionalInfo = const {},
  });

  factory PollinatorModel.fromJson(Map<String, dynamic> json) {
    return PollinatorModel(
      id: json['id'] as String,
      commonName: json['commonName'] as String,
      scientificName: json['scientificName'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      type: json['type'] as String,
      preferredPlants: List<String>.from(json['preferredPlants'] ?? []),
      conservationStatus: json['conservationStatus'] as String? ?? 'Unknown',
      additionalInfo: json['additionalInfo'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commonName': commonName,
      'scientificName': scientificName,
      'description': description,
      'imageUrl': imageUrl,
      'type': type,
      'preferredPlants': preferredPlants,
      'conservationStatus': conservationStatus,
      'additionalInfo': additionalInfo,
    };
  }
}