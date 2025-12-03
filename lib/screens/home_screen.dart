import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/app_provider.dart';
import '../widgets/upload_card.dart';
import '../widgets/generate_button.dart';
import '../widgets/image_grid.dart';

/// Main screen of the Photo AI app.
/// Single screen with upload, generate, and display functionality.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Photo AI'),
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              // Main content
              _buildContent(context, provider),
              // Loading overlay
              if (provider.isLoading) _buildLoadingOverlay(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upload card
          UploadCard(
            selectedImage: provider.selectedImage,
            onTap: () => _pickImage(context),
            onRemove: provider.hasSelectedImage ? () => provider.clearImage() : null,
            enabled: !provider.isLoading,
          ),
          const SizedBox(height: AppTheme.spacingL),

          // Generate button
          GenerateButton(
            state: _getButtonState(provider),
            onPressed: provider.hasSelectedImage ? () => provider.generateScenes() : null,
            loadingText: provider.state == AppState.uploading 
                ? 'Uploading...' 
                : 'Creating your scenes...',
          ),

          // Error message
          if (provider.state == AppState.error) ...[
            const SizedBox(height: AppTheme.spacingM),
            _buildErrorMessage(provider),
          ],

          // Results grid
          if (provider.hasResults) ...[
            const SizedBox(height: AppTheme.spacingXL),
            ImageGrid(
              originalImageUrl: provider.uploadedImageUrl,
              generatedImages: provider.generatedImages,
            ),
          ],

          // Bottom padding for scroll
          const SizedBox(height: AppTheme.spacingXL),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay(AppProvider provider) {
    return Container(
      color: Colors.white.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryStart),
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              provider.state == AppState.uploading
                  ? 'Uploading your photo...'
                  : 'Creating your scenes...',
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            const Text(
              'This may take a moment',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.error,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (provider.errorMessage != null) ...[
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    provider.errorMessage!,
                    style: TextStyle(
                      color: AppTheme.error.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => provider.retry(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  GenerateButtonState _getButtonState(AppProvider provider) {
    if (provider.isLoading) {
      return GenerateButtonState.loading;
    }
    if (provider.hasSelectedImage) {
      return GenerateButtonState.ready;
    }
    return GenerateButtonState.disabled;
  }

  Future<void> _pickImage(BuildContext context) async {
    final provider = context.read<AppProvider>();
    
    // Show bottom sheet to choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    // Pick image
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      provider.selectImage(File(pickedFile.path));
    }
  }
}
