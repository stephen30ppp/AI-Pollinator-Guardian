import 'package:flutter/material.dart';

class PlantTag extends StatelessWidget {
  final String tag;

  const PlantTag({
    super.key,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 12, color: Colors.green[700]),
      ),
    );
  }
}