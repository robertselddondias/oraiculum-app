import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oraculum/widgets/app_image.dart';

class AppAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final String? name;
  final Color? backgroundColor;
  final String? heroTag;

  const AppAvatar({
    Key? key,
    required this.imageUrl,
    required this.size,
    this.name,
    this.backgroundColor,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If no image URL is provided, display initials
    if (imageUrl.isEmpty) {
      return _buildInitialsAvatar();
    }

    // Use the base AppImage with circular border radius
    return AppImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      borderRadius: BorderRadius.circular(size / 2), // Circular
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      heroTag: heroTag,
      errorWidget: _buildInitialsAvatar(),
    );
  }

  Widget _buildInitialsAvatar() {
    // Extract initials from name or use a default
    final initials = name != null && name!.isNotEmpty
        ? name!.split(' ').map((part) => part.isNotEmpty ? part[0] : '').join().toUpperCase()
        : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.length > 2 ? initials.substring(0, 2) : initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4, // Scale font size with avatar size
          ),
        ),
      ),
    );
  }
}