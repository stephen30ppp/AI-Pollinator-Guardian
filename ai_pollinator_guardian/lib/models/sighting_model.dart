import 'package:cloud_firestore/cloud_firestore.dart';

class SightingModel {
  final String id;
  final String userId;
  final String pollinatorId;
  final String pollinatorName;
  final String imageUrl;
  final GeoPoint location;
  final String locationName;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic> additionalData;

  SightingModel({
    required this.id,
    required this.userId,
    required this.pollinatorId,
    required this.pollinatorName,
    required this.imageUrl,
    required this.location,
    this.locationName = '',
    required this.confidence,
    required this.timestamp,
    this.additionalData = const {},
  });

  factory SightingModel.fromJson(Map<String, dynamic> json) {
    return SightingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      pollinatorId: json['pollinatorId'] as String,
      pollinatorName: json['pollinatorName'] as String,
      imageUrl: json['imageUrl'] as String,
      location: json['location'] as GeoPoint,
      locationName: json['locationName'] as String? ?? '',
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      additionalData: json['additionalData'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'pollinatorId': pollinatorId,
      'pollinatorName': pollinatorName,
      'imageUrl': imageUrl,
      'location': location,
      'locationName': locationName,
      'confidence': confidence,
      'timestamp': timestamp,
      'additionalData': additionalData,
    };
  }
}