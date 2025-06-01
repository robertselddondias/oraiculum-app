import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/screens/astrology/widgets/interpretation_section.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class BirthChartHistoryDialog {
  static Future<void> show({
    required BuildContext context,
    required HoroscopeController controller,
    required Function(Map<String, dynamic>) onChartSelected,
  }) async {
    try {
      // Loading dialog com tema consistente
      Get.dialog(
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando histórico...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final birthCharts = await controller.getUserBirthCharts();
      Get.back();

      if (birthCharts.isEmpty) {
        return Get.dialog(
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF392F5A),
                    Color(0xFF483D8B),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Histórico Vazio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Você ainda não gerou nenhum mapa astral.\nGere seu primeiro mapa para começar sua jornada astrológica!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Get.back(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: const Color(0xFF392F5A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Entendi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Obter dimensões da tela para responsividade
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 360;
      final isTablet = screenWidth >= 600;

      return Get.dialog(
        Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF392F5A),
                  Color(0xFF483D8B),
                  Color(0xFF8C6BAE),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: isTablet ? 600 : double.infinity,
            ),
            child: Stack(
              children: [
                // Partículas de fundo
                ...ZodiacUtils.buildStarParticles(context, 15, maxHeight: 200),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header com gradiente e estilo consistente
                    Container(
                      padding: EdgeInsets.all(isTablet ? 28 : isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: isTablet ? 28 : 24,
                            ),
                          ),
                          SizedBox(width: isTablet ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Histórico de Mapas',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isTablet ? 22 : isSmallScreen ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${birthCharts.length} ${birthCharts.length == 1 ? 'mapa gerado' : 'mapas gerados'}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: isTablet ? 16 : isSmallScreen ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Get.back(),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: isTablet ? 28 : 24,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista de mapas astrais
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.all(isTablet ? 20 : isSmallScreen ? 12 : 16),
                        itemCount: birthCharts.length,
                        itemBuilder: (context, index) {
                          final chart = birthCharts[index];

                          // Usar o método helper para formatar os dados
                          final formattedChart = _formatChartData(chart);
                          final name = formattedChart['name'] as String;
                          final formattedDate = formattedChart['birthDateString'] as String;
                          final place = formattedChart['birthPlace'] as String;
                          final time = formattedChart['birthTime'] as String;
                          final formattedCreatedAt = formattedChart['formattedCreatedAt'] as String;
                          final zodiacSign = formattedChart['zodiacSign'] as String;
                          final isFavorite = formattedChart['isFavorite'] as bool;

                          return Container(
                            margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () {
                                  Get.back();
                                  // Mostrar detalhes do mapa astral com interpretação formatada
                                  _showChartDetails(
                                    context,
                                    formattedChart,
                                    isSmallScreen,
                                    isTablet,
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: EdgeInsets.all(isTablet ? 20 : isSmallScreen ? 12 : 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Cabeçalho do card
                                      Row(
                                        children: [
                                          // Avatar do signo se disponível
                                          if (zodiacSign.isNotEmpty)
                                            ZodiacUtils.buildSignAvatar(
                                              context: context,
                                              sign: zodiacSign,
                                              size: isTablet ? 56 : isSmallScreen ? 40 : 48,
                                              highlight: true,
                                            )
                                          else
                                            Container(
                                              width: isTablet ? 56 : isSmallScreen ? 40 : 48,
                                              height: isTablet ? 56 : isSmallScreen ? 40 : 48,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppTheme.primaryColor,
                                                    AppTheme.secondaryColor,
                                                  ],
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.public,
                                                color: Colors.white,
                                                size: isTablet ? 28 : isSmallScreen ? 20 : 24,
                                              ),
                                            ),

                                          SizedBox(width: isTablet ? 16 : 12),

                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        name,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: isTablet ? 18 : isSmallScreen ? 14 : 16,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (isFavorite)
                                                      Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.amber.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Icon(
                                                          Icons.star,
                                                          color: Colors.amber,
                                                          size: isSmallScreen ? 12 : 14,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      color: Colors.white.withOpacity(0.6),
                                                      size: isSmallScreen ? 12 : 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      formattedDate,
                                                      style: TextStyle(
                                                        color: Colors.white.withOpacity(0.7),
                                                        fontSize: isTablet ? 14 : isSmallScreen ? 11 : 12,
                                                      ),
                                                    ),
                                                    if (zodiacSign.isNotEmpty) ...[
                                                      Text(
                                                        ' • ',
                                                        style: TextStyle(
                                                          color: Colors.white.withOpacity(0.5),
                                                          fontSize: isTablet ? 14 : isSmallScreen ? 11 : 12,
                                                        ),
                                                      ),
                                                      Text(
                                                        zodiacSign,
                                                        style: TextStyle(
                                                          color: ZodiacUtils.getSignColor(zodiacSign),
                                                          fontSize: isTablet ? 14 : isSmallScreen ? 11 : 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Gerado em $formattedCreatedAt',
                                                  style: TextStyle(
                                                    color: Colors.white.withOpacity(0.5),
                                                    fontSize: isTablet ? 12 : isSmallScreen ? 10 : 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          Container(
                                            padding: EdgeInsets.all(isTablet ? 10 : 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              Icons.visibility,
                                              color: Colors.white,
                                              size: isTablet ? 18 : isSmallScreen ? 14 : 16,
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),

                                      // Divider com gradiente
                                      Container(
                                        height: 1,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              Colors.white.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Informações detalhadas
                                      Row(
                                        children: [
                                          // Local de nascimento
                                          Expanded(
                                            child: _buildInfoChip(
                                              icon: Icons.location_on,
                                              label: 'Local',
                                              value: place,
                                              color: AppTheme.accentColor,
                                              isSmallScreen: isSmallScreen,
                                              isTablet: isTablet,
                                            ),
                                          ),

                                          SizedBox(width: isTablet ? 16 : 12),

                                          // Horário
                                          _buildInfoChip(
                                            icon: Icons.access_time,
                                            label: 'Horário',
                                            value: time,
                                            color: AppTheme.successColor,
                                            isSmallScreen: isSmallScreen,
                                            isTablet: isTablet,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                            delay: Duration(milliseconds: 100 * index),
                            duration: const Duration(milliseconds: 500),
                          ).slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutQuart,
                            duration: const Duration(milliseconds: 400),
                          ).scale(
                            begin: const Offset(0.95, 0.95),
                            end: const Offset(1.0, 1.0),
                            duration: const Duration(milliseconds: 300),
                          );
                        },
                      ),
                    ),

                    // Botão de fechar com estilo consistente
                    Padding(
                      padding: EdgeInsets.all(isTablet ? 24 : isSmallScreen ? 16 : 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: isTablet ? 56 : 48,
                        child: ElevatedButton.icon(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close,
                            size: isTablet ? 24 : 20,
                          ),
                          label: Text(
                            'Fechar',
                            style: TextStyle(
                              fontSize: isTablet ? 18 : isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: const Color(0xFF392F5A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                            ),
                            elevation: 0,
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
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Erro',
        'Não foi possível carregar o histórico de mapas astrais: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        borderRadius: 12,
        margin: const EdgeInsets.all(16),
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }
  }

  // Novo método para mostrar detalhes com interpretação formatada
  static void _showChartDetails(
      BuildContext context,
      Map<String, dynamic> chart,
      bool isSmallScreen,
      bool isTablet,
      ) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF392F5A),
                Color(0xFF483D8B),
                Color(0xFF8C6BAE),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Partículas de fundo
              ...ZodiacUtils.buildStarParticles(context, 20, maxHeight: 300),

              Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Avatar do signo
                        if (chart['zodiacSign']?.isNotEmpty ?? false)
                          ZodiacUtils.buildSignAvatar(
                            context: context,
                            sign: chart['zodiacSign'],
                            size: isTablet ? 60 : 50,
                            highlight: true,
                          )
                        else
                          Container(
                            width: isTablet ? 60 : 50,
                            height: isTablet ? 60 : 50,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.public,
                              color: Colors.white,
                              size: isTablet ? 30 : 25,
                            ),
                          ),

                        SizedBox(width: isTablet ? 16 : 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chart['name'] ?? 'Sem nome',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isTablet ? 20 : isSmallScreen ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              if (chart['zodiacSign']?.isNotEmpty ?? false)
                                Text(
                                  'Signo Solar: ${chart['zodiacSign']}',
                                  style: TextStyle(
                                    color: ZodiacUtils.getSignColor(chart['zodiacSign']),
                                    fontSize: isTablet ? 16 : isSmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conteúdo scrollável
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Informações básicas
                          _buildBasicInfoCard(chart, isSmallScreen, isTablet),

                          const SizedBox(height: 20),

                          // Interpretação formatada
                          _buildFormattedInterpretation(
                            chart['interpretation'] ?? '',
                            isSmallScreen,
                            isTablet,
                          ),
                        ],
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
  }

  // Widget para informações básicas do mapa
  static Widget _buildBasicInfoCard(
      Map<String, dynamic> chart,
      bool isSmallScreen,
      bool isTablet,
      ) {
    final cardPadding = isTablet ? 20.0 : isSmallScreen ? 12.0 : 16.0;
    final textSize = isTablet ? 14.0 : isSmallScreen ? 12.0 : 13.0;
    final iconSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dados do Nascimento',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 18 : isSmallScreen ? 14 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Data
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Colors.white.withOpacity(0.7),
                size: iconSize,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data de Nascimento',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: textSize - 1,
                    ),
                  ),
                  Text(
                    chart['birthDate'] ?? 'Não informado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horário
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.white.withOpacity(0.7),
                size: iconSize,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Horário',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: textSize - 1,
                    ),
                  ),
                  Text(
                    chart['birthTime'] ?? 'Não informado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Local
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white.withOpacity(0.7),
                size: iconSize,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Local de Nascimento',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: textSize - 1,
                      ),
                    ),
                    Text(
                      chart['birthPlace'] ?? 'Não informado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: textSize,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para interpretação formatada usando o componente existente
  static Widget _buildFormattedInterpretation(
      String interpretation,
      bool isSmallScreen,
      bool isTablet,
      ) {
    return BirthChartInterpretation(
      interpretation: interpretation,
      isSmallScreen: isSmallScreen,
      isTablet: isTablet,
    );
  }

  // Método helper para formatar dados do mapa astral seguindo o padrão da BirthChartDetailsScreen
  static Map<String, dynamic> _formatChartData(Map<String, dynamic> chart) {
    final name = chart['name'] ?? 'Sem nome';
    final birthDateRaw = chart['birthDate'];
    final place = chart['birthPlace'] ?? 'Local desconhecido';
    final time = chart['birthTime'] ?? 'Hora desconhecida';
    final createdAt = chart['createdAt'];
    final isFavorite = chart['isFavorite'] ?? false;

    String formattedDate = 'Data desconhecida';
    String formattedCreatedAt = 'Data desconhecida';
    String zodiacSign = '';
    DateTime? birthDateTime;

    // Formatar datas seguindo o padrão da BirthChartDetailsScreen
    if (birthDateRaw != null) {
      if (birthDateRaw is DateTime) {
        birthDateTime = birthDateRaw;
        formattedDate = DateFormat('dd/MM/yyyy').format(birthDateTime);
        zodiacSign = ZodiacUtils.getZodiacSignFromDate(birthDateTime);
      } else if (birthDateRaw is String && birthDateRaw.isNotEmpty) {
        try {
          // Tentar diferentes formatos de data
          if (birthDateRaw.contains('/')) {
            birthDateTime = DateFormat('dd/MM/yyyy').parse(birthDateRaw);
          } else if (birthDateRaw.contains('-')) {
            // Formato ISO 8601 ou similar
            birthDateTime = DateTime.parse(birthDateRaw);
          }

          if (birthDateTime != null) {
            formattedDate = DateFormat('dd/MM/yyyy').format(birthDateTime);
            zodiacSign = ZodiacUtils.getZodiacSignFromDate(birthDateTime);
          } else {
            formattedDate = birthDateRaw;
          }
        } catch (e) {
          formattedDate = birthDateRaw;
          // Tentar extrair signo mesmo com erro de parsing
          final parts = birthDateRaw.split('/');
          if (parts.length == 3) {
            try {
              final day = int.parse(parts[0]);
              final month = int.parse(parts[1]);
              final year = int.parse(parts[2]);
              if (year < 100) {
                // Assumir que anos de 2 dígitos são do século 20/21
                final currentYear = DateTime.now().year;
                final century = (currentYear ~/ 100) * 100;
                final fullYear = year + century;
                if (fullYear > currentYear) {
                  birthDateTime = DateTime(fullYear - 100, month, day);
                } else {
                  birthDateTime = DateTime(fullYear, month, day);
                }
              } else {
                birthDateTime = DateTime(year, month, day);
              }
              zodiacSign = ZodiacUtils.getZodiacSignFromDate(birthDateTime!);
            } catch (e) {
              // Ignorar erro se não conseguir fazer parsing
            }
          }
        }
      }
    }

    if (createdAt != null) {
      if (createdAt is DateTime) {
        formattedCreatedAt = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
      } else if (createdAt is String) {
        try {
          final parsedCreatedAt = DateTime.parse(createdAt);
          formattedCreatedAt = DateFormat('dd/MM/yyyy HH:mm').format(parsedCreatedAt);
        } catch (e) {
          formattedCreatedAt = createdAt;
        }
      }
    }

    // Retornar dados formatados compatíveis com BirthChartDetailsScreen
    return {
      ...chart,
      'name': name,
      'birthDate': formattedDate, // String formatada para exibição
      'birthDateString': formattedDate, // Alias para compatibilidade
      'birthDateTime': birthDateTime, // DateTime original para cálculos
      'birthTime': time,
      'birthPlace': place,
      'zodiacSign': zodiacSign,
      'formattedCreatedAt': formattedCreatedAt,
      'isFavorite': isFavorite,
      // Manter campos originais para compatibilidade
      'interpretation': chart['interpretation'] ?? '',
      'paymentId': chart['paymentId'] ?? '',
      'tags': chart['tags'] ?? [],
    };
  }

  // Widget helper para criar chips de informação
  static Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: isTablet ? 16 : isSmallScreen ? 12 : 14,
          ),
        ),
        SizedBox(width: isTablet ? 10 : 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: isTablet ? 12 : isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isTablet ? 14 : isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

}

// Classe helper para informações de seção (mantida para compatibilidade se necessário)
class _SectionInfo {
  final Color color;
  final IconData icon;

  _SectionInfo({
    required this.color,
    required this.icon,
  });
}