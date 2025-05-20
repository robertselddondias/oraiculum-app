import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class BirthChartResultHeader extends StatelessWidget {
  final String name;
  final DateTime birthDate;
  final String birthTime;
  final String birthPlace;
  final bool isSmallScreen;
  final bool isTablet;

  const BirthChartResultHeader({
    Key? key,
    required this.name,
    required this.birthDate,
    required this.birthTime,
    required this.birthPlace,
    required this.isSmallScreen,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardPadding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;
    final nameSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;
    final titleSize = isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0;
    final textSize = isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0;
    final iconSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;

    // Determinar o signo solar
    final sign = ZodiacUtils.getZodiacSignFromDate(birthDate);
    final signColor = ZodiacUtils.getSignColor(sign);

    return Card(
      elevation: isTablet ? 4 : 2,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: signColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome e Signo
            Row(
              children: [
                ZodiacUtils.buildSignAvatar(
                  context: context,
                  sign: sign,
                  size: isTablet ? 60 : isSmallScreen ? 40 : 50,
                  highlight: true,
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Mapa Astral' : name,
                        style: TextStyle(
                          fontSize: nameSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Signo Solar: $sign',
                        style: TextStyle(
                          fontSize: titleSize,
                          color: signColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 32, color: Colors.white24),

            // Informações de Nascimento
            Row(
              children: [
                // Data de Nascimento
                Expanded(
                  child: _buildInfoItem(
                    context: context,
                    icon: Icons.calendar_today,
                    title: 'Data',
                    value: DateFormat('dd/MM/yyyy').format(birthDate),
                    iconSize: iconSize,
                    titleSize: textSize - 2,
                    valueSize: textSize,
                  ),
                ),
                // Horário de Nascimento
                Expanded(
                  child: _buildInfoItem(
                    context: context,
                    icon: Icons.access_time,
                    title: 'Horário',
                    value: birthTime,
                    iconSize: iconSize,
                    titleSize: textSize - 2,
                    valueSize: textSize,
                  ),
                ),
              ],
            ),

            SizedBox(height: isTablet ? 16 : 12),

            // Local de Nascimento
            _buildInfoItem(
              context: context,
              icon: Icons.location_on,
              title: 'Local',
              value: birthPlace,
              iconSize: iconSize,
              titleSize: textSize - 2,
              valueSize: textSize,
            ),

            // Informações sobre o Elemento e Modalidade
            SizedBox(height: isTablet ? 20 : 16),
            Row(
              children: [
                // Elemento do Signo
                Expanded(
                  child: _buildElementItem(
                    context: context,
                    title: 'Elemento',
                    value: ZodiacUtils.getElement(sign),
                    iconSize: iconSize,
                    titleSize: textSize - 2,
                    valueSize: textSize,
                  ),
                ),
                // Modalidade do Signo
                Expanded(
                  child: _buildElementItem(
                    context: context,
                    title: 'Modalidade',
                    value: ZodiacUtils.getModality(sign),
                    iconSize: iconSize,
                    titleSize: textSize - 2,
                    valueSize: textSize,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 800),
    ).slideY(
      begin: 0.2,
      end: 0,
      curve: Curves.easeOutBack,
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildInfoItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required double iconSize,
    required double titleSize,
    required double valueSize,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.7),
          size: iconSize,
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: titleSize,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildElementItem({
    required BuildContext context,
    required String title,
    required String value,
    required double iconSize,
    required double titleSize,
    required double valueSize,
  }) {
    // Escolher o ícone com base no elemento ou modalidade
    IconData getElementIcon(String element) {
      switch (element.toLowerCase()) {
        case 'fogo':
          return Icons.local_fire_department;
        case 'terra':
          return Icons.landscape;
        case 'ar':
          return Icons.air;
        case 'água':
          return Icons.water_drop;
        case 'cardinal':
          return Icons.arrow_forward;
        case 'fixo':
          return Icons.square;
        case 'mutável':
          return Icons.change_circle;
        default:
          return Icons.question_mark;
      }
    }

    // Escolher a cor com base no elemento
    Color getElementColor(String element) {
      switch (element.toLowerCase()) {
        case 'fogo':
          return Colors.deepOrange;
        case 'terra':
          return Colors.green;
        case 'ar':
          return Colors.lightBlueAccent;
        case 'água':
          return Colors.blue;
        case 'cardinal':
          return Colors.red;
        case 'fixo':
          return Colors.indigo;
        case 'mutável':
          return Colors.purple;
        default:
          return Colors.grey;
      }
    }

    final elementIcon = getElementIcon(value);
    final elementColor = getElementColor(value);

    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: elementColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        border: Border.all(
          color: elementColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: titleSize,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                elementIcon,
                color: elementColor,
                size: iconSize,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}