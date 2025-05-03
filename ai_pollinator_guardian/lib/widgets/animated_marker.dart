import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AnimatedMarker extends StatefulWidget {
  final LatLng position;
  final String markerId;
  final BitmapDescriptor icon;
  final VoidCallback onTap;
  
  const AnimatedMarker({
    super.key,
    required this.position,
    required this.markerId,
    required this.icon,
    required this.onTap,
  });
  
  @override
  AnimatedMarkerState createState() => AnimatedMarkerState();
}

class AnimatedMarkerState extends State<AnimatedMarker> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Marker _marker;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    // 创建带有点击回调的 Marker
    _createMarker();
  }
  
  void _createMarker() {
    _marker = Marker(
      markerId: MarkerId(widget.markerId),
      position: widget.position,
      icon: widget.icon,
      onTap: () {
        _playAnimation();
        widget.onTap();
      },
    );
  }
  
  void _playAnimation() {
    _controller.reset();
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(AnimatedMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当 widget 属性变化时重新创建 marker
    if (oldWidget.position != widget.position || 
        oldWidget.markerId != widget.markerId || 
        oldWidget.icon != widget.icon) {
      _createMarker();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  Marker get marker => _marker;
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: const SizedBox(), // 仅作为动画容器，实际 Marker 通过 getter 向外暴露
    );
  }
}