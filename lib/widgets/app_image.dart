import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final Color? backgroundColor;
  final String? heroTag;

  const AppImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.loadingWidget,
    this.backgroundColor,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // If no image URL is provided, return the error widget
    if (imageUrl.isEmpty) {
      return _buildErrorContainer();
    }

    // Default border radius
    final radius = borderRadius ?? BorderRadius.circular(8);

    // Build the image with proper wrapping
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildLoadingContainer(),
      errorWidget: (context, url, error) => _buildErrorContainer(),
    );

    // Add hero animation if heroTag is provided
    if (heroTag != null) {
      imageWidget = Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }

    // Apply border radius if provided
    return ClipRRect(
      borderRadius: radius,
      child: imageWidget,
    );
  }

  Widget _buildLoadingContainer() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade200,
      child: loadingWidget ?? const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? Colors.grey.shade200,
      child: errorWidget ?? const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Colors.grey,
        ),
      ),
    );
  }
}