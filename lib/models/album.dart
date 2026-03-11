class Album {
  final String id;
  final String profileId;
  final String name;
  final String? emoji;
  final String? categoryId;
  final String? personId;
  final int? year;
  final String? folderPath;
  final String? coverPhotoId;
  final int photoCount;
  final bool cloudSynced;
  final int? createdAt;
  final int? updatedAt;

  const Album({
    required this.id,
    required this.profileId,
    required this.name,
    this.emoji,
    this.categoryId,
    this.personId,
    this.year,
    this.folderPath,
    this.coverPhotoId,
    this.photoCount = 0,
    this.cloudSynced = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'name': name,
        'emoji': emoji,
        'category_id': categoryId,
        'person_id': personId,
        'year': year,
        'folder_path': folderPath,
        'cover_photo_id': coverPhotoId,
        'photo_count': photoCount,
        'cloud_synced': cloudSynced ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      categoryId: json['category_id'] as String?,
      personId: json['person_id'] as String?,
      year: json['year'] as int?,
      folderPath: json['folder_path'] as String?,
      coverPhotoId: json['cover_photo_id'] as String?,
      photoCount: json['photo_count'] as int? ?? 0,
      cloudSynced: (json['cloud_synced'] as int?) == 1,
      createdAt: json['created_at'] as int?,
      updatedAt: json['updated_at'] as int?,
    );
  }
}
