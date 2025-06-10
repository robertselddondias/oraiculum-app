import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';

class BirthChartSubmitButton extends StatelessWidget {
  final HoroscopeController controller;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isSmallScreen;
  final bool isTablet;

  const BirthChartSubmitButton({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onPressed,
    required this.isSmallScreen,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final buttonHeight = isTablet ? 60.0 : isSmallScreen ? 50.0 : 56.0;
    final fontSize = isTablet ? 18.0 : isSmallScreen ? 15.0 : 16.0;
    final iconSize = isTablet ? 28.0 : isSmallScreen ? 22.0 : 24.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: isTablet ? 3 : 2,
          ),
        )
            : Icon(
          Icons.public,
          size: iconSize,
        ),
        label: Text(
          isLoading ? 'Gerando Mapa Astral...' : 'Gerar Mapa Astral',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : 12,
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 800),
      duration: const Duration(milliseconds: 500),
    ).scale(
      begin: const Offset(0.95, 0.95),
      end: const Offset(1, 1),
      duration: const Duration(milliseconds: 300),
    );
  }
}