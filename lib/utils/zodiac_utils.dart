import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';

/// Classe utilitária para elementos relacionados aos signos do zodíaco
/// que são compartilhados em múltiplas telas do aplicativo
class ZodiacUtils {
  /// Lista com todos os signos do zodíaco na ordem tradicional
  static const List<String> allSigns = [
    'Áries', 'Touro', 'Gêmeos', 'Câncer',
    'Leão', 'Virgem', 'Libra', 'Escorpião',
    'Sagitário', 'Capricórnio', 'Aquário', 'Peixes'
  ];

  /// Retorna o elemento associado a um signo
  static String getElement(String sign) {
    final Map<String, String> signElements = {
      'Áries': 'Fogo', 'Leão': 'Fogo', 'Sagitário': 'Fogo',
      'Touro': 'Terra', 'Virgem': 'Terra', 'Capricórnio': 'Terra',
      'Gêmeos': 'Ar', 'Libra': 'Ar', 'Aquário': 'Ar',
      'Câncer': 'Água', 'Escorpião': 'Água', 'Peixes': 'Água',
    };

    return signElements[sign] ?? 'Desconhecido';
  }

  /// Retorna a modalidade/qualidade associada a um signo (Cardinal, Fixo, Mutável)
  static String getModality(String sign) {
    final Map<String, String> signModalities = {
      'Áries': 'Cardinal', 'Câncer': 'Cardinal', 'Libra': 'Cardinal', 'Capricórnio': 'Cardinal',
      'Touro': 'Fixo', 'Leão': 'Fixo', 'Escorpião': 'Fixo', 'Aquário': 'Fixo',
      'Gêmeos': 'Mutável', 'Virgem': 'Mutável', 'Sagitário': 'Mutável', 'Peixes': 'Mutável',
    };

    return signModalities[sign] ?? 'Desconhecido';
  }

  /// Obtém o planeta regente de um signo
  static String getRulingPlanet(String sign) {
    final Map<String, String> signRulers = {
      'Áries': 'Marte',
      'Touro': 'Vênus',
      'Gêmeos': 'Mercúrio',
      'Câncer': 'Lua',
      'Leão': 'Sol',
      'Virgem': 'Mercúrio',
      'Libra': 'Vênus',
      'Escorpião': 'Plutão',
      'Sagitário': 'Júpiter',
      'Capricórnio': 'Saturno',
      'Aquário': 'Urano',
      'Peixes': 'Netuno',
    };

    return signRulers[sign] ?? 'Desconhecido';
  }

  /// Retorna o período aproximado do signo (datas)
  static String getDateRange(String sign) {
    final Map<String, String> signDates = {
      'Áries': '21 de março - 19 de abril',
      'Touro': '20 de abril - 20 de maio',
      'Gêmeos': '21 de maio - 20 de junho',
      'Câncer': '21 de junho - 22 de julho',
      'Leão': '23 de julho - 22 de agosto',
      'Virgem': '23 de agosto - 22 de setembro',
      'Libra': '23 de setembro - 22 de outubro',
      'Escorpião': '23 de outubro - 21 de novembro',
      'Sagitário': '22 de novembro - 21 de dezembro',
      'Capricórnio': '22 de dezembro - 19 de janeiro',
      'Aquário': '20 de janeiro - 18 de fevereiro',
      'Peixes': '19 de fevereiro - 20 de março',
    };

    return signDates[sign] ?? 'Período desconhecido';
  }

  /// Determina o signo com base na data de nascimento
  static String getZodiacSignFromDate(DateTime birthDate) {
    final day = birthDate.day;
    final month = birthDate.month;

    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquário';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Peixes';
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Áries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Touro';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gêmeos';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Câncer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leão';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgem';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Escorpião';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagitário';

    return 'Capricórnio';
  }

  /// Widget para exibir a imagem do signo
  static Widget buildZodiacImage(String sign, {double? size, Color? color}) {
    // Normaliza o nome do signo para corresponder ao nome do arquivo
    final signAssetName = getSignAssetName(sign);

    try {
      return Image.asset(
        'assets/images/zodiac/$signAssetName.png',
        width: size,
        height: size,
        color: color, // Aplicar uma cor de filtro, se fornecida
        errorBuilder: (context, error, stackTrace) {
          // Fallback para ícone em caso de erro no carregamento da imagem
          return Icon(
            getZodiacFallbackIcon(sign),
            size: size,
            color: color ?? getSignColor(sign),
          );
        },
      );
    } catch (e) {
      // Fallback para ícone em caso de exceção
      return Icon(
        getZodiacFallbackIcon(sign),
        size: size,
        color: color ?? getSignColor(sign),
      );
    }
  }

