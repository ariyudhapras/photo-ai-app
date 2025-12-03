import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Button states for the generate action.
enum GenerateButtonState {
  disabled, // No image selected
  ready,    // Ready to generate
  loading,  // Generation in progress
}

/// Main action button with gradient background and loading state.
class GenerateButton extends StatelessWidget {
  final GenerateButtonState state;
  final VoidCallback? onPressed;
  final String? loadingText;

  const GenerateButton({
    super.key,
    required this.state,
    this.onPressed,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = state == GenerateButtonState.disabled;
    final isLoading = state == GenerateButtonState.loading;

    return SizedBox(
      width: double.infinity,
      height: AppTheme.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDisabled ? null : AppTheme.primaryGradient,
          color: isDisabled ? AppTheme.disabled : null,
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.primaryStart.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isDisabled || isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            child: Center(
              child: isLoading
                  ? _buildLoadingContent()
                  : _buildReadyContent(isDisabled),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(width: AppTheme.spacingM),
        Text(
          loadingText ?? 'Creating...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildReadyContent(bool isDisabled) {
    return Text(
      'Generate Scenes',
      style: TextStyle(
        color: isDisabled ? AppTheme.textSecondary : Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
