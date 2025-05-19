import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oraculum/widgets/app_image.dart';

class AppCardImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? overlay;
  final bool addGradientOverlay;
  final String? heroTag;

  const AppCardImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.overlay,
    this.addGradientOverlay = false,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        // Base image
        AppImage(
          imageUrl: imageUrl,
          width: width,
          height: height,
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          heroTag: heroTag,
        ),

        // Optional gradient overlay for better text visibility
        if (addGradientOverlay)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),

        // Custom overlay widget if provided
        if (overlay != null)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: borderRadius ?? BorderRadius.circular(12),
              child: overlay!,
            ),
          ),
      ],
    );
  }
}