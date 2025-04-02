class UserModel {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> sightings;
  final List<String> gardens;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.sightings = const [],
    this.gardens = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      sightings: List<String>.from(json['sightings'] ?? []),
      gardens: List<String>.from(json['gardens'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'sightings': sightings,
      'gardens': gardens,
    };
  }
}