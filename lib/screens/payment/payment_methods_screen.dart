import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/card_list_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentController _paymentController = Get.find<PaymentController>();
  final CardListController _cardListController = Get.find<CardListController>();

  // Lista de pacotes de créditos disponíveis
  final List<Map<String, dynamic>> _creditPackages = [
    {'amount': 20.0, 'description': 'Pacote Básico', 'bonus': 0},
    {'amount': 50.0, 'description': 'Pacote Médio', 'bonus': 5},
    {'amount': 100.0, 'description': 'Pacote Premium', 'bonus': 15},
    {'amount': 200.0, 'description': 'Pacote VIP', 'bonus': 40},
  ];

  // Pacote selecionado inicialmente
  Map<String, dynamic>? _selectedPackage;

  // Método de pagamento selecionado
  String _selectedPaymentMethod = 'Cartão de Crédito';

  // Controlador para valor personalizado
  final TextEditingController _customAmountController = TextEditingController();

  // Indicador de carregamento
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Definir o pacote médio como padrão
    _selectedPackage = _creditPackages[1];
    // Carregar cartões ao iniciar
    _loadCards();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  // Carregar cartões do usuário
  Future<void> _loadCards() async {
    await _cardListController.loadCards();
  }

  // Processar pagamento de acordo com o método selecionado
  Future<void> _processPayment() async {
    if (_selectedPackage == null) {
      Get.snackbar(
        'Erro',
        'Selecione um pacote de créditos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      double amount = _selectedPackage!['amount'];
      String description = 'Compra de créditos: ${_selectedPackage!['description']}';
      String serviceId = 'credit-purchase-${DateTime.now().millisecondsSinceEpoch}';

      String paymentId = await _paymentController.processPayment(
        context: context,
        description: description,
        amount: amount,
        serviceId: serviceId,
        serviceType: 'credit_purchase',
        paymentMethod: _selectedPaymentMethod,
      );

      if (paymentId.isNotEmpty) {
        Get.back(); // Voltar para a tela anterior após o pagamento bem-sucedido
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Falha ao processar o pagamento: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }@override
  Widget build(BuildContext context) {
    // Verificar se é modo escuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Créditos'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com saldo atual
            _buildHeader(isDarkMode),

            // Pacotes de créditos
            _buildCreditPackages(isDarkMode, isTablet),

            // Valor personalizado
            _buildCustomAmountSection(isDarkMode),

            // Métodos de pagamento
            _buildPaymentMethods(isDarkMode, isTablet),

            // Botão de confirmação
            _buildConfirmButton(isDarkMode),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Cabeçalho com saldo atual
  Widget _buildHeader(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seu Saldo Atual',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 10),
              Obx(() {
                return Text(
                  'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Escolha um valor para adicionar créditos',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  // Seção de pacotes de créditos
  Widget _buildCreditPackages(bool isDarkMode, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Pacotes de Créditos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.lightTextColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          isTablet
              ? GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _creditPackages.length,
            itemBuilder: (context, index) {
              return _buildCreditPackageCard(
                _creditPackages[index],
                isDarkMode,
              ).animate().fadeIn(
                duration: const Duration(milliseconds: 300),
                delay: Duration(milliseconds: index * 100),
              );
            },
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _creditPackages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildCreditPackageCard(
                  _creditPackages[index],
                  isDarkMode,
                ).animate().fadeIn(
                  duration: const Duration(milliseconds: 300),
                  delay: Duration(milliseconds: index * 100),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Card para pacote de créditos
  Widget _buildCreditPackageCard(Map<String, dynamic> package, bool isDarkMode) {
    final bool isSelected = _selectedPackage == package;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
          _customAmountController.clear(); // Limpar valor personalizado ao selecionar pacote
        });
      },
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        color: isDarkMode
            ? isSelected ? Colors.grey.shade800 : Colors.grey.shade900
            : isSelected ? Colors.white : Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ícone de seleção
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
                    : null,
              ),
              const SizedBox(width: 16),
              // Informações do pacote
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package['description'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${package['amount'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Bônus
              if (package['bonus'] > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${package['bonus']}% Bônus',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Seção de valor personalizado
  Widget _buildCustomAmountSection(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Valor Personalizado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.lightTextColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: 'Digite um valor personalizado',
              prefixIcon: const Icon(Icons.attach_money),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                try {
                  final amount = double.parse(value);
                  setState(() {
                    _selectedPackage = {
                      'amount': amount,
                      'description': 'Valor Personalizado',
                      'bonus': 0,
                    };
                  });
                } catch (_) {
                  // Ignorar se não for um número válido
                }
              } else {
                setState(() {
                  _selectedPackage = _creditPackages[1]; // Voltar ao pacote padrão
                });
              }
            },
          ),
        ],
      ),
    );
  }
  // Seção de métodos de pagamento
  Widget _buildPaymentMethods(bool isDarkMode, bool isTablet) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Text(
              'Método de Pagamento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : AppTheme.lightTextColor,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Cartão de crédito
          _buildPaymentMethodTile(
            icon: Icons.credit_card,
            title: 'Cartão de Crédito',
            subtitle: 'Pague com seu cartão cadastrado',
            isDarkMode: isDarkMode,
            isSelected: _selectedPaymentMethod == 'Cartão de Crédito',
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'Cartão de Crédito';
              });
            },
          ),

          // PIX - Novo método de pagamento
          _buildPaymentMethodTile(
            icon: Icons.qr_code,
            title: 'PIX',
            subtitle: 'Pagamento instantâneo',
            isDarkMode: isDarkMode,
            isSelected: _selectedPaymentMethod == 'PIX',
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'PIX';
              });
            },
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 400),
            delay: const Duration(milliseconds: 200),
          ),

          // Google Pay
          _buildPaymentMethodTile(
            icon: Icons.account_balance_wallet,
            title: 'Google Pay',
            subtitle: 'Pagamento rápido e seguro',
            isDarkMode: isDarkMode,
            isSelected: _selectedPaymentMethod == 'Google Pay',
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'Google Pay';
              });
            },
          ),

          // Apple Pay
          _buildPaymentMethodTile(
            icon: Icons.apple,
            title: 'Apple Pay',
            subtitle: 'Pagamento rápido e seguro',
            isDarkMode: isDarkMode,
            isSelected: _selectedPaymentMethod == 'Apple Pay',
            onTap: () {
              setState(() {
                _selectedPaymentMethod = 'Apple Pay';
              });
            },
          ),

          // Gerenciar cartões (mostrado apenas quando Cartão de Crédito está selecionado)
          if (_selectedPaymentMethod == 'Cartão de Crédito')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  Get.toNamed(AppRoutes.creditcardList);
                },
                icon: const Icon(
                  Icons.credit_card,
                  color: AppTheme.primaryColor,
                ),
                label: const Text(
                  'Gerenciar Cartões',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
            ),

          // Informações adicionais para o método PIX
          if (_selectedPaymentMethod == 'PIX')
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppTheme.infoColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sobre o pagamento via PIX',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Você receberá um QR Code para efetuar o pagamento. Os créditos serão adicionados automaticamente após a confirmação do pagamento.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(
              duration: const Duration(milliseconds: 300),
            ),
        ],
      ),
    );
  }

  // Tile para método de pagamento
  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      elevation: isSelected ? 2 : 0,
      color: isDarkMode
          ? isSelected ? Colors.grey.shade800 : Colors.grey.shade900
          : isSelected ? Colors.white : Colors.grey.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ícone de seleção
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                )
                    : null,
              ),
              const SizedBox(width: 16),
              // Ícone do método
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade700
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Informações do método
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : AppTheme.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // Botão de confirmação
  Widget _buildConfirmButton(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Comprar R\$ ${_selectedPackage != null ? _selectedPackage!['amount'].toStringAsFixed(2) : '0.00'}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}