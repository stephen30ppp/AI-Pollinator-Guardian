class GardenModel {
  final String id;
  final String userId;
  final String name;
  final List<String> photoUrls;
  final double pollinatorScore;
  final Map<String, bool> analysisResults;
  final List<PlantRecommendation> recommendations;
  final DateTime createdAt;
  final DateTime updatedAt;

  GardenModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrls = const [],
    this.pollinatorScore = 0.0,
    this.analysisResults = const {},
    this.recommendations = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory GardenModel.fromJson(Map<String, dynamic> json) {
    return GardenModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      pollinatorScore: (json['pollinatorScore'] as num?)?.toDouble() ?? 0.0,
      analysisResults: Map<String, bool>.from(json['analysisResults'] ?? {}),
      recommendations: (json['recommendations'] as List?)
          ?.map((e) => PlantRecommendation.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'photoUrls': photoUrls,
      'pollinatorScore': pollinatorScore,
      'analysisResults': analysisResults,
      'recommendations': recommendations.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class PlantRecommendation {
  final String name;
  final String imageUrl;
  final String description;
  final List<String> tags;

  PlantRecommendation({
    required this.name,
    required this.imageUrl,
    required this.description,
    this.tags = const [],
  });

  factory PlantRecommendation.fromJson(Map<String, dynamic> json) {
    return PlantRecommendation(
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
      'tags': tags,
    };
  }
}