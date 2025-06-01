import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BirthChartActionButtons extends StatelessWidget {
  final VoidCallback onNewChart;
  final VoidCallback onShare;
  final bool isSmallScreen;
  final bool isTablet;

  const BirthChartActionButtons({
    super.key,
    required this.onNewChart,
    required this.onShare,
    required this.isSmallScreen,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = isTablet ? 56.0 : isSmallScreen ? 48.0 : 52.0;
    final fontSize = isTablet ? 16.0 : isSmallScreen ? 14.0 : 15.0;
    final iconSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;
    final borderRadius = isTablet ? 20.0 : 16.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: onNewChart,
                  icon: Icon(Icons.refresh, size: iconSize),
                  label: Text(
                    'Nova Consulta',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 16),
            Expanded(
              child: SizedBox(
                height: buttonHeight,
                child: ElevatedButton.icon(
                  onPressed: onShare,
                  icon: Icon(Icons.share, size: iconSize),
                  label: Text(
                    'Compartilhar',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(borderRadius),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 500),
      duration: const Duration(milliseconds: 500),
    );
  }
}