import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/generation.dart';
import '../models/scene.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/functions_service.dart';

/// Application state enum.
enum AppState {
  idle,       // Initial state, ready for upload
  uploading,  // Uploading image to Storage
  generating, // Calling Cloud Function for AI generation
  completed,  // Generation completed successfully
  error,      // An error occurred
}

/// Main application state provider.
/// Orchestrates the flow: Upload → Generate → Display.
class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final FunctionsService _functionsService = FunctionsService();

  // State
  AppState _state = AppState.idle;
  File? _selectedImage;
  String? _uploadedImageUrl;
  String? _uploadedImagePath;
  Set<Scene> _selectedScenes = {};
  List<GeneratedImage> _generatedImages = [];
  String? _errorMessage;

  // Getters
  AppState get state => _state;
  File? get selectedImage => _selectedImage;
  String? get uploadedImageUrl => _uploadedImageUrl;
  Set<Scene> get selectedScenes => _selectedScenes;
  List<GeneratedImage> get generatedImages => _generatedImages;
  String? get errorMessage => _errorMessage;
  bool get hasSelectedImage => _selectedImage != null;
  bool get hasSelectedScenes => _selectedScenes.isNotEmpty;
  bool get canGenerate => hasSelectedImage && hasSelectedScenes;
  bool get hasResults => _generatedImages.isNotEmpty;
  bool get isLoading => _state == AppState.uploading || _state == AppState.generating;

  /// Select an image from gallery or camera.
  void selectImage(File image) {
    _selectedImage = image;
    _uploadedImageUrl = null;
    _uploadedImagePath = null;
    _selectedScenes = {};
    _generatedImages = [];
    _errorMessage = null;
    _state = AppState.idle;
    notifyListeners();
  }

  /// Clear the selected image.
  void clearImage() {
    _selectedImage = null;
    _uploadedImageUrl = null;
    _uploadedImagePath = null;
    _selectedScenes = {};
    _generatedImages = [];
    _errorMessage = null;
    _state = AppState.idle;
    notifyListeners();
  }

  /// Toggle scene selection (select/unselect).
  void toggleScene(Scene scene) {
    if (_selectedScenes.contains(scene)) {
      _selectedScenes.remove(scene);
    } else {
      _selectedScenes.add(scene);
    }
    notifyListeners();
  }

  /// Clear all scene selections.
  void clearScenes() {
    _selectedScenes = {};
    notifyListeners();
  }

  /// Main flow: Upload image and generate AI scenes.
  Future<void> generateScenes() async {
    if (_selectedImage == null) {
      _setError('No image selected');
      return;
    }

    if (_selectedScenes.isEmpty) {
      _setError('Please select at least one scene');
      return;
    }

    try {
      // Step 1: Ensure user is authenticated
      final userId = await _authService.ensureAuthenticated();

      // Step 2: Upload image to Storage
      _setState(AppState.uploading);
      final uploadResult = await _storageService.uploadImage(
        file: _selectedImage!,
        userId: userId,
      );
      _uploadedImageUrl = uploadResult.downloadUrl;
      _uploadedImagePath = uploadResult.storagePath;

      // Step 3: Call Cloud Function to generate AI scenes
      _setState(AppState.generating);
      final sceneIds = _selectedScenes.map((s) => s.id).toList();
      final generationResult = await _functionsService.generateAIScenes(
        imageUrl: _uploadedImageUrl!,
        imagePath: _uploadedImagePath!,
        sceneIds: sceneIds,
      );

      // Step 4: Append new results to existing (for "Generate More" flow)
      _generatedImages = [..._generatedImages, ...generationResult.images];
      
      // Step 5: Clear selection after successful generation
      _selectedScenes = {};
      _setState(AppState.completed);

    } on AuthException catch (e) {
      _setError('Authentication failed: ${e.message}');
    } on StorageException catch (e) {
      _setError('Upload failed: ${e.message}');
    } on FunctionsException catch (e) {
      _setError('Generation failed: ${e.message}');
    } catch (e) {
      _setError('Something went wrong: $e');
    }
  }

  /// Reset to initial state.
  void reset() {
    _state = AppState.idle;
    _selectedImage = null;
    _uploadedImageUrl = null;
    _uploadedImagePath = null;
    _selectedScenes = {};
    _generatedImages = [];
    _errorMessage = null;
    notifyListeners();
  }

  /// Retry after error.
  void retry() {
    _errorMessage = null;
    _state = AppState.idle;
    notifyListeners();
    
    // If we have a selected image, try generating again
    if (_selectedImage != null) {
      generateScenes();
    }
  }

  /// Set state and notify listeners.
  void _setState(AppState newState) {
    _state = newState;
    _errorMessage = null;
    notifyListeners();
  }

  /// Set error state.
  void _setError(String message) {
    _state = AppState.error;
    _errorMessage = message;
    notifyListeners();
  }
}
