import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Widget que exibe o cabeçalho da tela do Mapa Astral
class BirthChartHeader extends StatelessWidget {
  final bool isSmallScreen;
  final bool isTablet;

  const BirthChartHeader({
    Key? key,
    required this.isSmallScreen,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mapa Astral Personalizado',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: isTablet ? 28 : isSmallScreen ? 20 : 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Descubra os segredos do seu nascimento e as influências planetárias em sua vida.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: isTablet ? 18 : isSmallScreen ? 14 : 16,
            height: 1.5,
          ),
        ),
      ],
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 800),
    ).slideY(
      begin: 0.2,
      end: 0,
      curve: Curves.easeOutQuad,
      duration: const Duration(milliseconds: 500),
    );
  }
}