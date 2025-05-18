import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';

class BirthChartScreen extends StatefulWidget {
  const BirthChartScreen({Key? key}) : super(key: key);

  @override
  State<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> {
  final HoroscopeController _controller = Get.find<HoroscopeController>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 30)); // 30 anos por padrão
  final RxMap<String, dynamic> _chartResult = <String, dynamic>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasResult = false.obs;

  @override
  void initState() {
    super.initState();
    // Carregar créditos do usuário
    _paymentController.loadUserCredits();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthPlaceController.dispose();
    _timeController.dispose();
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
      // Verificar se tem créditos suficientes e mostrar diálogo de confirmação
      final confirmedPurchase = await _showPaymentConfirmationDialog();

      if (!confirmedPurchase) {
        _isLoading.value = false;
        return;
      }

      // Gerar o mapa astral
      final result = await _controller.getBirthChartInterpretation(
          _selectedDate,
          _timeController.text,
          _birthPlaceController.text
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Astral'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Histórico de Mapas Astrais',
            onPressed: () => _showHistoryDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (_hasResult.value) {
          return _buildResultView();
        }

        return _buildInputForm();
      }),
    );
  }

  Widget _buildInputForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final textFieldPadding = isSmallScreen ? 12.0 : 16.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(textFieldPadding),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildFormFields(isSmallScreen, textFieldPadding),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mapa Astral Personalizado',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Descubra os segredos do seu nascimento e as influências planetárias em sua vida.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    ).animate().fadeIn().slideY(
      begin: 0.2,
      end: 0,
      curve: Curves.easeOutQuad,
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mapa Astral Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Para gerar um mapa astral completo é necessário um pagamento de R\$ ${_controller.birthChartCost.toStringAsFixed(2)}.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() => Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: _paymentController.userCredits.value >= _controller.birthChartCost
                      ? Colors.green
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Seus créditos: R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: _paymentController.userCredits.value >= _controller.birthChartCost
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_paymentController.userCredits.value < _controller.birthChartCost)
                  TextButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Adicionar'),
                  ),
              ],
            )),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildFormFields(bool isSmallScreen, double padding) {
    final labelTextStyle = TextStyle(
      fontSize: isSmallScreen ? 14.0 : 16.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nome Completo',
            prefixIcon: const Icon(Icons.person_outline),
            contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
            labelStyle: labelTextStyle,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe seu nome';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Data de nascimento
        GestureDetector(
          onTap: () => _selectDate(context),
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Data de Nascimento',
                prefixIcon: const Icon(Icons.calendar_today),
                contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
                labelStyle: labelTextStyle,
              ),
              controller: TextEditingController(
                text: DateFormat('dd/MM/yyyy').format(_selectedDate),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione a data de nascimento';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Hora de nascimento
        TextFormField(
          controller: _timeController,
          decoration: InputDecoration(
            labelText: 'Hora de Nascimento (HH:MM)',
            prefixIcon: const Icon(Icons.access_time),
            hintText: 'Ex: 15:30',
            contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
            labelStyle: labelTextStyle,
          ),
          keyboardType: TextInputType.datetime,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe a hora de nascimento';
            }

            // Validar formato da hora
            final RegExp timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):([0-5][0-9])$');
            if (!timeRegex.hasMatch(value)) {
              return 'Formato inválido. Use HH:MM (Ex: 15:30)';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),

        // Local de nascimento
        TextFormField(
          controller: _birthPlaceController,
          decoration: InputDecoration(
            labelText: 'Local de Nascimento',
            prefixIcon: const Icon(Icons.location_on_outlined),
            hintText: 'Ex: São Paulo, SP, Brasil',
            contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
            labelStyle: labelTextStyle,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, informe o local de nascimento';
            }
            return null;
          },
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: Obx(() => ElevatedButton.icon(
        onPressed: _isLoading.value ? null : _generateChart,
        icon: _isLoading.value
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(Icons.auto_graph),
        label: Text(_isLoading.value ? 'Gerando Mapa...' : 'Gerar Mapa Astral (R\$ ${_controller.birthChartCost.toStringAsFixed(2)})'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      )),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 500),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com os dados
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    _nameController.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nascido(a) em ${DateFormat('dd/MM/yyyy').format(_selectedDate)} às ${_timeController.text}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    _birthPlaceController.text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPlanetIndicator(
                        icon: Icons.wb_sunny,
                        title: 'Sol',
                        sign: 'Áries', // Isso seria dinâmico em uma versão completa
                      ),
                      _buildPlanetIndicator(
                        icon: Icons.nights_stay,
                        title: 'Lua',
                        sign: 'Câncer', // Isso seria dinâmico em uma versão completa
                      ),
                      _buildPlanetIndicator(
                        icon: Icons.arrow_upward,
                        title: 'Ascendente',
                        sign: 'Leão', // Isso seria dinâmico em uma versão completa
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            duration: const Duration(milliseconds: 500),
          ),

          const SizedBox(height: 24),

          // Título da interpretação
          const Text(
            'Interpretação do Mapa Astral',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 500),
          ),

          const SizedBox(height: 16),

          // Interpretação
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _chartResult['interpretation'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ).animate().fadeIn(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 500),
          ),

          const SizedBox(height: 24),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _hasResult.value = false;
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nova Consulta'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implementar compartilhamento
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(
            delay: const Duration(milliseconds: 500),
            duration: const Duration(milliseconds: 500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanetIndicator({
    required IconData icon,
    required String title,
    required String sign,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        Text(
          sign,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Dialog para mostrar o histórico de mapas astrais
  Future<void> _showHistoryDialog(BuildContext context) async {
    try {
      // Mostrar carregando
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Buscar os mapas astrais do usuário
      final birthCharts = await _controller.getUserBirthCharts();

      // Remover o diálogo de carregamento
      Get.back();

      if (birthCharts.isEmpty) {
        Get.dialog(
          AlertDialog(
            title: const Text('Histórico de Mapas Astrais'),
            content: const Text('Você ainda não gerou nenhum mapa astral.'),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
        return;
      }

      // Mostrar lista de mapas astrais
      Get.dialog(
        AlertDialog(
          title: const Text('Histórico de Mapas Astrais'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: birthCharts.length,
              itemBuilder: (context, index) {
                final chart = birthCharts[index];
                final date = chart['birthDate'] != null
                    ? DateFormat('dd/MM/yyyy').format((chart['birthDate'] as DateTime))
                    : 'Data desconhecida';
                final place = chart['birthPlace'] ?? 'Local desconhecido';
                final time = chart['birthTime'] ?? 'Hora desconhecida';
                final createdAt = chart['createdAt'] != null
                    ? DateFormat('dd/MM/yyyy').format((chart['createdAt'] as DateTime))
                    : 'Data desconhecida';

                return Card(
                  child: ListTile(
                    title: Text('Mapa Astral - $date'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Local: $place'),
                        Text('Hora: $time'),
                        Text('Gerado em: $createdAt'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        // Fechar o diálogo atual
                        Get.back();

                        // Mostrar a interpretação completa
                        Get.dialog(
                          AlertDialog(
                            title: Text('Mapa Astral - $date'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Local: $place'),
                                  Text('Hora: $time'),
                                  Text('Gerado em: $createdAt'),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Interpretação:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(chart['interpretation'] ?? 'Interpretação não disponível'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: const Text('Fechar'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      // Fechar o diálogo atual
                      Get.back();

                      // Preencher o formulário com os dados deste mapa astral
                      setState(() {
                        if (chart['birthDate'] != null) {
                          _selectedDate = chart['birthDate'] as DateTime;
                        }
                        _birthPlaceController.text = chart['birthPlace'] ?? '';
                        _timeController.text = chart['birthTime'] ?? '';

                        // Mostrar a interpretação
                        _chartResult.value = {
                          'success': true,
                          'interpretation': chart['interpretation'] ?? 'Interpretação não disponível'
                        };
                        _hasResult.value = true;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Fechar'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Remover o diálogo de carregamento se houver erro
      Get.back();

      Get.snackbar(
        'Erro',
        'Não foi possível carregar o histórico de mapas astrais: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}