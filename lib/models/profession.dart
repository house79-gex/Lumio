class ProfessionCategory {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final bool splitByYear;
  final bool isCustom;
  final String folderName;

  const ProfessionCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    this.splitByYear = false,
    this.isCustom = false,
    String? folderName,
  }) : folderName = folderName ?? name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'description': description,
        'splitByYear': splitByYear,
        'isCustom': isCustom,
        'folderName': folderName,
      };

  factory ProfessionCategory.fromJson(Map<String, dynamic> json) {
    return ProfessionCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '📁',
      description: json['description'] as String? ?? '',
      splitByYear: json['splitByYear'] as bool? ?? false,
      isCustom: json['isCustom'] as bool? ?? false,
      folderName: json['folderName'] as String? ?? json['name'] as String,
    );
  }
}

class Profession {
  final String id;
  final String name;
  final String emoji;
  final String sector;
  final List<ProfessionCategory> defaultCategories;
  final bool isCustom;

  const Profession({
    required this.id,
    required this.name,
    required this.emoji,
    required this.sector,
    required this.defaultCategories,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'sector': sector,
        'defaultCategories': defaultCategories.map((c) => c.toJson()).toList(),
        'isCustom': isCustom,
      };

  factory Profession.fromJson(Map<String, dynamic> json) {
    final list = json['categories'] as List<dynamic>? ?? json['defaultCategories'] as List<dynamic>? ?? [];
    return Profession(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '💼',
      sector: json['sector'] as String? ?? '',
      defaultCategories: list.map((e) => ProfessionCategory.fromJson(e as Map<String, dynamic>)).toList(),
      isCustom: json['isCustom'] as bool? ?? false,
    );
  }
}

class UserProfile {
  final String id;
  final String name;
  final String emoji;
  final Profession baseProfession;
  final List<ProfessionCategory> categories;
  final String baseFolderPath;
  final Map<String, bool> cloudSyncEnabled;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.baseProfession,
    required this.categories,
    required this.baseFolderPath,
    this.cloudSyncEnabled = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'baseProfession': baseProfession.toJson(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'baseFolderPath': baseFolderPath,
        'cloudSyncEnabled': cloudSyncEnabled,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  UserProfile copyWith({
    String? name,
    String? emoji,
    List<ProfessionCategory>? categories,
    String? baseFolderPath,
    Map<String, bool>? cloudSyncEnabled,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      baseProfession: baseProfession,
      categories: categories ?? this.categories,
      baseFolderPath: baseFolderPath ?? this.baseFolderPath,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      createdAt: createdAt,
    );
  }
}
