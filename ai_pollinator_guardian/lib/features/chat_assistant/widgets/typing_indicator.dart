import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: const Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0.0),
          const SizedBox(width: 4),
          _buildDot(0.2),
          const SizedBox(width: 4),
          _buildDot(0.4),
        ],
      ),
    );
  }

  Widget _buildDot(double delay) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        const begin = 0.0;
        const end = -5.0;
        
        final value = _calculateDelayedValue(_animationController.value, delay);
        final translateY = begin + (end - begin) * _bounce(value);
        
        return Transform.translate(
          offset: Offset(0, translateY),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  double _calculateDelayedValue(double value, double delay) {
    return (value + delay) % 1.0;
  }

  double _bounce(double t) {
    if (t < 0.5) {
      return 4.0 * t * t * t;
    } else {
      final p = 2 * t - 2;
      return 0.5 * p * p * p + 1;
    }
  }
}