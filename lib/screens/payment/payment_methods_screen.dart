import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentController _controller = Get.find<PaymentController>();
  final TextEditingController _amountController = TextEditingController(text: '50.00');

  @override
  void initState() {
    super.initState();
    _controller.loadUserCredits();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Créditos'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCreditBalanceCard(),
            const SizedBox(height: 24),
            _buildAmountSelection(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditBalanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu saldo atual',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  'R\$ ${_controller.userCredits.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildAmountSelection() {
    final predefinedAmounts = [20.0, 50.0, 100.0, 200.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Valor a adicionar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: predefinedAmounts.length,
            itemBuilder: (context, index) {
              final amount = predefinedAmounts[index];
              final amountString = amount.toStringAsFixed(2);
              final isSelected = _amountController.text == amountString;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _amountController.text = amountString;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.5),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'R\$ ${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 400),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Valor personalizado',
            prefixText: 'R\$ ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 300),
          duration: const Duration(milliseconds: 400),
        ),
      ],
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha o método de pagamento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Opção de Google Pay (apenas para Android)
              if (Platform.isAndroid)
                _buildPaymentMethodItem(
                  icon: const Icon(Icons.payment, color: Colors.green),
                  title: 'Google Pay',
                  onTap: () => _processPaymentWithGooglePay(),
                ),

              // Opção de Apple Pay (apenas para iOS)
              if (Platform.isIOS)
                _buildPaymentMethodItem(
                  icon: const Icon(Icons.apple, color: Colors.black),
                  title: 'Apple Pay',
                  onTap: () => _processPaymentWithApplePay(),
                ),

              // Métodos tradicionais
              if (Platform.isAndroid || Platform.isIOS)
                const Divider(height: 1),

              _buildPaymentMethodItem(
                icon: Icon(Icons.credit_card, color: Theme.of(context).colorScheme.primary),
                title: 'Cartão de Crédito',
                onTap: () => _processPaymentWithCard(),
              ),
              const Divider(height: 1),
              _buildPaymentMethodItem(
                icon: const Icon(Icons.account_balance, color: Colors.green),
                title: 'Transferência Bancária',
                onTap: () => _processPaymentWithBankTransfer(),
              ),
              const Divider(height: 1),
              _buildPaymentMethodItem(
                icon: const Icon(Icons.pix, color: Colors.blue),
                title: 'PIX',
                onTap: () => _processPaymentWithPix(),
              ),
            ],
          ),
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 400),
          duration: const Duration(milliseconds: 400),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: icon,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _processPaymentWithGooglePay() async {
    await _processGenericPayment('Google Pay', (amount, description, serviceId, serviceType) async {
      return await _controller.processPaymentWithGooglePay(
        context: context,
        description: description,
        amount: amount,
        serviceId: serviceId,
        serviceType: serviceType,
      );
    });
  }

  Future<void> _processPaymentWithApplePay() async {
    await _processGenericPayment('Apple Pay', (amount, description, serviceId, serviceType) async {
      return await _controller.processPaymentWithApplePay(
        context: context,
        description: description,
        amount: amount,
        serviceId: serviceId,
        serviceType: serviceType,
      );
    });
  }

  Future<void> _processPaymentWithCard() async {
    // No momento apenas simulamos o pagamento com cartão através da adição de créditos
    await _processGenericPayment('Cartão de Crédito', (amount, description, serviceId, serviceType) async {
      await _controller.addCredits(amount);
      return 'card-payment-${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  Future<void> _processPaymentWithBankTransfer() async {
    // No momento apenas simulamos o pagamento com transferência bancária através da adição de créditos
    await _processGenericPayment('Transferência Bancária', (amount, description, serviceId, serviceType) async {
      await _controller.addCredits(amount);
      return 'bank-transfer-${DateTime.now().millisecondsSinceEpoch}';
    });
  }

  Future<void> _processPaymentWithPix() async {

  }

  // Método genérico para processamento de pagamentos
  Future<void> _processGenericPayment(
      String paymentMethod,
      Future<String> Function(double amount, String description, String serviceId, String serviceType) processFunction,
      ) async {
    try {
      final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;

      if (amount <= 0) {
        Get.snackbar(
          'Erro',
          'Por favor, insira um valor válido maior que zero.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Confirmar Pagamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Adicionar R\$ ${amount.toStringAsFixed(2)} em créditos?'),
              const SizedBox(height: 8),
              Text(
                'Você será redirecionado para o pagamento via $paymentMethod.',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final description = 'Compra de créditos: R\$ ${amount.toStringAsFixed(2)}';
        final serviceId = 'credits-${DateTime.now().millisecondsSinceEpoch}';

        // Processar pagamento
        final paymentId = await processFunction(amount, description, serviceId, 'credits');

        if (paymentId.isNotEmpty) {
          // Mostrar confirmação de sucesso
          await Get.dialog(
            AlertDialog(
              title: const Text('Pagamento Concluído'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Seus créditos foram adicionados com sucesso!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Novo saldo: R\$ ${_controller.userCredits.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );

          Get.back(); // Voltar para a tela anterior após o pagamento
        }
      }
    } catch (e) {
      debugPrint('Erro ao processar pagamento: $e');
      Get.snackbar(
        'Erro',
        'Ocorreu um erro ao processar o pagamento: ${e.toString().split(':').last}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}