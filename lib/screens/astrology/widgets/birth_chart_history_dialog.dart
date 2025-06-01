import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/utils/zodiac_utils.dart';
import 'package:share_plus/share_plus.dart';

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
                                              decoration: const BoxDecoration(
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

  // Método para mostrar detalhes com interpretação formatada
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

                        // Botão de favorito
                        IconButton(
                          onPressed: () {
                            // TODO: Implementar toggle de favorito
                            Get.snackbar(
                              'Info',
                              'Funcionalidade de favorito em desenvolvimento',
                              backgroundColor: AppTheme.infoColor,
                              colorText: Colors.white,
                            );
                          },
                          icon: Icon(
                            chart['isFavorite'] == true ? Icons.star : Icons.star_border,
                            color: chart['isFavorite'] == true ? Colors.amber : Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        // Botão de compartilhar
                        IconButton(
                          onPressed: () {
                            final chartText = _generateShareText(chart);
                            SharePlus.instance.share(ShareParams(text: chartText));
                          },
                          icon: Icon(
                            Icons.share,
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

                        // Botão de fechar
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
                          // Informações básicas do nascimento
                          _buildBasicInfoCard(chart, isSmallScreen, isTablet),

                          const SizedBox(height: 20),

                          // Interpretação formatada
                          _buildFormattedInterpretation(
                            chart['interpretation'] ?? 'Interpretação não disponível',
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

  // Widget para interpretação formatada - implementação própria
  static Widget _buildFormattedInterpretation(
      String interpretation,
      bool isSmallScreen,
      bool isTablet,
      ) {
    final sectionCardPadding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;
    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;
    final sectionTitleSize = isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0;
    final bodyTextSize = isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0;
    final iconSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;

    // Debug: Verificar se temos interpretação válida
    if (interpretation.isEmpty || interpretation == 'Interpretação não disponível') {
      return Container(
        padding: EdgeInsets.all(sectionCardPadding),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.warning,
              color: Colors.orange,
              size: iconSize,
            ),
            const SizedBox(height: 12),
            Text(
              'Interpretação não disponível',
              style: TextStyle(
                color: Colors.white,
                fontSize: sectionTitleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A interpretação do mapa astral não foi encontrada ou está vazia.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: bodyTextSize,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Parse da interpretação
    final parsedSections = _parseInterpretation(interpretation);

    // Debug: Verificar se conseguimos parsear seções
    if (parsedSections.isEmpty) {
      return Container(
        padding: EdgeInsets.all(sectionCardPadding),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.orange,
                  size: iconSize,
                ),
                const SizedBox(width: 12),
                Text(
                  'Erro no Parse',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: sectionTitleSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Não foi possível parsear a interpretação. Mostrando conteúdo original:',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: bodyTextSize,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                interpretation.length > 500
                    ? '${interpretation.substring(0, 500)}...'
                    : interpretation,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: bodyTextSize - 1,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.public,
                color: AppTheme.primaryColor,
                size: iconSize,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interpretação do Mapa Astral',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${parsedSections.length} ${parsedSections.length == 1 ? 'seção encontrada' : 'seções encontradas'}',
                    style: TextStyle(
                      fontSize: bodyTextSize - 2,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),

        // Construir cada seção da interpretação
        ...parsedSections.entries.map((entry) {
          final title = entry.key;
          final content = entry.value;

          // Skip empty sections
          if (content.isEmpty) return const SizedBox.shrink();

          // Determinar cor e ícone da seção
          final sectionInfo = _getSectionInfo(title);

          return Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
            child: Card(
              elevation: isTablet ? 4 : 2,
              color: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: sectionInfo.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(sectionCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sectionInfo.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            sectionInfo.icon,
                            color: sectionInfo.color,
                            size: iconSize,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.bold,
                              color: sectionInfo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      content,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: bodyTextSize,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 200 + (100 * parsedSections.keys.toList().indexOf(title))),
            duration: const Duration(milliseconds: 500),
          ).slideY(
            begin: 0.1,
            end: 0,
            duration: const Duration(milliseconds: 400),
          );
        }),
      ],
    );
  }

  // Parse da interpretação string em seções
  static Map<String, String> _parseInterpretation(String text) {
    Map<String, String> sections = {};

    // Debug: Imprimir o texto original
    print('🔍 DEBUG - Texto original da interpretação:');
    print(text);
    print('📏 Tamanho do texto: ${text.length}');

    try {
      // Tentar parse como JSON primeiro
      final jsonData = json.decode(text);
      print('✅ JSON parseado com sucesso!');
      print('🔍 Tipo do JSON: ${jsonData.runtimeType}');

      if (jsonData is Map<String, dynamic>) {
        print('📋 Chaves encontradas no JSON: ${jsonData.keys.toList()}');

        // Processar estrutura JSON
        jsonData.forEach((key, value) {
          print('🔑 Processando chave: $key, tipo do valor: ${value.runtimeType}');

          if (value is Map<String, dynamic>) {
            print('📝 Valor é Map: $value');
            if (value.containsKey('body')) {
              // Usar título do JSON se disponível, senão capitalizar a chave
              final title = value['title'] ?? _capitalizeSection(key);
              final body = value['body'] ?? '';
              sections[title] = body;
              print('✅ Seção adicionada: $title -> ${body.substring(0, body.length > 50 ? 50 : body.length)}...');
            } else if (value.containsKey('title') && value.containsKey('content')) {
              // Formato alternativo com 'content' ao invés de 'body'
              final title = value['title'] ?? _capitalizeSection(key);
              final content = value['content'] ?? '';
              sections[title] = content;
              print('✅ Seção adicionada (content): $title -> ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
            } else {
              // Se o Map não tem estrutura esperada, usar como texto simples
              final title = _capitalizeSection(key);
              final content = value.toString();
              sections[title] = content;
              print('✅ Seção adicionada (toString): $title -> ${content.substring(0, content.length > 50 ? 50 : content.length)}...');
            }
          } else if (value is String) {
            // Par chave-valor simples
            final title = _capitalizeSection(key);
            sections[title] = value;
            print('✅ Seção adicionada (string): $title -> ${value.substring(0, value.length > 50 ? 50 : value.length)}...');
          } else if (value is List) {
            // Se for uma lista, converter para string
            final title = _capitalizeSection(key);
            final content = value.join(', ');
            sections[title] = content;
            print('✅ Seção adicionada (lista): $title -> $content');
          }
        });

        print('📊 Total de seções criadas: ${sections.length}');
        print('🗂️ Seções finais: ${sections.keys.toList()}');
        return sections;
      } else {
        print('❌ JSON não é um Map<String, dynamic>, é: ${jsonData.runtimeType}');
      }
    } catch (e) {
      print('❌ Erro ao fazer parse do JSON: $e');
      print('🔄 Tentando parse de texto...');
    }

    // Fallback: Tentar identificar seções por cabeçalhos
    try {
      // Padrões mais abrangentes de seção em interpretações de mapa astral
      final sectionRegex = RegExp(
          r'(SOL\s*:)|(LUA\s*:)|(ASCENDENTE\s*:)|'
          r'(MERCÚRIO\s*:)|(VÊNUS\s*:)|(MARTE\s*:)|'
          r'(JÚPITER\s*:)|(SATURNO\s*:)|(URANO\s*:)|(NETUNO\s*:)|(PLUTÃO\s*:)|'
          r'(CASAS\s*:)|(ASPECTOS\s*:)|(CONCLUSÃO\s*:)|'
          r'(VISÃO\s*GERAL\s*:)|(PERSONALIDADE\s*:)|(EMOÇÕES\s*:)|'
          r'(###\s*.+?)|(\*\*\s*.+?\s*\*\*)',
          caseSensitive: false,
          multiLine: true
      );

      // Dividir por cabeçalhos de seção detectados
      final matches = sectionRegex.allMatches(text);
      print('🔍 Matches encontrados: ${matches.length}');

      if (matches.isNotEmpty) {
        int startIndex = 0;
        String currentTitle = 'Visão Geral';

        // Extrair texto inicial antes da primeira seção como "Visão Geral"
        if (matches.first.start > 0) {
          final initialText = text.substring(0, matches.first.start).trim();
          if (initialText.isNotEmpty) {
            sections[currentTitle] = initialText;
            print('✅ Seção inicial adicionada: $currentTitle');
          }
        }

        // Processar cada seção
        for (final match in matches) {
          // Salvar seção anterior
          if (match.start > startIndex && currentTitle.isNotEmpty) {
            final sectionText = text.substring(startIndex, match.start).trim();
            if (sectionText.isNotEmpty) {
              sections[currentTitle] = sectionText;
              print('✅ Seção de texto adicionada: $currentTitle');
            }
          }

          // Atualizar para próxima seção
          currentTitle = text.substring(match.start, match.end)
              .replaceAll(RegExp(r'[:#*]'), '')
              .trim();
          if (currentTitle.isEmpty) {
            currentTitle = 'Seção ${sections.length + 1}';
          }
          startIndex = match.end;
        }

        // Adicionar última seção
        if (startIndex < text.length && currentTitle.isNotEmpty) {
          final sectionText = text.substring(startIndex).trim();
          if (sectionText.isNotEmpty) {
            sections[currentTitle] = sectionText;
            print('✅ Última seção adicionada: $currentTitle');
          }
        }

        if (sections.isNotEmpty) {
          print('📊 Parse de texto bem-sucedido! Seções: ${sections.keys.toList()}');
          return sections;
        }
      }
    } catch (e) {
      print('❌ Erro no parse de texto: $e');
    }

    // Se todo parse falhar, usar texto completo como seção geral
    print('⚠️ Fallback: usando texto completo como seção única');
    sections['Interpretação Completa'] = text;
    return sections;
  }

  // Função helper para capitalizar nomes de seção
  static String _capitalizeSection(String text) {
    if (text.isEmpty) return 'Visão Geral';

    // Limpar o texto primeiro
    String cleanText = text.trim()
        .replaceAll(RegExp(r'[:#*_-]'), '')
        .trim();

    // Tratamento especial para termos astrológicos comuns
    switch (cleanText.toLowerCase()) {
      case 'sol':
      case 'solar':
      case 'sun':
        return 'Sol (Personalidade)';
      case 'lua':
      case 'lunar':
      case 'moon':
        return 'Lua (Emoções)';
      case 'asc':
      case 'ascendente':
      case 'ascendant':
        return 'Ascendente';
      case 'mc':
      case 'meio_do_ceu':
      case 'meio do ceu':
      case 'midheaven':
        return 'Meio do Céu';
      case 'venus':
      case 'vênus':
      case 'vênus em':
      case 'amor':
        return 'Vênus (Amor)';
      case 'marte':
      case 'mars':
      case 'energia':
        return 'Marte (Energia)';
      case 'mercurio':
      case 'mercúrio':
      case 'mercury':
      case 'comunicacao':
      case 'comunicação':
        return 'Mercúrio (Comunicação)';
      case 'jupiter':
      case 'júpiter':
      case 'expansao':
      case 'expansão':
        return 'Júpiter (Expansão)';
      case 'saturno':
      case 'saturn':
      case 'limitacoes':
      case 'limitações':
        return 'Saturno (Limitações)';
      case 'urano':
      case 'uranus':
      case 'originalidade':
        return 'Urano (Originalidade)';
      case 'netuno':
      case 'neptune':
      case 'espiritualidade':
        return 'Netuno (Espiritualidade)';
      case 'plutao':
      case 'plutão':
      case 'pluto':
      case 'transformacao':
      case 'transformação':
        return 'Plutão (Transformação)';
      case 'casas':
      case 'casas astrologicas':
      case 'casas astrológicas':
      case 'houses':
        return 'Casas Astrológicas';
      case 'aspectos':
      case 'aspectos planetarios':
      case 'aspectos planetários':
      case 'aspects':
        return 'Aspectos Planetários';
      case 'geral':
      case 'visao_geral':
      case 'visão_geral':
      case 'visao geral':
      case 'visão geral':
      case 'overview':
        return 'Visão Geral';
      case 'conclusao':
      case 'conclusão':
      case 'conclusion':
        return 'Conclusão';
      case 'personalidade':
      case 'personality':
        return 'Personalidade';
      case 'emocoes':
      case 'emoções':
      case 'emotions':
        return 'Vida Emocional';
      case 'relacionamentos':
      case 'relationships':
        return 'Relacionamentos';
      case 'carreira':
      case 'career':
        return 'Carreira';
      case 'financas':
      case 'finanças':
      case 'money':
        return 'Finanças';
      case 'saude':
      case 'saúde':
      case 'health':
        return 'Saúde';
      case 'familia':
      case 'família':
      case 'family':
        return 'Família';
      case 'criatividade':
      case 'creativity':
        return 'Criatividade';
      case 'espiritualidade':
      case 'spirituality':
        return 'Espiritualidade';
      default:
      // Capitalizar cada palavra e remover underscores
        return cleanText.split(RegExp(r'[\s_]+'))
            .map((word) => word.isNotEmpty ?
        word[0].toUpperCase() + word.substring(1).toLowerCase() : '')
            .join(' ');
    }
  }

  // Informações de estilo da seção
  static _SectionInfo _getSectionInfo(String sectionTitle) {
    final title = sectionTitle.toLowerCase();

    if (title.contains('sol') || title.contains('personalidade')) {
      return _SectionInfo(
        color: Colors.orange,
        icon: Icons.wb_sunny_outlined,
      );
    } else if (title.contains('lua') || title.contains('emoções')) {
      return _SectionInfo(
        color: Colors.blueGrey,
        icon: Icons.nightlight_round,
      );
    } else if (title.contains('mercúrio') || title.contains('comunicação')) {
      return _SectionInfo(
        color: Colors.lightBlue,
        icon: Icons.message_outlined,
      );
    } else if (title.contains('vênus') || title.contains('amor')) {
      return _SectionInfo(
        color: Colors.pink,
        icon: Icons.favorite_outline,
      );
    } else if (title.contains('marte') || title.contains('energia')) {
      return _SectionInfo(
        color: Colors.red,
        icon: Icons.flash_on_outlined,
      );
    } else if (title.contains('ascendente')) {
      return _SectionInfo(
        color: Colors.amber,
        icon: Icons.arrow_upward,
      );
    } else if (title.contains('casas')) {
      return _SectionInfo(
        color: Colors.teal,
        icon: Icons.home_outlined,
      );
    } else if (title.contains('aspectos')) {
      return _SectionInfo(
        color: Colors.deepPurple,
        icon: Icons.connecting_airports_outlined,
      );
    } else if (title.contains('conclusão')) {
      return _SectionInfo(
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } else {
      // Padrão
      return _SectionInfo(
        color: Colors.deepPurple,
        icon: Icons.public,
      );
    }
  }

  // Gerar texto para compartilhamento
  static String _generateShareText(Map<String, dynamic> chart) {
    final buffer = StringBuffer();

    buffer.writeln('🌟 MEU MAPA ASTRAL - ${chart['name'] ?? 'Oraculum'}');
    buffer.writeln('═══════════════════════════════');
    buffer.writeln();

    buffer.writeln('📅 Data: ${chart['birthDate'] ?? 'Não informado'}');
    buffer.writeln('🕐 Horário: ${chart['birthTime'] ?? 'Não informado'}');
    buffer.writeln('📍 Local: ${chart['birthPlace'] ?? 'Não informado'}');

    if (chart['zodiacSign']?.isNotEmpty ?? false) {
      buffer.writeln('♈ Signo Solar: ${chart['zodiacSign']}');
    }

    buffer.writeln();
    buffer.writeln('Descubra seu destino também no app Oraculum! ✨');

    return buffer.toString();
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: iconSize,
                ),
              ),
              SizedBox(width: isTablet ? 12 : 8),
              Text(
                'Dados do Nascimento',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isTablet ? 18 : isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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

          // Mostrar informações adicionais se disponíveis
          if (chart['zodiacSign']?.isNotEmpty ?? false) ...[
            const SizedBox(height: 16),
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

            // Informações astrológicas
            Row(
              children: [
                // Signo Solar
                Expanded(
                  child: _buildAstroInfo(
                    icon: Icons.wb_sunny,
                    label: 'Signo Solar',
                    value: chart['zodiacSign'],
                    color: ZodiacUtils.getSignColor(chart['zodiacSign']),
                    isSmallScreen: isSmallScreen,
                    isTablet: isTablet,
                  ),
                ),

                SizedBox(width: isTablet ? 16 : 12),

                // Elemento
                Expanded(
                  child: _buildAstroInfo(
                    icon: Icons.eco,
                    label: 'Elemento',
                    value: ZodiacUtils.getElement(chart['zodiacSign']),
                    color: AppTheme.accentColor,
                    isSmallScreen: isSmallScreen,
                    isTablet: isTablet,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Widget para informações astrológicas
  static Widget _buildAstroInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 12 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isTablet ? 12 : isSmallScreen ? 10 : 11,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: isTablet ? 18 : isSmallScreen ? 14 : 16,
              ),
              SizedBox(width: isTablet ? 8 : 6),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 14 : isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Método helper para formatar dados do mapa astral
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

    // Formatar datas
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
              zodiacSign = ZodiacUtils.getZodiacSignFromDate(birthDateTime);
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

    // Retornar dados formatados
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

// Classe helper para informações de seção
class _SectionInfo {
  final Color color;
  final IconData icon;

  _SectionInfo({
    required this.color,
    required this.icon,
  });
}