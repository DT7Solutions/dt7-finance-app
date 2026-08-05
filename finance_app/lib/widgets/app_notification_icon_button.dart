import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppNotificationIconButton extends StatefulWidget {
  final int unreadCount;
  final VoidCallback onTap;

  const AppNotificationIconButton({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  State<AppNotificationIconButton> createState() => _AppNotificationIconButtonState();
}

class _AppNotificationIconButtonState extends State<AppNotificationIconButton> with SingleTickerProviderStateMixin {
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _colorAnimation = ColorTween(
      begin: const Color(0xFF1F2937),
      end: AppColors.primary,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // 0ms INSTANT RESPONSE: Fire notification handler immediately on tap
    widget.onTap();

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
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isAnimating ? AppColors.primary.withValues(alpha: 0.18) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isAnimating ? AppColors.primary.withValues(alpha: 0.6) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: isAnimating
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        isAnimating ? Icons.notifications_rounded : Icons.notifications_none_outlined,
                        color: _colorAnimation.value,
                        size: 22,
                      ),
                      if (widget.unreadCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF5500),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Center(
                              child: Text(
                                '${widget.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
