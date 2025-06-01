import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/screens/astrology/widgets/birth_chart_history_dialog.dart';
import 'package:oraculum/screens/astrology/widgets/birth_chart_action_buttons.dart';
import 'package:oraculum/screens/astrology/widgets/birth_chart_form_fields.dart';
import 'package:oraculum/screens/astrology/widgets/birth_chart_header.dart';
import 'package:oraculum/screens/astrology/widgets/birth_chart_info_card.dart';
import 'package:oraculum/screens/astrology/widgets/birth_chart_result_header.dart';
import 'package:oraculum/screens/astrology/widgets/birth_chart_submit_button.dart';
import 'package:oraculum/screens/astrology/widgets/interpretation_section.dart';
import 'package:oraculum/utils/zodiac_utils.dart';
import 'package:share_plus/share_plus.dart';

class BirthChartScreen extends StatefulWidget {
  const BirthChartScreen({Key? key}) : super(key: key);

  @override
  State<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> with SingleTickerProviderStateMixin {
  final HoroscopeController _controller = Get.find<HoroscopeController>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 30));
  final RxMap<String, dynamic> _chartResult = <String, dynamic>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasResult = false.obs;

  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _paymentController.loadUserCredits();
    _setupAnimations();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _topAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    _timeController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _generateChart() async {
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;
    _hasResult.value = false;

    try {
      final confirmedPurchase = await _showPaymentConfirmationDialog();

      if (!confirmedPurchase) {
        _isLoading.value = false;
        return;
      }

      final result = await _controller.getBirthChartInterpretation(
          _birthDateController.text,
          _timeController.text,
          _birthPlaceController.text,
          _nameController.text
      );

      _chartResult.value = result;
      _hasResult.value = result['success'] == true;

      if (!result['success']) {
        Get.snackbar(
          'Erro',
          result['message'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível gerar o mapa astral: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> _showPaymentConfirmationDialog() async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmação de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gerar um mapa astral custa R\$ ${_controller.birthChartCost.toStringAsFixed(2)}.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() => Text(
              'Seus créditos atuais: R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
              style: TextStyle(
                color: _paymentController.userCredits.value >= _controller.birthChartCost
                    ? Colors.green
                    : Colors.red,
              ),
            )),
            const SizedBox(height: 8),
            if (_paymentController.userCredits.value < _controller.birthChartCost)
              const Text(
                'Você não tem créditos suficientes. Adicione mais créditos para continuar.',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          if (_paymentController.userCredits.value < _controller.birthChartCost)
            ElevatedButton(
              onPressed: () {
                Get.back(result: false);
                Get.toNamed(AppRoutes.paymentMethods);
              },
              child: const Text('Adicionar Créditos'),
            )
          else
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Confirmar Pagamento'),
            ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showHistoryDialog(BuildContext context) async {
    return await BirthChartHistoryDialog.show(
      context: context,
      controller: _controller,
      onChartSelected: (chartData) {
        setState(() {
          if (chartData['birthDate'] != null) {
            _selectedDate = chartData['birthDate'] as DateTime;
          }
          _birthPlaceController.text = chartData['birthPlace'] ?? '';
          _timeController.text = chartData['birthTime'] ?? '';

          _chartResult.value = {
            'success': true,
            'interpretation': chartData['interpretation'] ?? 'Interpretação não disponível'
          };
          _hasResult.value = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final textFieldPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: const [
                  Color(0xFF392F5A),
                  Color(0xFF483D8B),
                  Color(0xFF8C6BAE),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              ...ZodiacUtils.buildStarParticles(context, 30),

              Column(
                children: [
                  _buildAppBar(context, isSmallScreen, isTablet),
                  Expanded(
                    child: Obx(() {
                      if (_hasResult.value) {
                        return _buildResultView(context, isSmallScreen, isTablet);
                      }
                      return _buildInputForm(context, isSmallScreen, isTablet, textFieldPadding);
                    }),
                  ),
                ],
              ),

              Obx(() => _isLoading.value
                  ? Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
                  : const SizedBox.shrink()
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isSmallScreen, bool isTablet) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : isTablet ? 24.0 : 20.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            tooltip: 'Voltar',
            splashRadius: 24,
          ),

          Expanded(
            child: Text(
              'Mapa Astral',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 20.0 : isTablet ? 24.0 : 22.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Histórico de Mapas Astrais',
            onPressed: () => Get.toNamed(AppRoutes.birthChartHistory),
            splashRadius: 24,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildInputForm(BuildContext context, bool isSmallScreen, bool isTablet, double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      physics: const BouncingScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BirthChartHeader(isSmallScreen: isSmallScreen, isTablet: isTablet),

            BirthChartInfoCard(
              controller: _controller,
              paymentController: _paymentController,
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
            ),

            const SizedBox(height: 24),

            BirthChartFormFields(
              nameController: _nameController,
              birthPlaceController: _birthPlaceController,
              timeController: _timeController,
              selectedDate: _selectedDate,
              onDateSelect: () => _selectDate(context),
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
              padding: padding,
              horoscopeController: _controller,
              birthDateController: _birthDateController,
            ),

            const SizedBox(height: 32),

            BirthChartSubmitButton(
              controller: _controller,
              isLoading: _isLoading.value,
              onPressed: _generateChart,
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context, bool isSmallScreen, bool isTablet) {
    final padding = isSmallScreen ? 12.0 : isTablet ? 24.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BirthChartResultHeader(
            name: _nameController.text,
            birthDate: _birthDateController.text,
            birthTime: _timeController.text,
            birthPlace: _birthPlaceController.text,
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          ),

          const SizedBox(height: 24),

          BirthChartInterpretation(
            interpretation: _chartResult['interpretation'] ?? '',
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          ),

          const SizedBox(height: 24),

          BirthChartActionButtons(
            onNewChart: () {
              _hasResult.value = false;
            },
            onShare: () {
              SharePlus.instance.share(
                  ShareParams(text: 'Meu mapa astral gerado no app Oraculum. Nascido em ${DateFormat('dd/MM/yyyy').format(_selectedDate)} às ${_timeController.text} em ${_birthPlaceController.text}.\n\nDescubra seu destino também!')
              );
            },
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }
}