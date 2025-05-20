import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';

class BirthChartFormFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController birthPlaceController;
  final TextEditingController timeController;
  final TextEditingController birthDateController;
  final DateTime selectedDate;
  final VoidCallback onDateSelect;
  final bool isSmallScreen;
  final bool isTablet;
  final double padding;
  final HoroscopeController horoscopeController;

  const BirthChartFormFields({
    Key? key,
    required this.nameController,
    required this.birthPlaceController,
    required this.timeController,
    required this.selectedDate,
    required this.onDateSelect,
    required this.isSmallScreen,
    required this.isTablet,
    required this.padding,
    required this.horoscopeController,
    required this.birthDateController
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final labelSize = isTablet ? 16.0 : isSmallScreen ? 12.0 : 14.0;
    final inputSize = isTablet ? 16.0 : isSmallScreen ? 14.0 : 15.0;
    final fieldPadding = EdgeInsets.symmetric(
      vertical: isTablet ? 16 : 12,
      horizontal: isTablet ? 20 : 16,
    );
    final borderRadius = BorderRadius.circular(isTablet ? 16 : 12);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      contentPadding: fieldPadding,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: labelSize,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações do Nascimento',
          style: TextStyle(
            color: Colors.white,
            fontSize: isTablet ? 20 : isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),

        // Campo de Nome
        TextFormField(
          controller: nameController,
          decoration: inputDecoration.copyWith(
            labelText: 'Nome Completo',
            prefixIcon: Icon(
              Icons.person_outline,
              color: Colors.white.withOpacity(0.7),
              size: isTablet ? 24 : 20,
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: inputSize,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite seu nome';
            }
            return null;
          },
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 400),
          duration: const Duration(milliseconds: 400),
        ),

        SizedBox(height: isTablet ? 20 : 16),

        TextFormField(
          controller: birthDateController,
          inputFormatters: [horoscopeController.dataNascimento],
          keyboardType: TextInputType.number,
          decoration: inputDecoration.copyWith(
            labelText: 'Data Nascimento',
            prefixIcon: Icon(
              Icons.edit_calendar,
              color: Colors.white.withOpacity(0.7),
              size: isTablet ? 24 : 20,
            ),
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: inputSize,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, digite sua Data Nascimento';
            }
            return null;
          },
        ).animate().fadeIn(
          delay: const Duration(milliseconds: 400),
          duration: const Duration(milliseconds: 400),
        ),

        SizedBox(height: isTablet ? 20 : 16),

        // Campos de Horário e Local em linha para telas maiores, ou empilhados para telas menores
        isTablet
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de Horário
            Expanded(
              flex: 1,
              child: _buildTimeField(inputDecoration, inputSize),
            ),
            const SizedBox(width: 16),
            // Campo de Local
            Expanded(
              flex: 2,
              child: _buildPlaceField(inputDecoration, inputSize),
            ),
          ],
        )
            : Column(
          children: [
            // Campo de Horário
            _buildTimeField(inputDecoration, inputSize),
            SizedBox(height: isTablet ? 20 : 16),
            // Campo de Local
            _buildPlaceField(inputDecoration, inputSize),
          ],
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildTimeField(InputDecoration decoration, double fontSize) {
    return TextFormField(
      controller: timeController,
      inputFormatters: [horoscopeController.horaNascimento],
      textCapitalization: TextCapitalization.none,
      decoration: decoration.copyWith(
        labelText: 'Horário de Nascimento',
        hintText: 'Ex: 14:30',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: fontSize,
        ),
        prefixIcon: Icon(
          Icons.access_time,
          color: Colors.white.withOpacity(0.7),
          size: isTablet ? 24 : 20,
        ),
      ),
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Insira o horário de nascimento';
        }
        // Validação simples de formato de hora
        final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
        if (!timeRegex.hasMatch(value)) {
          return 'Formato inválido (use HH:MM)';
        }
        return null;
      },
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 600),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildPlaceField(InputDecoration decoration, double fontSize) {
    return TextFormField(
      controller: birthPlaceController,
      decoration: decoration.copyWith(
        labelText: 'Local de Nascimento',
        hintText: 'Ex: São Paulo, SP, Brasil',
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: fontSize,
        ),
        prefixIcon: Icon(
          Icons.location_on_outlined,
          color: Colors.white.withOpacity(0.7),
          size: isTablet ? 24 : 20,
        ),
      ),
      style: TextStyle(
        color: Colors.white,
        fontSize: fontSize,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Insira o local de nascimento';
        }
        return null;
      },
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 700),
      duration: const Duration(milliseconds: 400),
    );
  }
}