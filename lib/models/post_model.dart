class PostModel {
  final String? id; // Can be null if local before saving, or dynamic if we support mock int IDs still (but we should move to UUID)
  final String? content;
  final String? imageUrl;
  final String? userId; // Author
  final DateTime createdAt;

  // Interactions (Not stored in `posts` table directly usually, but often joined)
  // For now, let's keep it simple mapping to the table structure
  
  PostModel({
    this.id,
    this.content,
    this.imageUrl,
    this.userId,
    required this.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id']?.toString(), // Handle int or string ID
      content: json['content'] as String?,
      imageUrl: json['image_url'] as String?,
      userId: json['user_id']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'image_url': imageUrl,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
