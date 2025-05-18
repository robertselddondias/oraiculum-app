import 'package:oraculum/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({Key? key}) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final MediumController _mediumController = Get.find<MediumController>();
  final PaymentController _paymentController = Get.find<PaymentController>();

  final List<int> _availableDurations = [15, 30, 45, 60];
  int _selectedDuration = 30;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00';
  final List<String> _availableTimes = [
    '09:00', '10:00', '11:00', '12:00', '14:00', '15:00', '16:00', '17:00'
  ];

  double get _totalAmount =>
      _mediumController.selectedMedium.value!.pricePerMinute * _selectedDuration;

  @override
  void initState() {
    super.initState();
    // Garantir que os créditos do usuário estejam atualizados
    _paymentController.loadUserCredits();
  }

  @override
  Widget build(BuildContext context) {
    // Ajustes responsivos baseados no tamanho da tela
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Consulta'),
        elevation: 0,
      ),
      body: Obx(() {
        if (_mediumController.selectedMedium.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final medium = _mediumController.selectedMedium.value!;

        return SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMediumCard(medium, isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildDateSelection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildTimeSelection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildDurationSelection(isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildPriceSummary(isSmallScreen),
              SizedBox(height: isSmallScreen ? 24 : 32),
              _buildBookingButton(isSmallScreen),
              const SizedBox(height: 16),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMediumCard(medium, bool isSmallScreen) {
    final titleSize = isSmallScreen ? 16.0 : 18.0;
    final subtitleSize = isSmallScreen ? 12.0 : 14.0;
    final priceSize = isSmallScreen ? 14.0 : 15.0;
    final avatarSize = isSmallScreen ? 25.0 : 30.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: avatarSize,
              backgroundImage: NetworkImage(medium.imageUrl),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              onBackgroundImageError: (_, __) {},
              child: medium.imageUrl.isEmpty
                  ? Icon(
                Icons.person,
                size: avatarSize,
                color: Theme.of(context).colorScheme.primary,
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medium.name,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        medium.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: subtitleSize,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${medium.reviewsCount} avaliações)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: subtitleSize - 2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}/min',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: priceSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelection(bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 15.0 : 16.0;
    final contentTextSize = isSmallScreen ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data da Consulta',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMMd('pt_BR').format(_selectedDate),
                      style: TextStyle(
                        fontSize: contentTextSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _showDatePicker,
                      child: const Text('Alterar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showDatePicker() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Widget _buildTimeSelection(bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 15.0 : 16.0;
    final contentTextSize = isSmallScreen ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Horário da Consulta',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.primary,
                      size: isSmallScreen ? 20 : 24,
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedTime,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTime = newValue;
                          });
                        }
                      },
                      items: _availableTimes
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      underline: Container(),
                      style: TextStyle(
                        fontSize: contentTextSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationSelection(bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 15.0 : 16.0;
    final chipTextSize = isSmallScreen ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duração da Consulta',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: isSmallScreen ? 50 : 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _availableDurations.length,
            itemBuilder: (context, index) {
              final duration = _availableDurations[index];
              final isSelected = duration == _selectedDuration;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDuration = duration;
                  });
                },
                child: Container(
                  width: isSmallScreen ? 70 : 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.withOpacity(0.5),
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      '$duration min',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: chipTextSize,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriceSummary(bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 15.0 : 16.0;
    final titleTextSize = isSmallScreen ? 14.0 : 16.0;
    final contentTextSize = isSmallScreen ? 12.0 : 14.0;
    final totalTextSize = isSmallScreen ? 16.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resumo de Pagamento',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consulta',
                      style: TextStyle(
                        fontSize: titleTextSize,
                      ),
                    ),
                    Text(
                      'R\$ ${_totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: titleTextSize,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preço: R\$ ${_mediumController.selectedMedium.value!.pricePerMinute.toStringAsFixed(2)}/min',
                      style: TextStyle(
                        fontSize: contentTextSize,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'Duração: $_selectedDuration min',
                      style: TextStyle(
                        fontSize: contentTextSize,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: totalTextSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'R\$ ${_totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: totalTextSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Seus créditos',
                      style: TextStyle(
                        fontSize: contentTextSize,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Obx(() => Text(
                      'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: contentTextSize,
                        fontWeight: FontWeight.bold,
                        color: _paymentController.userCredits.value >= _totalAmount
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton(bool isSmallScreen) {
    return Obx(() {
      final hasEnoughCredits = _paymentController.userCredits.value >= _totalAmount;
      final buttonTextSize = isSmallScreen ? 14.0 : 16.0;
      final errorTextSize = isSmallScreen ? 12.0 : 14.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_mediumController.isLoading.value ||
                  _paymentController.isLoading.value)
                  ? null
                  : () => _confirmBooking(),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                ),
              ),
              child: (_mediumController.isLoading.value ||
                  _paymentController.isLoading.value)
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                'Confirmar Agendamento',
                style: TextStyle(
                  fontSize: buttonTextSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (!hasEnoughCredits) ...[
            const SizedBox(height: 16),
            Text(
              'Você não possui créditos suficientes para este agendamento.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: errorTextSize,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
                  ),
                ),
                child: Text(
                  'Adicionar Créditos',
                  style: TextStyle(
                    fontSize: buttonTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  void _confirmBooking() async {
    // Criar um DateTime combinando a data e hora selecionadas
    final timeComponents = _selectedTime.split(':');
    final hour = int.parse(timeComponents[0]);
    final minute = int.parse(timeComponents[1]);

    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );

    // Confirmar com o usuário
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar Agendamento'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Médium: ${_mediumController.selectedMedium.value!.name}'),
            const SizedBox(height: 8),
            Text('Data: ${DateFormat.yMMMMd('pt-BR').format(_selectedDate)}'),
            const SizedBox(height: 4),
            Text('Horário: $_selectedTime'),
            const SizedBox(height: 4),
            Text('Duração: $_selectedDuration minutos'),
            const SizedBox(height: 4),
            Text('Valor: R\$ ${_totalAmount.toStringAsFixed(2)}'),
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
      // Realizar o agendamento
      final success = await _mediumController.bookAppointment(
        _mediumController.selectedMedium.value!.id,
        appointmentDateTime,
        _selectedDuration,
      );

      if (success) {
        Get.offAllNamed(AppRoutes.navigation);
        Get.snackbar(
          'Agendamento Confirmado',
          'Sua consulta foi agendada com sucesso!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }
}