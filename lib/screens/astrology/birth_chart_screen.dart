import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class BirthChartScreen extends StatefulWidget {
  const BirthChartScreen({Key? key}) : super(key: key);

  @override
  State<BirthChartScreen> createState() => _BirthChartScreenState();
}

class _BirthChartScreenState extends State<BirthChartScreen> {
  final HoroscopeController _controller = Get.find<HoroscopeController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthPlaceController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 30)); // 30 anos por padrão
  final RxString _chartInterpretation = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxBool _hasResult = false.obs;

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
      final interpretation = await _controller.getBirthChartInterpretation(
          _selectedDate,
          _timeController.text,
          _birthPlaceController.text
      );

      _chartInterpretation.value = interpretation;
      _hasResult.value = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Astral'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildFormFields(),
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
                    'Informações Precisas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Para um mapa astral preciso, informe a data, hora e local de nascimento exatos.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nome
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome Completo',
            prefixIcon: Icon(Icons.person_outline),
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
              decoration: const InputDecoration(
                labelText: 'Data de Nascimento',
                prefixIcon: Icon(Icons.calendar_today),
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
          decoration: const InputDecoration(
            labelText: 'Hora de Nascimento (HH:MM)',
            prefixIcon: Icon(Icons.access_time),
            hintText: 'Ex: 15:30',
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
          decoration: const InputDecoration(
            labelText: 'Local de Nascimento',
            prefixIcon: Icon(Icons.location_on_outlined),
            hintText: 'Ex: São Paulo, SP, Brasil',
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
        label: Text(_isLoading.value ? 'Gerando Mapa...' : 'Gerar Mapa Astral'),
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
            elevation: 2,
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
                _chartInterpretation.value,
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
}