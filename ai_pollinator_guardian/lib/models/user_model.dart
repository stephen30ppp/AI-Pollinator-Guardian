class UserModel {
  final String id;
  final String name;
  final String email;
  final String username;
  final String? photoUrl;
  final List<String> sightings;
  final List<String> gardens;
  
  // Added target fields for tracking user goals
  final Map<String, int> targets; // Store different types of targets
  final Map<String, int> identifiedSpecies; // Track identified species by ID

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.photoUrl,
    this.sightings = const [],
    this.gardens = const [],
    this.targets = const {},
    this.identifiedSpecies = const {},
  });

  // Get specific target values with defaults
  int getTarget(String targetType, {int defaultValue = 10}) {
    return targets[targetType] ?? defaultValue;
  }

  // Get number of unique species identified
  int get identifiedSpeciesCount => identifiedSpecies.length;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      username:
          json['username'] as String? ??
          '', // For backward compatibility with existing users
      photoUrl: json['photoUrl'] as String?,
      sightings: List<String>.from(json['sightings'] ?? []),
      gardens: List<String>.from(json['gardens'] ?? []),
      targets: Map<String, int>.from(json['targets'] ?? {}),
      identifiedSpecies: Map<String, int>.from(json['identifiedSpecies'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'username': username,
      'photoUrl': photoUrl,
      'sightings': sightings,
      'gardens': gardens,
      'targets': targets,
      'identifiedSpecies': identifiedSpecies,
    };
  }

  // Create a copy of this model with updated fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? username,
    String? photoUrl,
    List<String>? sightings,
    List<String>? gardens, 
    Map<String, int>? targets,
    Map<String, int>? identifiedSpecies,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      username: username ?? this.username,
      photoUrl: photoUrl ?? this.photoUrl,
      sightings: sightings ?? this.sightings,
      gardens: gardens ?? this.gardens,
      targets: targets ?? this.targets,
      identifiedSpecies: identifiedSpecies ?? this.identifiedSpecies,
    );
  }

  // Helper method to update a specific target
  UserModel updateTarget(String targetType, int value) {
    final updatedTargets = Map<String, int>.from(targets);
    updatedTargets[targetType] = value;
    return copyWith(targets: updatedTargets);
  }

  // Helper method to add a new identified species
  UserModel addIdentifiedSpecies(String speciesId) {
    final updatedSpecies = Map<String, int>.from(identifiedSpecies);
    // Increment the count for this species or set to 1 if first time
    updatedSpecies[speciesId] = (updatedSpecies[speciesId] ?? 0) + 1;
    return copyWith(identifiedSpecies: updatedSpecies);
  }
}