import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({Key? key}) : super(key: key);

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  final HoroscopeController _controller = Get.find<HoroscopeController>();

  String _sign1 = 'Áries';
  String _sign2 = 'Touro';
  final RxString _compatibilityResult = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxMap<String, dynamic> _parsedCompatibility = <String, dynamic>{}.obs;

  @override
  void initState() {
    super.initState();
    // Inicializar formatação de data em português
    initializeDateFormatting('pt_BR', null);
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
      appBar: AppBar(
        title: const Text('Compatibilidade'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary.withOpacity(0.9),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Obx(() {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.05),
                Theme.of(context).colorScheme.surface,
              ],
              stops: const [0.0, 0.2],
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isSmallScreen),
                SizedBox(height: isSmallScreen ? 16 : 24),
                _buildSignSelectors(isSmallScreen),
                SizedBox(height: isSmallScreen ? 24 : 32),
                _buildAnalyzeButton(isSmallScreen),
                SizedBox(height: isSmallScreen ? 24 : 32),
                if (_isLoading.value)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        const Text('Analisando compatibilidade...'),
                      ],
                    ),
                  )
                else if (_compatibilityResult.isNotEmpty)
                  _buildResultCard(isSmallScreen),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    final titleSize = isSmallScreen ? 20.0 : 24.0;
    final subtitleSize = isSmallScreen ? 14.0 : 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise de Compatibilidade',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Descubra a compatibilidade entre dois signos do zodíaco e entenda como suas energias interagem em diferentes aspectos da vida.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: subtitleSize,
            height: 1.4,
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

  Widget _buildSignSelectors(bool isSmallScreen) {
    final iconSize = isSmallScreen ? 60.0 : 80.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Expanded(
                child: _buildSignSelector(
                  title: 'Primeiro Signo',
                  currentSign: _sign1,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sign1 = value;
                      });
                    }
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ),
              SizedBox(width: isSmallScreen ? 16 : 24),
              Container(
                width: iconSize * 0.5,
                height: iconSize * 0.5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.redAccent,
                  size: iconSize * 0.25,
                ),
              ).animate(
                onPlay: (controller) => controller.repeat(
                    reverse: true,
                    period: const Duration(seconds: 2)
                ),
              ).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
              ),
              SizedBox(width: isSmallScreen ? 16 : 24),
              Expanded(
                child: _buildSignSelector(
                  title: 'Segundo Signo',
                  currentSign: _sign2,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sign2 = value;
                      });
                    }
                  },
                  isSmallScreen: isSmallScreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Visualização dos signos selecionados
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSelectedSignPreview(_sign1, isSmallScreen),
              SizedBox(width: isSmallScreen ? 10 : 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              SizedBox(width: isSmallScreen ? 10 : 20),
              _buildSelectedSignPreview(_sign2, isSmallScreen),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildSelectedSignPreview(String sign, bool isSmallScreen) {
    final size = isSmallScreen ? 80.0 : 100.0;
    final color = _getSignColor(sign);

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: _buildZodiacImage(sign, size: size * 0.6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sign,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 14 : 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSignSelector({
    required String title,
    required String currentSign,
    required ValueChanged<String?> onChanged,
    required bool isSmallScreen,
  }) {
    final labelSize = isSmallScreen ? 12.0 : 14.0;
    final dropdownTextSize = isSmallScreen ? 14.0 : 16.0;
    final iconSize = isSmallScreen ? 18.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: labelSize,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: DropdownButtonHideUnderline(
            child: ButtonTheme(
              alignedDropdown: true,
              child: DropdownButton<String>(
                value: currentSign,
                icon: const Icon(Icons.arrow_drop_down),
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                borderRadius: BorderRadius.circular(12),
                items: _controller.zodiacSigns.map((String sign) {
                  return DropdownMenuItem<String>(
                    value: sign,
                    child: Row(
                      children: [
                        SizedBox(
                          width: iconSize * 1.5,
                          height: iconSize * 1.5,
                          child: _buildZodiacImage(sign, size: iconSize),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sign,
                          style: TextStyle(
                            fontSize: dropdownTextSize,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzeButton(bool isSmallScreen) {
    final buttonTextSize = isSmallScreen ? 14.0 : 16.0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _analyzeCompatibility,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology),
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

  Widget _buildResultCard(bool isSmallScreen) {
    // Calcular as cores com base nos signos selecionados
    final color1 = _getSignColor(_sign1);
    final color2 = _getSignColor(_sign2);

    // Formatar a data atual em português
    final today = DateTime.now();
    final formattedDate = DateFormat.MMMMEEEEd('pt_BR').format(today);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color1.withOpacity(0.05),
              color2.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com signos e data
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color1.withOpacity(0.1),
                  child: _buildZodiacImage(_sign1, size: 24),
                ),
                Expanded(
                  child: Divider(
                    indent: 16,
                    endIndent: 16,
                    color: color1.withOpacity(0.5),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: color2.withOpacity(0.1),
                  child: _buildZodiacImage(_sign2, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$_sign1 ❤️ $_sign2',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Exibir data formatada em português
            Center(
              child: Text(
                formattedDate,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            const Divider(height: 32),

            // Seções da compatibilidade em formato segmentado
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
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _compatibilityResult.value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    height: 1.5,
                  ),
                ),
              ),

            const SizedBox(height: 24),
            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Implementar compartilhamento
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Compartilhando análise...')),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: Text(
                      'Compartilhar',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navegar para mapa astral
                      Get.toNamed('/birthChart');
                    },
                    icon: const Icon(Icons.public),
                    label: Text(
                      'Mapa Astral',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildCompatibilitySection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(
                color: color.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 500),
    );
  }

  Future<void> _analyzeCompatibility() async {
    if (_sign1 == _sign2) {
      Get.snackbar(
        'Aviso',
        'Selecione signos diferentes para a análise de compatibilidade',
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

  // Widget para exibir a imagem do signo
  Widget _buildZodiacImage(String sign, {double? size, Color? color}) {
    // Normaliza o nome do signo para corresponder ao nome do arquivo
    final signAssetName = _getSignAssetName(sign);

    try {
      return Image.asset(
        'assets/images/zodiac/$signAssetName.png',
        width: size,
        height: size,
        color: color, // Aplicar uma cor de filtro, se fornecida
        errorBuilder: (context, error, stackTrace) {
          // Fallback para ícone em caso de erro no carregamento da imagem
          return Icon(
            _getZodiacFallbackIcon(sign),
            size: size,
            color: color ?? _getSignColor(sign),
          );
        },
      );
    } catch (e) {
      // Fallback para ícone em caso de exceção
      return Icon(
        _getZodiacFallbackIcon(sign),
        size: size,
        color: color ?? _getSignColor(sign),
      );
    }
  }

  // Função para normalizar o nome do signo para o nome do arquivo
  String _getSignAssetName(String sign) {
    switch (sign.toLowerCase()) {
      case 'áries':
        return 'aries';
      case 'touro':
        return 'touro';
      case 'gêmeos':
        return 'gemeos';
      case 'câncer':
        return 'cancer';
      case 'leão':
        return 'leao';
      case 'virgem':
        return 'virgem';
      case 'libra':
        return 'libra';
      case 'escorpião':
        return 'escorpiao';
      case 'sagitário':
        return 'sagitario';
      case 'capricórnio':
        return 'capricornio';
      case 'aquário':
        return 'aquario';
      case 'peixes':
        return 'peixes';
      default:
        return sign.toLowerCase()
            .replaceAll('á', 'a')
            .replaceAll('â', 'a')
            .replaceAll('ã', 'a')
            .replaceAll('à', 'a')
            .replaceAll('é', 'e')
            .replaceAll('ê', 'e')
            .replaceAll('í', 'i')
            .replaceAll('ó', 'o')
            .replaceAll('ô', 'o')
            .replaceAll('õ', 'o')
            .replaceAll('ú', 'u')
            .replaceAll('ç', 'c');
    }
  }

  // Ícones de fallback caso a imagem não seja encontrada
  IconData _getZodiacFallbackIcon(String sign) {
    switch (sign) {
      case 'Áries':
        return Icons.fitness_center;
      case 'Touro':
        return Icons.spa;
      case 'Gêmeos':
        return Icons.people;
      case 'Câncer':
        return Icons.home;
      case 'Leão':
        return Icons.star;
      case 'Virgem':
        return Icons.healing;
      case 'Libra':
        return Icons.balance;
      case 'Escorpião':
        return Icons.psychology;
      case 'Sagitário':
        return Icons.explore;
      case 'Capricórnio':
        return Icons.landscape;
      case 'Aquário':
        return Icons.waves;
      case 'Peixes':
        return Icons.water;
      default:
        return Icons.stars;
    }
  }

  // Função para obter a cor associada a cada signo
  Color _getSignColor(String sign) {
    switch (sign) {
      case 'Áries':
        return Colors.red;
      case 'Touro':
        return Colors.green.shade700;
      case 'Gêmeos':
        return Colors.amberAccent.shade700;
      case 'Câncer':
        return Colors.blue.shade300;
      case 'Leão':
        return Colors.orange;
      case 'Virgem':
        return Colors.green.shade400;
      case 'Libra':
        return Colors.pink.shade300;
      case 'Escorpião':
        return Colors.red.shade900;
      case 'Sagitário':
        return Colors.purple.shade300;
      case 'Capricórnio':
        return Colors.brown.shade700;
      case 'Aquário':
        return Colors.blueAccent;
      case 'Peixes':
        return Colors.indigo.shade300;
      default:
        return Colors.deepPurple;
    }
  }
}