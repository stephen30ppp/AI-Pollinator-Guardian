import 'package:flutter/material.dart';

class SightingImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final BorderRadius? borderRadius;

  const SightingImage({
    super.key,
    this.imageUrl,
    this.height = 200,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: imageUrl != null
          ? Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          : Container(
              height: height,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Icon(
                Icons.photo,
                size: 60,
                color: Colors.grey,
              ),
            ),
    );
  }
}