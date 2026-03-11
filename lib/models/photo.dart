class Photo {
  final String id;
  final String path;
  final int? dateTaken;
  final int? year;
  final String? aiCategory;
  final double? aiConfidence;
  final String? aiDescription;
  final bool isManuallyMoved;
  final int? analyzedAt;
  final double? latitude;
  final double? longitude;
  final String? localFolderPath;
  final String cloudSyncStatus;
  final int? cloudSyncAt;

  const Photo({
    required this.id,
    required this.path,
    this.dateTaken,
    this.year,
    this.aiCategory,
    this.aiConfidence,
    this.aiDescription,
    this.isManuallyMoved = false,
    this.analyzedAt,
    this.latitude,
    this.longitude,
    this.localFolderPath,
    this.cloudSyncStatus = 'pending',
    this.cloudSyncAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'date_taken': dateTaken,
        'year': year,
        'ai_category': aiCategory,
        'ai_confidence': aiConfidence,
        'ai_description': aiDescription,
        'is_manually_moved': isManuallyMoved ? 1 : 0,
        'analyzed_at': analyzedAt,
        'latitude': latitude,
        'longitude': longitude,
        'local_folder_path': localFolderPath,
        'cloud_sync_status': cloudSyncStatus,
        'cloud_sync_at': cloudSyncAt,
      };

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      path: json['path'] as String,
      dateTaken: json['date_taken'] as int?,
      year: json['year'] as int?,
      aiCategory: json['ai_category'] as String?,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      aiDescription: json['ai_description'] as String?,
      isManuallyMoved: (json['is_manually_moved'] as int?) == 1,
      analyzedAt: json['analyzed_at'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      localFolderPath: json['local_folder_path'] as String?,
      cloudSyncStatus: json['cloud_sync_status'] as String? ?? 'pending',
      cloudSyncAt: json['cloud_sync_at'] as int?,
    );
  }
}
