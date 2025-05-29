import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _ModernPaymentScreenState();
}

class _ModernPaymentScreenState extends State<PaymentMethodsScreen>
    with TickerProviderStateMixin {
  final PaymentController _paymentController = Get.find<PaymentController>();

  // Controlador de animação
  late AnimationController _animationController;

  // Lista de pacotes de créditos disponíveis
  final List<Map<String, dynamic>> _creditPackages = [
    {
      'amount': 10.0,
      'description': 'Pacote Starter',
      'bonus': 0,
      'popular': false,
      'icon': Icons.star_outline,
      'color': Colors.blue.shade300
    },
    {
      'amount': 25.0,
      'description': 'Pacote Básico',
      'bonus': 2,
      'popular': false,
      'icon': Icons.star_half,
      'color': Colors.green.shade300
    },
    {
      'amount': 50.0,
      'description': 'Pacote Popular',
      'bonus': 8,
      'popular': true,
      'icon': Icons.star,
      'color': Colors.orange.shade300
    },
    {
      'amount': 100.0,
      'description': 'Pacote Premium',
      'bonus': 20,
      'popular': false,
      'icon': Icons.workspace_premium,
      'color': Colors.purple.shade300
    },
    {
      'amount': 200.0,
      'description': 'Pacote VIP',
      'bonus': 50,
      'popular': false,
      'icon': Icons.diamond,
      'color': Colors.indigo.shade300
    },
  ];

  // Estados
  Map<String, dynamic>? _selectedPackage;
  String _selectedPaymentMethod = '';
  final TextEditingController _customAmountController = TextEditingController();
  bool _isLoading = false;

  // PIX
  String? _pixQrCode;
  String? _pixTransactionId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Selecionar pacote popular por padrão
    _selectedPackage = _creditPackages.firstWhere((p) => p['popular'] == true);

    // Iniciar animação
    _animationController.forward();

    // Carregar dados
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    await _paymentController.loadSavedCards();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Conteúdo principal
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _pixQrCode != null
                      ? _buildPixPaymentView()
                      : _buildMainContent(isTablet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const Expanded(
                child: Text(
                  'Adicionar Créditos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Para balancear o botão de voltar
            ],
          ),
          const SizedBox(height: 20),
          // Saldo atual
          Obx(() => Column(
            children: [
              const Text(
                'Seu Saldo Atual',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
  }

  Widget _buildMainContent(bool isTablet) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pacotes de créditos
          _buildCreditPackages(isTablet),
          const SizedBox(height: 24),

          // Valor personalizado
          _buildCustomAmountSection(),
          const SizedBox(height: 32),

          // Métodos de pagamento
          _buildPaymentMethods(isTablet),
          const SizedBox(height: 32),

          // Botão de pagamento
          _buildPaymentButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCreditPackages(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Escolha um Pacote',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),

        if (isTablet)
        // Layout em grid para tablets
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _creditPackages.length,
            itemBuilder: (context, index) {
              return _buildPackageCard(_creditPackages[index], index);
            },
          )
        else
        // Lista horizontal para celulares
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _creditPackages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildPackageCard(_creditPackages[index], index),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package, int index) {
    final isSelected = _selectedPackage == package;
    final popular = package['popular'] == true;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
          _customAmountController.clear();
        });
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
              colors: [package['color'], package['color'].withOpacity(0.7)]
          )
              : null,
          color: isSelected ? null : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: package['color'].withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            // Badge popular
            if (popular)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Conteúdo do card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    package['icon'],
                    size: 32,
                    color: isSelected ? Colors.white : package['color'],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    package['description'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'R\$ ${package['amount'].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                  ),

                  if (package['bonus'] > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${package['bonus']}% Bônus',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 600.ms)
          .slideX(begin: 0.3, end: 0),
    );
  }

  Widget _buildCustomAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ou Digite um Valor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _customAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Ex: 75,00',
            prefixIcon: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              try {
                final amount = double.parse(value.replaceAll(',', '.'));
                setState(() {
                  _selectedPackage = {
                    'amount': amount,
                    'description': 'Valor Personalizado',
                    'bonus': 0,
                    'popular': false,
                    'icon': Icons.edit,
                    'color': AppTheme.primaryColor,
                  };
                });
              } catch (_) {}
            }
          },
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPaymentMethods(bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Pagamento',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 16),

        Obx(() => Column(
          children: _paymentController.getAvailablePaymentMethods()
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final method = entry.value;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildPaymentMethodCard(method, index),
            );
          }).toList(),
        )),

        // Cartões salvos
        Obx(() {
          if (_paymentController.savedCards.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Cartões Salvos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),

                ..._paymentController.savedCards.map((card) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: _buildSavedCardTile(card),
                  );
                }),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method, int index) {
    final isSelected = _selectedPaymentMethod == method['id'];
    final available = method['available'] == true;

    return GestureDetector(
      onTap: available ? () {
        setState(() {
          _selectedPaymentMethod = method['id'];
        });
      } : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method['icon'],
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 24,
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: available ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: available ? Colors.grey.shade600 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.2, end: 0),
    );
  }

  Widget _buildSavedCardTile(Map<String, dynamic> card) {
    final isSelected = _selectedPaymentMethod == 'saved_card_${card['id']}';

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = 'saved_card_${card['id']}';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
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
                      color: Colors.grey.shade600,
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
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentButton() {
    final canProceed = _selectedPackage != null && _selectedPaymentMethod.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canProceed ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: canProceed ? 4 : 0,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          _selectedPackage != null
              ? 'Pagar R\$ ${_selectedPackage!['amount'].toStringAsFixed(2)}'
              : 'Selecione um pacote',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildPixPaymentView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          const Icon(
            Icons.qr_code_2,
            size: 64,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),

          const Text(
            'Pagamento via PIX',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Escaneie o QR Code abaixo para completar o pagamento',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // QR Code
          if (_pixQrCode != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: QrImageView(
                data: _pixQrCode!,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
            ),

          const SizedBox(height: 32),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Como pagar com PIX',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Abra o app do seu banco\n'
                      '2. Escolha a opção PIX\n'
                      '3. Escaneie o QR Code acima\n'
                      '4. Confirme o pagamento\n'
                      '5. Seus créditos serão adicionados automaticamente',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _pixQrCode = null;
                      _pixTransactionId = null;
                    });
                  },
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _checkPixPaymentStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Verificar Pagamento'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  // ===========================================
  // MÉTODOS DE PROCESSAMENTO
  // ===========================================

  Future<void> _processPayment() async {
    if (_selectedPackage == null || _selectedPaymentMethod.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = _selectedPackage!['amount'] as double;
      final description = 'Compra de créditos: ${_selectedPackage!['description']}';
      final serviceId = 'credit-purchase-${DateTime.now().millisecondsSinceEpoch}';

      String result = '';

      if (_selectedPaymentMethod == 'pix') {
        // Processar PIX
        final pixResult = await _paymentController.processPixPayment(
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: 'credit_purchase',
        );

        if (pixResult['success']) {
          setState(() {
            _pixQrCode = pixResult['pix_qr_code'];
            _pixTransactionId = pixResult['transaction_id'];
          });
        }
      } else if (_selectedPaymentMethod.startsWith('saved_card_')) {
        // Usar cartão salvo
        final cardId = _selectedPaymentMethod.replaceFirst('saved_card_', '');
        result = await _paymentController.processPaymentWithSavedCard(
          paymentMethodId: cardId,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: 'credit_purchase',
        );
      } else {
        // Outros métodos de pagamento
        result = await _paymentController.processPayment(
          context: context,
          description: description,
          amount: amount,
          serviceId: serviceId,
          serviceType: 'credit_purchase',
          paymentMethod: _selectedPaymentMethod,
        );
      }

      if (result.isNotEmpty && _pixQrCode == null) {
        // Pagamento bem-sucedido (exceto PIX que tem fluxo diferente)
        _showSuccessDialog();
      }
    } catch (e) {
      debugPrint('Erro ao processar pagamento: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkPixPaymentStatus() async {
    if (_pixTransactionId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Verificar status do pagamento PIX
      // Implementar lógica de verificação via webhook ou polling
      await Future.delayed(const Duration(seconds: 2));

      // Simular verificação bem-sucedida para demo
      _showSuccessDialog();
    } catch (e) {
      debugPrint('Erro ao verificar status do PIX: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível verificar o status do pagamento',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
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
              'Pagamento Realizado!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${_selectedPackage!['amount'].toStringAsFixed(2)} foram adicionados à sua conta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Continuar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================
  // MÉTODOS AUXILIARES
  // ===========================================

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