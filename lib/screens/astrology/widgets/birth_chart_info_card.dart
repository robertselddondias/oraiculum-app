import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

/// Widget que exibe informações sobre o custo do Mapa Astral e créditos do usuário
class BirthChartInfoCard extends StatelessWidget {
  final HoroscopeController controller;
  final PaymentController paymentController;
  final bool isSmallScreen;
  final bool isTablet;

  const BirthChartInfoCard({
    Key? key,
    required this.controller,
    required this.paymentController,
    required this.isSmallScreen,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardPadding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;
    final titleSize = isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0;
    final textSize = isTablet ? 15.0 : isSmallScreen ? 12.0 : 14.0;
    final iconSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;

    return Card(
      elevation: isTablet ? 4 : 2,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: iconSize,
                  ),
                ),
                SizedBox(width: isTablet ? 16 : 12),
                Expanded(
                  child: Text(
                    'Informações do Serviço',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: Colors.amber,
                  size: iconSize,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Text(
                  'Custo do Mapa Astral:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: textSize,
                  ),
                ),
                const Spacer(),
                Text(
                  'R\$ ${controller.birthChartCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: textSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Obx(() {
              final hasEnoughCredits = paymentController.userCredits.value >= controller.birthChartCost;
              return Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet,
                    color: hasEnoughCredits ? Colors.green : Colors.red,
                    size: iconSize,
                  ),
                  SizedBox(width: isTablet ? 12 : 8),
                  Text(
                    'Seus créditos:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'R\$ ${paymentController.userCredits.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: hasEnoughCredits ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: textSize,
                    ),
                  ),
                ],
              );
            }),
            SizedBox(height: isTablet ? 16 : 12),
            const Divider(height: 1, color: Colors.white24),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'Seu mapa astral será gerado com base nas informações fornecidas. '
                  'Quanto mais precisos forem os dados de nascimento, mais acurada será a análise.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: textSize - 1,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }
}