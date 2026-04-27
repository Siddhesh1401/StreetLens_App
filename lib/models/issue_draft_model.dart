class IssueDraftModel {
  final String description;
  final String? category;
  final double? latitude;
  final double? longitude;
  final String priority;
  final bool isAnonymous;
  final String? imagePath;
  final String? imageBase64;

  IssueDraftModel({
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.isAnonymous,
    required this.imagePath,
    required this.imageBase64,
  });

  factory IssueDraftModel.fromMap(Map<String, dynamic> map) {
    return IssueDraftModel(
      description: map['description'] ?? '',
      category: map['category'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      priority: map['priority'] ?? 'Normal',
      isAnonymous: map['is_anonymous'] ?? false,
      imagePath: map['image_path'] as String?,
      imageBase64: map['image_base64'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'priority': priority,
      'is_anonymous': isAnonymous,
      'image_path': imagePath,
      'image_base64': imageBase64,
    };
  }
}
