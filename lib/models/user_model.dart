class UserModel {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final String? work;
  final String? relationshipStatus;

  UserModel({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    this.work,
    this.relationshipStatus,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      work: json['work'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'location': location,
      'work': work,
      'relationship_status': relationshipStatus,
    };
  }
}
