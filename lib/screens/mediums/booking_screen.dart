import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

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
    _paymentController.loadUserCredits();
  }

  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    return {
      'padding': isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0,
      'titleSize': isTablet ? 22.0 : isSmallScreen ? 16.0 : 18.0,
      'subtitleSize': isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0,
      'bodySize': isTablet ? 16.0 : isSmallScreen ? 13.0 : 15.0,
      'captionSize': isTablet ? 14.0 : isSmallScreen ? 12.0 : 13.0,
      'spacing': isTablet ? 32.0 : 24.0,
      'cardPadding': isTablet ? 24.0 : 20.0,
      'avatarSize': isTablet ? 50.0 : isSmallScreen ? 30.0 : 40.0,
      'iconSize': isTablet ? 28.0 : 24.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Agendar Consulta',
          style: TextStyle(
            color: Colors.white,
            fontSize: dimensions['titleSize']!,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF533483),
            ],
          ),
        ),
        child: Obx(() {
          if (_mediumController.selectedMedium.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final medium = _mediumController.selectedMedium.value!;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(dimensions['padding']!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediumCard(medium, dimensions),
                  SizedBox(height: dimensions['spacing']!),
                  _buildDateSelection(dimensions),
                  SizedBox(height: dimensions['spacing']!),
                  _buildTimeSelection(dimensions),
                  SizedBox(height: dimensions['spacing']!),
                  _buildDurationSelection(dimensions),
                  SizedBox(height: dimensions['spacing']!),
                  _buildPriceSummary(dimensions),
                  SizedBox(height: dimensions['spacing']! + 8),
                  _buildBookingButton(dimensions),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMediumCard(medium, Map<String, double> dimensions) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.02),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: dimensions['avatarSize']! * 2,
              height: dimensions['avatarSize']! * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: medium.imageUrl.isNotEmpty
                    ? Image.network(
                  medium.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultAvatar(dimensions),
                )
                    : _buildDefaultAvatar(dimensions),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medium.name,
                    style: TextStyle(
                      fontSize: dimensions['titleSize']!,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        medium.rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: dimensions['bodySize']!,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${medium.reviewsCount} avaliações)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: dimensions['captionSize']!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}/min',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: dimensions['bodySize']!,
                      ),
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

  Widget _buildDefaultAvatar(Map<String, double> dimensions) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
        ),
      ),
      child: Icon(
        Icons.person,
        size: dimensions['avatarSize']!,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required Map<String, double> dimensions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: dimensions['subtitleSize']!,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          color: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(dimensions['cardPadding']!),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelection(Map<String, double> dimensions) {
    return _buildSectionCard(
      title: 'Data da Consulta',
      dimensions: dimensions,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: const Color(0xFF6C63FF),
              size: dimensions['iconSize']!,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMd('pt_BR').format(_selectedDate),
                  style: TextStyle(
                    fontSize: dimensions['bodySize']!,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.EEEE('pt_BR').format(_selectedDate),
                  style: TextStyle(
                    fontSize: dimensions['captionSize']!,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showDatePicker,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF).withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Alterar',
              style: TextStyle(color: Color(0xFF6C63FF)),
            ),
          ),
        ],
      ),
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
              primary: const Color(0xFF6C63FF),
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

  Widget _buildTimeSelection(Map<String, double> dimensions) {
    return _buildSectionCard(
      title: 'Horário da Consulta',
      dimensions: dimensions,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8E78FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.access_time,
              color: const Color(0xFF8E78FF),
              size: dimensions['iconSize']!,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF8E78FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8E78FF).withOpacity(0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
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
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: dimensions['bodySize']!,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }).toList(),
                  dropdownColor: Colors.black.withOpacity(0.9),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF8E78FF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationSelection(Map<String, double> dimensions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duração da Consulta',
          style: TextStyle(
            fontSize: dimensions['subtitleSize']!,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
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
                  width: 90,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                    )
                        : null,
                    color: isSelected
                        ? null
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.1),
                    ),
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$duration',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: dimensions['titleSize']!,
                          ),
                        ),
                        Text(
                          'min',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: dimensions['captionSize']!,
                          ),
                        ),
                      ],
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

  Widget _buildPriceSummary(Map<String, double> dimensions) {
    return _buildSectionCard(
      title: 'Resumo de Pagamento',
      dimensions: dimensions,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consulta',
                style: TextStyle(
                  fontSize: dimensions['bodySize']!,
                  color: Colors.white,
                ),
              ),
              Text(
                'R\$ ${_totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: dimensions['bodySize']!,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R\$ ${_mediumController.selectedMedium.value!.pricePerMinute.toStringAsFixed(2)}/min',
                style: TextStyle(
                  fontSize: dimensions['captionSize']!,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                '$_selectedDuration minutos',
                style: TextStyle(
                  fontSize: dimensions['captionSize']!,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(
              color: Colors.white.withOpacity(0.2),
              thickness: 1,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: dimensions['titleSize']!,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'R\$ ${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: dimensions['titleSize']!,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seus créditos',
                  style: TextStyle(
                    fontSize: dimensions['bodySize']!,
                    color: Colors.white,
                  ),
                ),
                Obx(() => Text(
                  'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: dimensions['bodySize']!,
                    fontWeight: FontWeight.bold,
                    color: _paymentController.userCredits.value >= _totalAmount
                        ? Colors.green
                        : Colors.red,
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(Map<String, double> dimensions) {
    return Obx(() {
      final hasEnoughCredits = _paymentController.userCredits.value >= _totalAmount;
      final isLoading = _mediumController.isLoading.value || _paymentController.isLoading.value;

      return Column(
        children: [
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: hasEnoughCredits
                  ? const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
              )
                  : null,
              color: hasEnoughCredits ? null : Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              boxShadow: hasEnoughCredits
                  ? [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
                  : [],
            ),
            child: ElevatedButton(
              onPressed: isLoading || !hasEnoughCredits ? null : _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(
                'Confirmar Agendamento',
                style: TextStyle(
                  fontSize: dimensions['bodySize']!,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (!hasEnoughCredits) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Créditos insuficientes para este agendamento',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: dimensions['captionSize']!,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6C63FF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Adicionar Créditos',
                        style: TextStyle(
                          fontSize: dimensions['bodySize']!,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }

  void _confirmBooking() async {
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

    final confirmed = await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.event_available,
                color: Color(0xFF6C63FF),
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Confirmar Agendamento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildConfirmationDetails(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(result: false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Confirmar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
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
          borderRadius: 12,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        );
      }
    }
  }

  Widget _buildConfirmationDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Médium', _mediumController.selectedMedium.value!.name),
          _buildDetailRow('Data', DateFormat.yMMMMd('pt-BR').format(_selectedDate)),
          _buildDetailRow('Horário', _selectedTime),
          _buildDetailRow('Duração', '$_selectedDuration minutos'),
          const Divider(color: Colors.white24),
          _buildDetailRow(
            'Valor Total',
            'R\$ ${_totalAmount.toStringAsFixed(2)}',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? const Color(0xFF6C63FF) : Colors.white,
              fontSize: isTotal ? 16 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}