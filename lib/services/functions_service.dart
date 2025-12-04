import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/generation.dart';

/// Service for calling Firebase Cloud Functions.
class FunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Call the generateAIScenes Cloud Function.
  /// 
  /// [imageUrl] - The download URL of the uploaded image.
  /// [imagePath] - The storage path for ownership validation.
  /// [sceneIds] - List of selected scene IDs to generate.
  /// 
  /// Returns a list of generated images on success.
  /// Storage paths are resolved to download URLs via Firebase Storage SDK.
  Future<GenerationResult> generateAIScenes({
    required String imageUrl,
    required String imagePath,
    required List<String> sceneIds,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateAIScenes',
        options: HttpsCallableOptions(
          timeout: const Duration(minutes: 8), // More time for multiple scenes
        ),
      );

      final result = await callable.call({
        'imageUrl': imageUrl,
        'imagePath': imagePath,
        'sceneIds': sceneIds,
      });

      final data = Map<String, dynamic>.from(result.data as Map);

      // Check for success
      if (data['success'] == true) {
        final generationId = data['generationId'] as String;
        final imagesList = data['images'] as List<dynamic>;
        final images = imagesList
            .map((e) => GeneratedImage.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        // Resolve storage paths to download URLs
        await _resolveImageUrls(images);

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

  /// Resolve storage paths to download URLs for all images.
  Future<void> _resolveImageUrls(List<GeneratedImage> images) async {
    await Future.wait(
      images.map((image) async {
        try {
          final url = await _storage.ref(image.path).getDownloadURL();
          image.url = url;
        } catch (e) {
          // Log error but don't fail the entire operation
          developer.log(
            'Failed to resolve URL for ${image.path}: $e',
            name: 'FunctionsService',
          );
        }
      }),
    );
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
