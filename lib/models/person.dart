class Person {
  final String id;
  final String name;
  final String? nickname;
  final String? relationship;
  final String? profileImagePath;
  final String? albumId;
  final String? folderPath;
  final int? createdAt;

  const Person({
    required this.id,
    required this.name,
    this.nickname,
    this.relationship,
    this.profileImagePath,
    this.albumId,
    this.folderPath,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nickname': nickname,
        'relationship': relationship,
        'profile_image_path': profileImagePath,
        'album_id': albumId,
        'folder_path': folderPath,
        'created_at': createdAt,
      };

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      relationship: json['relationship'] as String?,
      profileImagePath: json['profile_image_path'] as String?,
      albumId: json['album_id'] as String?,
      folderPath: json['folder_path'] as String?,
      createdAt: json['created_at'] as int?,
    );
  }
}
