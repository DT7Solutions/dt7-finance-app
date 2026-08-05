import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeaderIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color color;
  final double size;

  const AppHeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color = const Color(0xFF1F2937),
    this.size = 24,
  });

  @override
  State<AppHeaderIconButton> createState() => _AppHeaderIconButtonState();
}

class _AppHeaderIconButtonState extends State<AppHeaderIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _colorAnimation = ColorTween(
      begin: widget.color,
      end: AppColors.primary,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 0ms INSTANT RESPONSE: Fire click handler immediately on tap frame
    widget.onPressed();

    // Play visual active orange pulse animation in background
    _controller.forward().then((_) {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final isAnimating = _controller.value > 0.05;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: BorderRadius.circular(24),
            splashColor: AppColors.primary.withValues(alpha: 0.4),
            highlightColor: AppColors.primary.withValues(alpha: 0.25),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isAnimating ? AppColors.primary.withValues(alpha: 0.22) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAnimating ? AppColors.primary : Colors.transparent,
                  width: 2.0,
                ),
                boxShadow: isAnimating
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Icon(
                  widget.icon,
                  color: isAnimating ? AppColors.primary : _colorAnimation.value,
                  size: widget.size,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
