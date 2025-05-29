import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/screens/payment/widgets/payment_header.dart';
import 'package:oraculum/screens/payment/widgets/credit_packages_section.dart';
import 'package:oraculum/screens/payment/widgets/custom_amount_section.dart';
import 'package:oraculum/screens/payment/widgets/payment_methods_section.dart';
import 'package:oraculum/screens/payment/widgets/pix_payment_view.dart';
import 'package:oraculum/screens/payment/widgets/payment_button.dart';
import 'package:oraculum/screens/payment/widgets/success_dialog.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen>
    with TickerProviderStateMixin {
  final PaymentController _paymentController = Get.find<PaymentController>();

  late AnimationController _animationController;

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

  Map<String, dynamic>? _selectedPackage;
  String _selectedPaymentMethod = '';
  final TextEditingController _customAmountController = TextEditingController();
  bool _isLoading = false;

  String? _pixQrCode;
  String? _pixTransactionId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _selectedPackage = _creditPackages.firstWhere((p) => p['popular'] == true);
    _animationController.forward();
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
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: PaymentHeader(
                paymentController: _paymentController,
                isSmallScreen: isSmallScreen,
                isTablet: isTablet,
              ),
            ),
          ),

          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pixQrCode != null
                  ? PixPaymentView(
                pixQrCode: _pixQrCode!,
                pixTransactionId: _pixTransactionId,
                onBack: () {
                  setState(() {
                    _pixQrCode = null;
                    _pixTransactionId = null;
                  });
                },
                onCheckStatus: _checkPixPaymentStatus,
                isLoading: _isLoading,
                isSmallScreen: isSmallScreen,
                isTablet: isTablet,
              )
                  : _buildMainContent(isTablet, isSmallScreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isTablet, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : isSmallScreen ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CreditPackagesSection(
            creditPackages: _creditPackages,
            selectedPackage: _selectedPackage,
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
            onPackageSelected: (package) {
              setState(() {
                _selectedPackage = package;
                _customAmountController.clear();
              });
            },
          ),
          const SizedBox(height: 24),

          CustomAmountSection(
            controller: _customAmountController,
            isSmallScreen: isSmallScreen,
            onAmountChanged: (amount) {
              setState(() {
                _selectedPackage = {
                  'amount': amount,
                  'description': 'Valor Personalizado',
                  'bonus': 0,
                  'popular': false,
                  'icon': Icons.edit,
                  'color': Theme.of(context).colorScheme.primary,
                };
              });
            },
          ),
          const SizedBox(height: 32),

          PaymentMethodsSection(
            paymentController: _paymentController,
            selectedPaymentMethod: _selectedPaymentMethod,
            isTablet: isTablet,
            isSmallScreen: isSmallScreen,
            onMethodSelected: (method) {
              setState(() {
                _selectedPaymentMethod = method;
              });
            },
          ),
          const SizedBox(height: 32),

          PaymentButton(
            selectedPackage: _selectedPackage,
            selectedPaymentMethod: _selectedPaymentMethod,
            isLoading: _isLoading,
            onPressed: _processPayment,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

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
        final cardId = _selectedPaymentMethod.replaceFirst('saved_card_', '');
        result = await _paymentController.processPaymentWithSavedCard(
          paymentMethodId: cardId,
          amount: amount,
          description: description,
          serviceId: serviceId,
          serviceType: 'credit_purchase',
        );
      } else {
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
      await Future.delayed(const Duration(seconds: 2));
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
    SuccessDialog.show(
      context: context,
      amount: _selectedPackage!['amount'],
      onContinue: () {
        Navigator.of(context).pop();
        Get.back();
      },
    );
  }
}