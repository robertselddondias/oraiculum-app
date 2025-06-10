import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PaymentButton extends StatelessWidget {
  final Map<String, dynamic>? selectedPackage;
  final String selectedPaymentMethod;
  final bool isLoading;
  final VoidCallback onPressed;
  final bool isSmallScreen;

  const PaymentButton({
    super.key,
    required this.selectedPackage,
    required this.selectedPaymentMethod,
    required this.isLoading,
    required this.onPressed,
    required this.isSmallScreen,
  });

  @override
  Widget build(BuildContext context) {
    final canProceed = selectedPackage != null && selectedPaymentMethod.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      child: ElevatedButton(
        onPressed: canProceed ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canProceed ? 4 : 0,
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          selectedPackage != null
              ? 'Pagar R\$ ${selectedPackage!['amount'].toStringAsFixed(2)}'
              : 'Selecione um pacote',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0);
  }
}