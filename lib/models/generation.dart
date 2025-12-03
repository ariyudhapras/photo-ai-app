/// Status of an AI generation request.
enum GenerationStatus {
  pending,
  completed,
  failed;

  /// Convert from string (for JSON parsing).
  static GenerationStatus fromString(String value) {
    return GenerationStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => GenerationStatus.pending,
    );
  }
}

/// Represents a single AI-generated image with its scene type.
class GeneratedImage {
  final String url;
  final String scene; // beach, city, roadtrip, cafe, etc.

  const GeneratedImage({
    required this.url,
    required this.scene,
  });

  /// Create from JSON map.
  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      url: json['url'] as String,
      scene: json['scene'] as String,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'scene': scene,
    };
  }
}

/// Represents a complete generation session with original and generated images.
class Generation {
  final String id;
  final String originalImageUrl;
  final List<GeneratedImage> generatedImages;
  final GenerationStatus status;
  final String? errorMessage;
  final DateTime? createdAt;

  const Generation({
    required this.id,
    required this.originalImageUrl,
    this.generatedImages = const [],
    this.status = GenerationStatus.pending,
    this.errorMessage,
    this.createdAt,
  });

  /// Create from JSON map (Firestore document).
  factory Generation.fromJson(Map<String, dynamic> json) {
    return Generation(
      id: json['id'] as String,
      originalImageUrl: json['originalImageUrl'] as String,
      generatedImages: (json['generatedImages'] as List<dynamic>?)
              ?.map((e) => GeneratedImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: GenerationStatus.fromString(json['status'] as String? ?? 'pending'),
      errorMessage: json['errorMessage'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// Convert to JSON map (for Firestore).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalImageUrl': originalImageUrl,
      'generatedImages': generatedImages.map((e) => e.toJson()).toList(),
      'status': status.name,
      'errorMessage': errorMessage,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Generation copyWith({
    String? id,
    String? originalImageUrl,
    List<GeneratedImage>? generatedImages,
    GenerationStatus? status,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return Generation(
      id: id ?? this.id,
      originalImageUrl: originalImageUrl ?? this.originalImageUrl,
      generatedImages: generatedImages ?? this.generatedImages,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
