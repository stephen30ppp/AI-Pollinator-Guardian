import 'package:cloud_firestore/cloud_firestore.dart';

class SightingModel {
  final String id;
  final String userId;
  final String pollinatorId;
  final String pollinatorName;
  final String imageUrl;
  final GeoPoint location;
  final double confidence;
  final DateTime timestamp;

  SightingModel({
    required this.id,
    required this.userId,
    required this.pollinatorId,
    required this.pollinatorName,
    required this.imageUrl,
    required this.location,
    required this.confidence,
    required this.timestamp,
  });

  factory SightingModel.fromJson(Map<String, dynamic> json) {
    return SightingModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      pollinatorId: json['pollinatorId'] as String,
      pollinatorName: json['pollinatorName'] as String,
      imageUrl: json['imageUrl'] as String,
      location: json['location'] as GeoPoint,
      confidence: json['confidence'] as double,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
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
      'confidence': confidence,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}