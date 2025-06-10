import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class PaymentMethodsSection extends StatelessWidget {
  final PaymentController paymentController;
  final String selectedPaymentMethod;
  final bool isTablet;
  final bool isSmallScreen;
  final Function(String) onMethodSelected;

  const PaymentMethodsSection({
    super.key,
    required this.paymentController,
    required this.selectedPaymentMethod,
    required this.isTablet,
    required this.isSmallScreen,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Método de Pagamento',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        Obx(() => Column(
          children: paymentController.getAvailablePaymentMethods()
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final method = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentMethodCard(context, method, index),
            );
          }).toList(),
        )),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPaymentMethodCard(BuildContext context, Map<String, dynamic> method, int index) {
    final isSelected = selectedPaymentMethod == method['id'];
    final available = method['available'] == true;

    return GestureDetector(
      onTap: available ? () => onMethodSelected(method['id']) : null,
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: isSmallScreen ? 40 : 50,
              height: isSmallScreen ? 40 : 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method['icon'],
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: isSmallScreen ? 20 : 24,
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'],
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: available ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method['description'],
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      color: available ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: isSmallScreen ? 20 : 24,
              ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildSavedCardTile(BuildContext context, Map<String, dynamic> card) {
    final isSelected = selectedPaymentMethod == 'saved_card_${card['id']}';

    return GestureDetector(
      onTap: () => onMethodSelected('saved_card_${card['id']}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card,
              color: _getCardBrandColor(card['brand']),
              size: 24,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '**** ${card['last4']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${card['brand'].toUpperCase()} • ${card['expMonth']}/${card['expYear']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            if (card['isDefault'] == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Padrão',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Color _getCardBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'amex':
        return Colors.green;
      case 'elo':
        return Colors.yellow.shade700;
      default:
        return Colors.grey;
    }
  }
}