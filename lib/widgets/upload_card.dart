import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Card widget for uploading and previewing images.
/// Shows empty state with dashed border or image preview.
class UploadCard extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool enabled;

  const UploadCard({
    super.key,
    this.selectedImage,
    required this.onTap,
    this.onRemove,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 5,
      child: selectedImage != null
          ? _buildImagePreview()
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: enabled ? AppTheme.textSecondary.withValues(alpha: 0.3) : AppTheme.disabled,
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: enabled ? AppTheme.textSecondary.withValues(alpha: 0.3) : AppTheme.disabled,
            borderRadius: AppTheme.radiusLarge,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 48,
                  color: enabled ? AppTheme.textSecondary : AppTheme.disabled,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Tap to upload',
                  style: TextStyle(
                    fontSize: 16,
                    color: enabled ? AppTheme.textSecondary : AppTheme.disabled,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  'JPG or PNG, max 10MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? AppTheme.textSecondary.withValues(alpha: 0.7) : AppTheme.disabled,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        // Image
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Image.file(
                selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
        // Remove button
        if (onRemove != null && enabled)
          Positioned(
            top: AppTheme.spacingS,
            right: AppTheme.spacingS,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingS),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for dashed border effect.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    // Draw dashed path
    const dashWidth = 8.0;
    const dashSpace = 4.0;
    
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0, metric.length);
        canvas.drawPath(
          metric.extractPath(start, end.toDouble()),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
