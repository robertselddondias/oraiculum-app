import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomAmountSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isSmallScreen;
  final Function(double) onAmountChanged;

  const CustomAmountSection({
    super.key,
    required this.controller,
    required this.isSmallScreen,
    required this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ou Digite um Valor',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ex: 75,00',
            prefixIcon: Icon(Icons.attach_money, color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              try {
                final amount = double.parse(value.replaceAll(',', '.'));
                onAmountChanged(amount);
              } catch (_) {}
            }
          },
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }
}