  /// Função para normalizar o nome do signo para o nome do arquivo
  static String getSignAssetName(String sign) {
    switch (sign.toLowerCase()) {
      case 'áries':
        return 'aries';
      case 'touro':
        return 'touro';
      case 'gêmeos':
        return 'gemeos';
      case 'câncer':
        return 'cancer';
      case 'leão':
        return 'leao';
      case 'virgem':
        return 'virgem';
      case 'libra':
        return 'libra';
      case 'escorpião':
        return 'escorpiao';
      case 'sagitário':
        return 'sagitario';
      case 'capricórnio':
        return 'capricornio';
      case 'aquário':
        return 'aquario';
      case 'peixes':
        return 'peixes';
      default:
        return sign.toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('â', 'a')
            .replaceAll('ã', 'a')
            .replaceAll('à', 'a')
            .replaceAll('é', 'e')
            .replaceAll('ê', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ô', 'o')
            .replaceAll('õ', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ç', 'c');
    }
  }

  /// Ícones de fallback caso a imagem não seja encontrada
  static IconData getZodiacFallbackIcon(String sign) {
    switch (sign) {
      case 'Áries':
        return Icons.fitness_center;
      case 'Touro':
        return Icons.spa;
      case 'Gêmeos':
        return Icons.people;
      case 'Câncer':
        return Icons.home;
      case 'Leão':
        return Icons.star;
      case 'Virgem':
        return Icons.healing;
      case 'Libra':
        return Icons.balance;
      case 'Escorpião':
        return Icons.psychology;
      case 'Sagitário':
        return Icons.explore;
      case 'Capricórnio':
        return Icons.landscape;
      case 'Aquário':
        return Icons.waves;
      case 'Peixes':
        return Icons.water;
      default:
        return Icons.stars;
    }
  }

  /// Função para obter a cor associada a cada signo
  static Color getSignColor(String sign) {
    switch (sign) {
      case 'Áries':
        return Colors.red;
      case 'Touro':
        return Colors.green.shade700;
      case 'Gêmeos':
        return Colors.amberAccent.shade700;
      case 'Câncer':
        return Colors.blue.shade300;
      case 'Leão':
        return Colors.orange;
      case 'Virgem':
        return Colors.green.shade400;
      case 'Libra':
        return Colors.pink.shade300;
      case 'Escorpião':
        return Colors.red.shade900;
      case 'Sagitário':
        return Colors.purple.shade300;
      case 'Capricórnio':
        return Colors.brown.shade700;
      case 'Aquário':
        return Colors.blueAccent;
      case 'Peixes':
        return Colors.indigo.shade300;
      default:
        return Colors.deepPurple;
    }
  }

  /// Função utilitária para criar efeitos de partículas/estrelas para fundos astrológicos
  static List<Widget> buildStarParticles(BuildContext context, int count, {double maxHeight = 180}) {
    final random = Random(DateTime.now().millisecondsSinceEpoch);
    final screenWidth = MediaQuery.of(context).size.width;
    final particles = <Widget>[];

    for (var i = 0; i < count; i++) {
      final size = random.nextDouble() * 2 + 1.0; // Entre 1.0 e 3.0
      final left = random.nextDouble() * screenWidth;
      final top = random.nextDouble() * maxHeight;
      final opacity = random.nextDouble() * 0.6 + 0.4; // Entre 0.4 e 1.0
      final delay = random.nextInt(3000); // Entre 0 e 3000 ms

      particles.add(
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity),
              shape: BoxShape.circle,
            ),
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(reverse: true),
          delay: Duration(milliseconds: delay),
        ).fadeIn(
          duration: const Duration(milliseconds: 1500),
        ).fadeOut(
          delay: const Duration(milliseconds: 1500),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }

    return particles;
  }

  /// Widget para exibir um avatar de signo (círculo com imagem e bordas)
  static Widget buildSignAvatar({
    required BuildContext context,
    required String sign,
    required double size,
    Color? borderColor,
    Color? backgroundColor,
    bool highlight = false,
    VoidCallback? onTap,
  }) {
    final signColor = getSignColor(sign);
    final actualBorderColor = borderColor ?? signColor;
    final actualBackgroundColor = backgroundColor ?? signColor.withOpacity(0.1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: actualBackgroundColor,
          border: Border.all(
            color: actualBorderColor.withOpacity(highlight ? 1.0 : 0.3),
            width: highlight ? 2.0 : 1.0,
          ),
          boxShadow: highlight ? [
            BoxShadow(
              color: actualBorderColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Center(
          child: buildZodiacImage(sign, size: size * 0.6),
        ),
      ),
    );
  }

  /// Widget para exibir um card de signo
  static Widget buildSignCard({
    required BuildContext context,
    required String sign,
    bool isSelected = false,
    VoidCallback? onTap,
    double? height,
    double? width,
    bool showDetails = false,
  }) {
    final color = getSignColor(sign);
    final element = getElement(sign);
    final dateRange = getDateRange(sign);

    final cardHeight = height ?? 160.0;
    final cardWidth = width ?? 120.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: cardHeight,
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isSelected ? color.withOpacity(0.7) : Theme.of(context).cardColor,
              isSelected ? color.withOpacity(0.9) : Theme.of(context).cardColor,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.4) : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              spreadRadius: isSelected ? 1 : 0,
            ),
          ],
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSignAvatar(
              context: context,
              sign: sign,
              size: cardWidth * 0.45,
              highlight: isSelected,
              borderColor: isSelected ? Colors.white : color,
              backgroundColor: isSelected ? color.withOpacity(0.3) : color.withOpacity(0.1),
            ),
            const SizedBox(height: 12),
            Text(
              sign,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : null,
              ),
              textAlign: TextAlign.center,
            ),
            if (showDetails) ...[
              const SizedBox(height: 4),
              Text(
                element,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white.withOpacity(0.8) : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                dateRange,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white.withOpacity(0.7) : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Widget para exibir uma lista horizontal de signos
  static Widget buildSignsRow({
    required BuildContext context,
    required List<String> signs,
    required String currentSign,
    required Function(String) onSignTap,
    double? height,
    double? cardWidth,
    bool showDetails = false,
    bool showScrollbar = true,
  }) {
    return Container(
      height: height ?? 160.0,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: signs.length,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final sign = signs[index];
                final isSelected = sign == currentSign;

                return buildSignCard(
                  context: context,
                  sign: sign,
                  isSelected: isSelected,
                  width: cardWidth,
                  showDetails: showDetails,
                  onTap: () => onSignTap(sign),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 50 * index),
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
          ),
          if (showScrollbar)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              height: 4,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: signs.length,
                itemBuilder: (context, index) {
                  final sign = signs[index];
                  final isSelected = sign == currentSign;

                  return Container(
                    width: 30,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? getSignColor(currentSign)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Simular um score de compatibilidade baseado nos signos
  static double calculateCompatibilityScore(String sign1, String sign2) {
    // Compatibilidade por elementos
    final element1 = getElement(sign1);
    final element2 = getElement(sign2);

    // Matriz de compatibilidade entre elementos
    Map<String, Map<String, double>> elementCompatibility = {
      'Fogo': {'Fogo': 0.8, 'Terra': 0.4, 'Ar': 0.9, 'Água': 0.3},
      'Terra': {'Fogo': 0.4, 'Terra': 0.7, 'Ar': 0.5, 'Água': 0.9},
      'Ar': {'Fogo': 0.9, 'Terra': 0.5, 'Ar': 0.8, 'Água': 0.4},
      'Água': {'Fogo': 0.3, 'Terra': 0.9, 'Ar': 0.4, 'Água': 0.8},
    };

    // Compatibilidades específicas de alguns signos
    Map<String, Map<String, double>> specialCompatibility = {
      'Áries': {'Libra': 0.9, 'Leão': 0.85},
      'Touro': {'Escorpião': 0.85, 'Câncer': 0.9},
      'Gêmeos': {'Sagitário': 0.85, 'Aquário': 0.9},
      'Câncer': {'Capricórnio': 0.85, 'Peixes': 0.9},
      'Leão': {'Aquário': 0.85, 'Sagitário': 0.9},
      'Virgem': {'Peixes': 0.85, 'Escorpião': 0.9},
      'Libra': {'Áries': 0.85, 'Aquário': 0.9},
      'Escorpião': {'Touro': 0.85, 'Câncer': 0.9},
      'Sagitário': {'Gêmeos': 0.85, 'Áries': 0.9},
      'Capricórnio': {'Câncer': 0.85, 'Touro': 0.9},
      'Aquário': {'Leão': 0.85, 'Libra': 0.9},
      'Peixes': {'Virgem': 0.85, 'Câncer': 0.9},
    };

    // Verificar se há uma compatibilidade especial entre esses signos
    if (specialCompatibility.containsKey(sign1) &&
        specialCompatibility[sign1]!.containsKey(sign2)) {
      return specialCompatibility[sign1]![sign2]!;
    }
    if (specialCompatibility.containsKey(sign2) &&
        specialCompatibility[sign2]!.containsKey(sign1)) {
      return specialCompatibility[sign2]![sign1]!;
    }

    // Caso contrário, usar a compatibilidade por elementos
    if (elementCompatibility.containsKey(element1) &&
        elementCompatibility[element1]!.containsKey(element2)) {
      return elementCompatibility[element1]![element2]!;
    }

    // Valor padrão caso algo dê errado
    return 0.7;
  }

  /// Widget para exibir uma barra de compatibilidade entre signos
  static Widget buildCompatibilityBar({
    required BuildContext context,
    required double score,
    required bool isSmallScreen,
    required AnimationController animationController,
  }) {
    // Determinar cor baseada no score
    Color barColor;
    String compatibilityText;

    if (score < 0.3) {
      barColor = Colors.red;
      compatibilityText = 'Desafiadora';
    } else if (score < 0.6) {
      barColor = Colors.orangeAccent;
      compatibilityText = 'Moderada';
    } else if (score < 0.8) {
      barColor = Colors.lightGreenAccent;
      compatibilityText = 'Boa';
    } else {
      barColor = Colors.green;
      compatibilityText = 'Excelente';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Compatibilidade: $compatibilityText',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            Text(
              '${(score * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth * score,
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [barColor.withOpacity(0.7), barColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                  ).animate(controller: animationController)
                      .custom(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutQuart,
                    builder: (context, value, child) {
                      return Container(
                        width: constraints.maxWidth * score * value,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor.withOpacity(0.7), barColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}