import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/app_theme.dart';
import '../models/generation.dart';

/// Grid widget to display original and generated images.
class ImageGrid extends StatelessWidget {
  final String? originalImageUrl;
  final List<GeneratedImage> generatedImages;

  const ImageGrid({
    super.key,
    this.originalImageUrl,
    this.generatedImages = const [],
  });

  @override
  Widget build(BuildContext context) {
    // Build list of generated images
    final List<_GridItem> generatedItems = [];

    for (final image in generatedImages) {
      if (image.url != null) {
        generatedItems.add(_GridItem(
          url: image.url!,
          label: _formatLabel(image.scene),
        ));
      }
    }

    // If no images at all, don't show anything
    if (originalImageUrl == null && generatedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    // Single generated image: side-by-side comparison
    if (generatedItems.length == 1 && originalImageUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _ImageCard(
                    item: _GridItem(url: originalImageUrl!, label: 'Original'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _ImageCard(item: generatedItems[0]),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Multiple generated images: original small centered, grid below
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original section - small, centered
        if (originalImageUrl != null) ...[
          const Text(
            'Original',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: _ImageCard(
                item: _GridItem(url: originalImageUrl!, label: ''),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
        ],

        // Generated section
        if (generatedItems.isNotEmpty) ...[
          const Text(
            'Generated Scenes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: generatedItems.length,
            itemBuilder: (context, index) {
              return _ImageCard(item: generatedItems[index]);
            },
          ),
        ],
      ],
    );
  }

  /// Format scene name for display (capitalize first letter).
  String _formatLabel(String scene) {
    if (scene.isEmpty) return scene;
    return scene[0].toUpperCase() + scene.substring(1);
  }
}

/// Internal model for grid items.
class _GridItem {
  final String url;
  final String label;

  _GridItem({
    required this.url,
    required this.label,
  });
}

/// Individual image card with label overlay.
class _ImageCard extends StatelessWidget {
  final _GridItem item;

  const _ImageCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            CachedNetworkImage(
              imageUrl: item.url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppTheme.background,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryStart),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppTheme.background,
                child: const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.textSecondary,
                    size: 32,
                  ),
                ),
              ),
            ),
            // Label overlay at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingS,
                  vertical: AppTheme.spacingXS + 2,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Text(
                  item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
