import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarGlow extends StatefulWidget {
  final String? imageUrl;
  final double size;
  final VoidCallback? onTap;
  final bool showNotification;
  final Color glowColor;
  final Widget? fallbackWidget;

  const AvatarGlow({
    Key? key,
    this.imageUrl,
    this.size = 36,
    this.onTap,
    this.showNotification = false,
    this.glowColor = Colors.white,
    this.fallbackWidget,
  }) : super(key: key);

  @override
  State<AvatarGlow> createState() => _AvatarGlowState();
}

class _AvatarGlowState extends State<AvatarGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    // Adjust glow opacity based on theme brightness
    final glowOpacity = brightness == Brightness.dark ? 0.3 : 0.5;
    
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.glowColor.withOpacity(glowOpacity * _glowAnimation.value),
                    blurRadius: 4 + 4 * _glowAnimation.value,
                    spreadRadius: 1 + 1 * _glowAnimation.value,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Avatar
              CircleAvatar(
                radius: widget.size / 2,
                backgroundColor: theme.colorScheme.primaryContainer,
                backgroundImage: widget.imageUrl != null
                    ? CachedNetworkImageProvider(widget.imageUrl!)
                    : null,
                child: widget.imageUrl == null
                    ? widget.fallbackWidget ?? const Icon(Icons.person_outline, size: 20)
                    : null,
              ),
              
              // Notification dot
              if (widget.showNotification)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}