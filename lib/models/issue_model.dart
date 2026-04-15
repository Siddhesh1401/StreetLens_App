class IssueModel {
  final String issueId;
  final String userId;
  final String imageUrl;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String status; // 'Pending', 'In Progress', 'Resolved'
  final int upvotes;
  final String assignedWorker;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userName;

  IssueModel({
    required this.issueId,
    required this.userId,
    required this.imageUrl,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.upvotes,
    required this.assignedWorker,
    required this.createdAt,
    required this.updatedAt,
    required this.userName,
  });

  factory IssueModel.fromMap(Map<String, dynamic> map, String id) {
    return IssueModel(
      issueId: id,
      userId: map['user_id'] ?? '',
      imageUrl: map['image_url'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'Pending',
      upvotes: map['upvotes'] ?? 0,
      assignedWorker: map['assigned_worker'] ?? '',
      createdAt: (map['created_at'] as dynamic)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as dynamic)?.toDate() ?? DateTime.now(),
      userName: map['user_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'image_url': imageUrl,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'upvotes': upvotes,
      'assigned_worker': assignedWorker,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'user_name': userName,
    };
  }
}
