import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/scene.dart';

/// A horizontal scrollable scene selector with Apple Design Award style.
/// Displays scene options as tappable chips with emoji and label.
/// Supports multi-select with toggle behavior.
class SceneSelector extends StatelessWidget {
  final List<Scene> scenes;
  final Set<Scene> selectedScenes;
  final ValueChanged<Scene> onToggle;
  final bool enabled;

  const SceneSelector({
    super.key,
    required this.scenes,
    required this.selectedScenes,
    required this.onToggle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate chip width based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    // Show ~4.5 chips on screen, min 72, max 88
    final chipWidth = ((screenWidth - 48) / 4.5).clamp(72.0, 88.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Scenes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                children: [
                  if (selectedScenes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryStart.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${selectedScenes.length} selected',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryStart,
                        ),
                      ),
                    ),
                  Text(
                    '${scenes.length} options',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: scenes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final scene = scenes[index];
              final isSelected = selectedScenes.contains(scene);
              return _SceneChip(
                scene: scene,
                isSelected: isSelected,
                enabled: enabled,
                onTap: () => onToggle(scene),
                width: chipWidth,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SceneChip extends StatefulWidget {
  final Scene scene;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;
  final double width;

  const _SceneChip({
    required this.scene,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
    required this.width,
  });

  @override
  State<_SceneChip> createState() => _SceneChipState();
}

class _SceneChipState extends State<_SceneChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: widget.width,
          height: 96,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.isSelected ? AppTheme.surface : AppTheme.background,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: widget.isSelected
                  ? AppTheme.primaryStart
                  : Colors.grey.shade300,
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryStart.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.scene.icon,
                  size: 28,
                  color: widget.isSelected
                      ? AppTheme.primaryStart
                      : AppTheme.textSecondary,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.scene.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: widget.isSelected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
