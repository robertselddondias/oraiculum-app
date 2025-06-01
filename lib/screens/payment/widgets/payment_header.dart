import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class PaymentHeader extends StatelessWidget {
  final PaymentController paymentController;
  final bool isSmallScreen;
  final bool isTablet;

  const PaymentHeader({
    super.key,
    required this.paymentController,
    required this.isSmallScreen,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Expanded(
                child: Text(
                  'Adicionar Créditos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 26 : isSmallScreen ? 22 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          SizedBox(height: isTablet ? 24 : 20),
          Obx(() => Column(
            children: [
              Text(
                'Seu Saldo Atual',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${paymentController.userCredits.value.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 36 : isSmallScreen ? 28 : 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }
}