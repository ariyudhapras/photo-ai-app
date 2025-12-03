import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Service for handling Firebase Storage operations.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Upload an image file to Firebase Storage.
  /// Returns a tuple of (downloadUrl, storagePath).
  /// 
  /// Storage path format: users/{userId}/originals/{uuid}.{extension}
  Future<UploadResult> uploadImage({
    required File file,
    required String userId,
  }) async {
    try {
      // Validate file
      await _validateFile(file);

      // Generate unique filename
      final extension = _getFileExtension(file.path);
      final filename = '${_uuid.v4()}.$extension';
      final storagePath = 'users/$userId/originals/$filename';

      // Upload file
      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/$extension'),
      );

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return UploadResult(
        downloadUrl: downloadUrl,
        storagePath: storagePath,
      );
    } on FirebaseException catch (e) {
      throw StorageException(
        code: e.code,
        message: e.message ?? 'Upload failed',
      );
    }
  }

  /// Validate file before upload.
  Future<void> _validateFile(File file) async {
    // Check if file exists
    if (!await file.exists()) {
      throw StorageException(
        code: 'file-not-found',
        message: 'File does not exist',
      );
    }

    // Check file size (max 10MB)
    final fileSize = await file.length();
    const maxSize = 10 * 1024 * 1024; // 10MB
    if (fileSize > maxSize) {
      throw StorageException(
        code: 'file-too-large',
        message: 'File size exceeds 10MB limit',
      );
    }

    // Check file extension
    final extension = _getFileExtension(file.path).toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png'];
    if (!allowedExtensions.contains(extension)) {
      throw StorageException(
        code: 'invalid-file-type',
        message: 'Only JPG and PNG files are allowed',
      );
    }
  }

  /// Get file extension from path.
  String _getFileExtension(String path) {
    final parts = path.split('.');
    return parts.isNotEmpty ? parts.last : 'jpg';
  }

  /// Delete a file from Firebase Storage.
  Future<void> deleteFile(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      await ref.delete();
    } on FirebaseException catch (e) {
      throw StorageException(
        code: e.code,
        message: e.message ?? 'Delete failed',
      );
    }
  }
}

/// Result of an upload operation.
class UploadResult {
  final String downloadUrl;
  final String storagePath;

  UploadResult({
    required this.downloadUrl,
    required this.storagePath,
  });
}

/// Custom exception for storage errors.
class StorageException implements Exception {
  final String code;
  final String message;

  StorageException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'StorageException($code): $message';
}
