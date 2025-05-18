import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:oraculum/utils/zodiac_utils.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({Key? key}) : super(key: key);

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> with SingleTickerProviderStateMixin {
  final HoroscopeController _controller = Get.find<HoroscopeController>();

  String _sign1 = 'Áries';
  String _sign2 = 'Touro';
  final RxString _compatibilityResult = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxMap<String, dynamic> _parsedCompatibility = <String, dynamic>{}.obs;

  // Controlador para animação
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializar formatação de data em português
    initializeDateFormatting('pt_BR', null);

    // Configurar animação
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _parseCompatibilityData(String content) {
    try {
      // Tentar analisar o conteúdo como JSON
      final Map<String, dynamic> data = json.decode(content);
      _parsedCompatibility.value = data;
    } catch (e) {
      // Se falhar, usar o conteúdo como texto geral
      _parsedCompatibility.value = {
        'geral': {'title': 'Compatibilidade Geral', 'body': content},
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: Obx(() {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isSmallScreen),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildHeader(isSmallScreen),
                    const SizedBox(height: 24),
                    _buildSignSelectors(isSmallScreen, screenWidth),
                    const SizedBox(height: 30),
                    _buildAnalyzeButton(isSmallScreen),
                    const SizedBox(height: 24),
                    if (_isLoading.value)
                      _buildLoadingIndicator(isSmallScreen)
                    else if (_compatibilityResult.isNotEmpty)
                      _buildResultCard(isSmallScreen),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSliverAppBar(bool isSmallScreen) {
    final color1 = ZodiacUtils.getSignColor(_sign1);
    final color2 = ZodiacUtils.getSignColor(_sign2);

    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Compatibilidade',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color1, color2],
            ),
          ),
          child: Stack(
            children: [
              // Partículas/estrelas
              ...ZodiacUtils.buildStarParticles(context, 20),

              // Sobreposição de gradiente para garantir legibilidade do texto
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.0),
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),

              // Corrigindo o erro: Não coloque Positioned dentro de um container normal
              // Sempre use Stack como pai de Positioned
              Positioned(
                right: -50,
                bottom: -20,
                child: Opacity(
                  opacity: 0.2,
                  child: Icon(
                    ZodiacUtils.getZodiacFallbackIcon(_sign1),
                    size: 120,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            _showInfoDialog(context);
          },
        ),
      ],
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Descubra a Compatibilidade Astrológica',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecione dois signos para analisar a compatibilidade de relacionamento, amizade e trabalho.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: isSmallScreen ? 14 : 16,
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

  Widget _buildSignSelectors(bool isSmallScreen, double screenWidth) {
    final cardHeight = screenWidth > 600 ? 320.0 : isSmallScreen ? 260.0 : 290.0;
    final iconSize = isSmallScreen ? 80.0 : 100.0;
    final heartSize = isSmallScreen ? 40.0 : 50.0;
    final signSize = isSmallScreen ? 14.0 : 16.0;

    return Container(
      width: double.infinity,
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSignDropdown(
                  label: 'Primeiro Signo',
                  currentSign: _sign1,
                  onChanged: (String? newSign) {
                    if (newSign != null) {
                      setState(() {
                        _sign1 = newSign;
                      });
                      _compatibilityResult.value = '';
                      _parsedCompatibility.clear();
                    }
                  },
                  isSmallScreen: isSmallScreen,
                ),
                _buildSignDropdown(
                  label: 'Segundo Signo',
                  currentSign: _sign2,
                  onChanged: (String? newSign) {
                    if (newSign != null) {
                      setState(() {
                        _sign2 = newSign;
                      });
                      _compatibilityResult.value = '';
                      _parsedCompatibility.clear();
                    }
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Primeiro signo
                _buildSignPreview(
                  sign: _sign1,
                  iconSize: iconSize,
                  textSize: signSize,
                  isSmallScreen: isSmallScreen,
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                  delay: const Duration(milliseconds: 500),
                ).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOut,
                ),

                // Ícone do coração pulsante
                Container(
                  width: heartSize,
                  height: heartSize,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                  ),
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                ).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.4, 1.4),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                ),

                // Segundo signo
                _buildSignPreview(
                  sign: _sign2,
                  iconSize: iconSize,
                  textSize: signSize,
                  isSmallScreen: isSmallScreen,
                ).animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                  delay: const Duration(milliseconds: 800),
                ).scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: const Duration(seconds: 3),
                  curve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildSignDropdown({
    required String label,
    required String currentSign,
    required ValueChanged<String?> onChanged,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: DropdownButton<String>(
            value: currentSign,
            isExpanded: false,
            underline: Container(),
            icon: const Icon(Icons.keyboard_arrow_down),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: isSmallScreen ? 14 : 16,
            ),
            items: ZodiacUtils.allSigns.map((String sign) {
              return DropdownMenuItem<String>(
                value: sign,
                child: Text(sign),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSignPreview({
    required String sign,
    required double iconSize,
    required double textSize,
    required bool isSmallScreen,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ZodiacUtils.buildSignAvatar(
          context: context,
          sign: sign,
          size: iconSize,
          highlight: true,
        ),
        const SizedBox(height: 8),
        Text(
          sign,
          style: TextStyle(
            fontSize: textSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          ZodiacUtils.getElement(sign),
          style: TextStyle(
            fontSize: textSize - 2,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton(bool isSmallScreen) {
    final buttonTextSize = isSmallScreen ? 14.0 : 16.0;
    final color1 = ZodiacUtils.getSignColor(_sign1);
    final color2 = ZodiacUtils.getSignColor(_sign2);

    return Container(
      width: double.infinity,
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
      child: ElevatedButton(
        onPressed: _analyzeCompatibility,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined),
            const SizedBox(width: 8),
            Text(
              'Analisar Compatibilidade',
              style: TextStyle(
                fontSize: buttonTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildLoadingIndicator(bool isSmallScreen) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Analisando a compatibilidade entre\n$_sign1 e $_sign2...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(bool isSmallScreen) {
    // Calcular as cores com base nos signos selecionados
    final color1 = ZodiacUtils.getSignColor(_sign1);
    final color2 = ZodiacUtils.getSignColor(_sign2);

    // Formatar a data atual em português
    final today = DateTime.now();
    final formattedDate = DateFormat.MMMMEEEEd('pt_BR').format(today);

    // Calcular o score (compatibilidade simulada)
    final score = ZodiacUtils.calculateCompatibilityScore(_sign1, _sign2);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com signos e data
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color1.withOpacity(0.9),
                  color2.withOpacity(0.9),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Corrigindo o problema de overflow
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: isSmallScreen ? 20 : 24,
                      child: ZodiacUtils.buildZodiacImage(_sign1, size: isSmallScreen ? 24 : 28, color: Colors.white),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: Colors.white24,
                      radius: isSmallScreen ? 20 : 24,
                      child: ZodiacUtils.buildZodiacImage(_sign2, size: isSmallScreen ? 24 : 28, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '$_sign1 & $_sign2',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 20),
                // Barra de compatibilidade corrigida
                _buildCompatibilityBar(score: score, isSmallScreen: isSmallScreen),
              ],
            ),
          ),

          // Conteúdo da análise
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: SingleChildScrollView( // Prevenindo overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Corrigindo o problema de overflow
                children: [
                  // Construir seções baseadas no JSON retornado
                  if (_parsedCompatibility.containsKey('geral'))
                    _buildCompatibilitySection(
                      title: _parsedCompatibility['geral']['title'] ?? 'Compatibilidade Geral',
                      content: _parsedCompatibility['geral']['body'] ?? '',
                      icon: Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.primary,
                      isSmallScreen: isSmallScreen,
                    ),

                  if (_parsedCompatibility.containsKey('emocional'))
                    _buildCompatibilitySection(
                      title: _parsedCompatibility['emocional']['title'] ?? 'Compatibilidade Emocional',
                      content: _parsedCompatibility['emocional']['body'] ?? '',
                      icon: Icons.favorite,
                      color: Colors.redAccent,
                      isSmallScreen: isSmallScreen,
                    ),

                  if (_parsedCompatibility.containsKey('comunicacao'))
                    _buildCompatibilitySection(
                      title: _parsedCompatibility['comunicacao']['title'] ?? 'Comunicação',
                      content: _parsedCompatibility['comunicacao']['body'] ?? '',
                      icon: Icons.message,
                      color: Colors.blueAccent,
                      isSmallScreen: isSmallScreen,
                    ),

                  if (_parsedCompatibility.containsKey('sexual'))
                    _buildCompatibilitySection(
                      title: _parsedCompatibility['sexual']['title'] ?? 'Compatibilidade Sexual',
                      content: _parsedCompatibility['sexual']['body'] ?? '',
                      icon: Icons.spa,
                      color: Colors.purpleAccent,
                      isSmallScreen: isSmallScreen,
                    ),

                  if (_parsedCompatibility.containsKey('pontos_fortes'))
                    _buildCompatibilitySection(
                      title: _parsedCompatibility['pontos_fortes']['title'] ?? 'Pontos Fortes',
                      content: _parsedCompatibility['pontos_fortes']['body'] ?? '',
                      icon: Icons.thumb_up,
                      color: Colors.greenAccent.shade700,
                      isSmallScreen: isSmallScreen,
                    ),

                  if (_parsedCompatibility.containsKey('desafios'))
                    _buildCompatibilitySection(
                      title: _parsedCompatibility['desafios']['title'] ?? 'Desafios',
                      content: _parsedCompatibility['desafios']['body'] ?? '',
                      icon: Icons.warning_amber,
                      color: Colors.orangeAccent,
                      isSmallScreen: isSmallScreen,
                    ),

                  if (_parsedCompatibility.containsKey('conselhos'))
                    _buildCompatibilitySection(
                      title: _parsedCompatibility['conselhos']['title'] ?? 'Conselhos',
                      content: _parsedCompatibility['conselhos']['body'] ?? '',
                      icon: Icons.lightbulb,
                      color: Colors.amberAccent,
                      isSmallScreen: isSmallScreen,
                    ),

                  // Caso não seja JSON, mostrar texto completo
                  if (_parsedCompatibility.isEmpty || (_parsedCompatibility.containsKey('geral') && _parsedCompatibility.length == 1))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _compatibilityResult.value,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          height: 1.6,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Botões de ação
                  _buildActionButtons(
                    color1: color1,
                    color2: color2,
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 800),
    ).slideY(
      begin: 0.1,
      end: 0,
      curve: Curves.easeOutQuad,
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildCompatibilityBar({
    required double score,
    required bool isSmallScreen,
  }) {
    // Determinar cor baseada no score
    Color barColor;
    String compatibilityText;

    if (score < 0.3) {
      barColor = Colors.red;
      compatibilityText = 'Desafiadora';
    } else if (score < 0.6) {
      barColor = Colors.orangeAccent;
      compatibilityText = 'Moderada';
    } else if (score < 0.8) {
      barColor = Colors.lightGreenAccent;
      compatibilityText = 'Boa';
    } else {
      barColor = Colors.green;
      compatibilityText = 'Excelente';
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // Reduzir ao tamanho mínimo
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Compatibilidade: $compatibilityText',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
            Text(
              '${(score * 100).toInt()}%',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 12 : 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(5),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Container(
                        width: constraints.maxWidth * score * _progressAnimation.value,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor.withOpacity(0.7), barColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompatibilitySection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Prevenindo overflow
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons({
    required Color color1,
    required Color color2,
    required bool isSmallScreen,
  }) {
    return Row(
        children: [
    Expanded(
    child: OutlinedButton.icon(
    onPressed: () {
      // Compartilhar o resultado
      Get.snackbar(
        'Compartilhar',
        'Função de compartilhamento em desenvolvimento',
        snackPosition: SnackPosition.BOTTOM,
      );
    },
    icon: const Icon(Icons.share),
    label: Text(
    'Compartilhar',
    style: TextStyle(
    fontSize: isSmallScreen ? 14 : 16,
    ),
    ),
    style: OutlinedButton.styleFrom(
    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    ),
    ),
    ),
    ),
    const SizedBox(width: 16),
    Expanded(
    child: ElevatedButton.icon(
      onPressed: () {
        // Salvar nos favoritos
        Get.snackbar(
          'Favoritos',
          'Análise salva nos favoritos',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      icon: const Icon(Icons.favorite_border),
      label: Text(
        'Favoritar',
        style: TextStyle(
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    ),
        ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre Compatibilidade Astrológica'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'A compatibilidade astrológica analisa como os diferentes signos do zodíaco interagem entre si. Esta análise considera:',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(
                icon: Icons.whatshot,
                title: 'Elementos',
                description: 'Fogo, Terra, Ar e Água - cada signo pertence a um destes elementos, que determinam parte de sua compatibilidade.',
              ),
              _buildInfoItem(
                icon: Icons.settings,
                title: 'Modalidades',
                description: 'Cardinal, Fixo ou Mutável - determina como o signo aborda situações e mudanças.',
              ),
              _buildInfoItem(
                icon: Icons.public,
                title: 'Planetas Regentes',
                description: 'Cada signo é regido por um planeta que influencia suas características.',
              ),
              _buildInfoItem(
                icon: Icons.bar_chart,
                title: 'Aspectos',
                description: 'As posições dos planetas formam ângulos (aspectos) que podem ser harmônicos ou desafiadores.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Lembre-se que a compatibilidade astrológica é apenas um guia, e não determina o sucesso ou fracasso de um relacionamento. Comunicação, respeito e compreensão são sempre os fundamentos mais importantes.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendi'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _analyzeCompatibility() async {
    if (_sign1 == _sign2) {
      Get.snackbar(
        'Aviso',
        'Selecione signos diferentes para uma análise de compatibilidade mais precisa',
        backgroundColor: Colors.amber,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _isLoading.value = true;
    _compatibilityResult.value = '';
    _parsedCompatibility.clear();

    try {
      // Obter a análise de compatibilidade
      final result = await _controller.getCompatibilityAnalysis(_sign1, _sign2);
      _compatibilityResult.value = result;

      // Tentar analisar como JSON
      _parseCompatibilityData(result);

      // Iniciar animação da barra de compatibilidade
      _animationController.reset();
      _animationController.forward();

    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível realizar a análise de compatibilidade',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}