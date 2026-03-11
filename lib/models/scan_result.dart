class ScanResult {
  final String photoId;
  final String path;
  final String? categoryId;
  final String? categoryName;
  final String? emoji;
  final double confidence;
  final String? description;
  final int? year;
  final bool toReview;

  const ScanResult({
    required this.photoId,
    required this.path,
    this.categoryId,
    this.categoryName,
    this.emoji,
    required this.confidence,
    this.description,
    this.year,
    this.toReview = false,
  });
}

enum ScanStatus { idle, scanning, done, error }

class ScanState {
  final ScanStatus status;
  final int total;
  final int processed;
  final List<ScanResult> results;
  final String? errorMessage;

  const ScanState({
    this.status = ScanStatus.idle,
    this.total = 0,
    this.processed = 0,
    this.results = const [],
    this.errorMessage,
  });

  double get progress => total > 0 ? processed / total : 0.0;

  ScanState copyWith({
    ScanStatus? status,
    int? total,
    int? processed,
    List<ScanResult>? results,
    String? errorMessage,
  }) {
    return ScanState(
      status: status ?? this.status,
      total: total ?? this.total,
      processed: processed ?? this.processed,
      results: results ?? this.results,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
