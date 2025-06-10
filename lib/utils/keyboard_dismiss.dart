import 'package:flutter/material.dart';

class KeyboardDismiss extends StatelessWidget {
  final Widget child;

  const KeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // This will dismiss the keyboard when tapping anywhere outside text fields
        FocusScope.of(context).unfocus();
      },
      // Ensure gesture detector doesn't block interactions with its children
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}