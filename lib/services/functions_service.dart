import 'package:cloud_functions/cloud_functions.dart';
import '../models/generation.dart';

/// Service for calling Firebase Cloud Functions.
class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Call the generateAIScenes Cloud Function.
  /// 
  /// [imageUrl] - The download URL of the uploaded image.
  /// [imagePath] - The storage path for ownership validation.
  /// 
  /// Returns a list of generated images on success.
  Future<GenerationResult> generateAIScenes({
    required String imageUrl,
    required String imagePath,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateAIScenes',
        options: HttpsCallableOptions(
          timeout: const Duration(minutes: 5), // AI generation can take time
        ),
      );

      final result = await callable.call({
        'imageUrl': imageUrl,
        'imagePath': imagePath,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      // Check for success
      if (data['success'] == true) {
        final generationId = data['generationId'] as String;
        final imagesList = data['images'] as List<dynamic>;
        final images = imagesList
            .map((e) => GeneratedImage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        return GenerationResult(
          success: true,
          generationId: generationId,
          images: images,
        );
      } else {
        // Handle error response from function
        final error = data['error'] as Map<String, dynamic>?;
        throw FunctionsException(
          code: error?['code'] as String? ?? 'unknown',
          message: error?['message'] as String? ?? 'Generation failed',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      throw FunctionsException(
        code: e.code,
        message: e.message ?? 'Cloud Function call failed',
      );
    }
  }
}

/// Result of a generation operation.
class GenerationResult {
  final bool success;
  final String? generationId;
  final List<GeneratedImage> images;

  GenerationResult({
    required this.success,
    this.generationId,
    this.images = const [],
  });
}

/// Custom exception for Cloud Functions errors.
class FunctionsException implements Exception {
  final String code;
  final String message;

  FunctionsException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'FunctionsException($code): $message';
}
