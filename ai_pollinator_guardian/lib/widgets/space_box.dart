import 'package:flutter/material.dart';

/// Space Box Component
/// 
/// This component is a simple wrapper around SizedBox, used to provide a consistent layout spacing experience
class SpaceBox extends StatelessWidget {
  final double width;
  final double height;
  
  /// Creates a fixed-size empty space
  /// 
  /// [width] The width of the space
  /// [height] The height of the space
  const SpaceBox({super.key, this.width = 0, this.height = 0});
  
  /// Creates a vertical spacing
  factory SpaceBox.vertical(double height) => SpaceBox(height: height);
  
  /// Creates a horizontal spacing
  factory SpaceBox.horizontal(double width) => SpaceBox(width: width);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height);
  }
}