import 'package:flutter/material.dart';
import 'package:ai_pollinator_guardian/utils/ring_painter.dart';

class ScoreRing extends StatelessWidget {
  final int percentage;

  const ScoreRing({
    super.key,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    Color ringColor = _getRingColor(percentage);

    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(80, 80),
            painter: ScoreRingPainter(
              percentage: percentage,
              activeColor: ringColor,
              inactiveColor: Colors.grey[300]!,
            ),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Center(
              child: Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ringColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRingColor(int percentage) {
    if (percentage < 30) {
      return Colors.red;
    } else if (percentage < 70) {
      return Colors.yellow[700]!;
    } else {
      return Colors.green;
    }
  }
}