import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({Key? key}) : super(key: key);

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  final HoroscopeController _controller = Get.find<HoroscopeController>();

  @override
  void initState() {
    super.initState();
    // Inicializar formatação de data em português
    initializeDateFormatting('pt_BR', null);

    // Carregar horóscopo padrão se não tiver nenhum selecionado
    if (_controller.currentSign.isEmpty) {
      _controller.getDailyHoroscope('Áries');
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
        title: const Text('Horóscopo Diário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => Get.toNamed('/compatibility'),
            tooltip: 'Compatibilidade',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Get.toNamed('/birthChart'),
            tooltip: 'Mapa Astral',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSignSelector(isSmallScreen),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildHoroscopeContent(isSmallScreen, padding);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSignSelector(bool isSmallScreen) {
    final signHeight = isSmallScreen ? 100.0 : 120.0;
    final itemWidth = isSmallScreen ? 60.0 : 70.0;
    final iconSize = isSmallScreen ? 40.0 : 48.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;

    return Container(
      height: signHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: isSmallScreen ? 4 : 8),
        itemCount: _controller.zodiacSigns.length,
        itemBuilder: (context, index) {
          final sign = _controller.zodiacSigns[index];
          return Obx(() {
            final isSelected = _controller.currentSign.value == sign;
            return GestureDetector(
              onTap: () => _controller.getDailyHoroscope(sign),
              child: Container(
                width: itemWidth,
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: _buildSignImage(
                          sign: sign,
                          size: isSmallScreen ? 24 : 28,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sign,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: fontSize,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildHoroscopeContent(bool isSmallScreen, double padding) {
    return Obx(() {
      final horoscope = _controller.dailyHoroscope.value;
      if (horoscope == null) {
        return const Center(child: Text('Selecione um signo para ver o horóscopo'));
      }

      final titleSize = isSmallScreen ? 18.0 : 20.0;
      final dateSize = isSmallScreen ? 12.0 : 14.0;
      final contentSize = isSmallScreen ? 14.0 : 16.0;
      final iconSize = isSmallScreen ? 50.0 : 60.0;
      final buttonSize = isSmallScreen ? 14.0 : 16.0;

      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _buildSignImage(
                      sign: _controller.currentSign.value,
                      size: iconSize * 0.6,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controller.currentSign.value,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: titleSize,
                        ),
                      ),
                      Text(
                        DateFormat.MMMMEEEEd('pt_BR').format(horoscope.date),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: dateSize,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Implementar compartilhamento
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Compartilhando horóscopo...'))
                    );
                  },
                  tooltip: 'Compartilhar',
                ),
              ],
            ).animate().fadeIn().slideX(
              begin: -0.1,
              end: 0,
              curve: Curves.easeOutQuad,
              duration: const Duration(milliseconds: 400),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Text(
                  horoscope.content,
                  style: TextStyle(
                    fontSize: contentSize,
                    height: 1.5,
                  ),
                ),
              ),
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 500),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context: context,
                  icon: Icons.compare_arrows,
                  label: 'Compatibilidade',
                  onTap: () => Get.toNamed('/compatibility'),
                  isSmallScreen: isSmallScreen,
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.account_circle,
                  label: 'Mapa Astral',
                  onTap: () => Get.toNamed('/birthChart'),
                  isSmallScreen: isSmallScreen,
                ),
              ],
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 500),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSmallScreen,
  }) {
    final buttonWidth = isSmallScreen ? 130.0 : 150.0;
    final iconSize = isSmallScreen ? 28.0 : 32.0;
    final fontSize = isSmallScreen ? 12.0 : 14.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: buttonWidth,
        padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
            horizontal: isSmallScreen ? 6 : 8
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: iconSize,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função que retorna a imagem do signo (com tratamento para caso a imagem não seja encontrada)
  Widget _buildSignImage({required String sign, required double size, required Color color}) {
    return Image.asset(
      _getSignAssetPath(sign),
      width: size,
      height: size,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Fallback para ícone caso a imagem não seja encontrada
        return Icon(
          _getSignIcon(sign),
          color: color,
          size: size,
        );
      },
    );
  }

  // Função que retorna o caminho para a imagem do signo
  String _getSignAssetPath(String sign) {
    // Normaliza o nome do signo para corresponder ao nome do arquivo
    // Converte para minúsculas e remove acentos
    String normalizedSign = sign.toLowerCase()
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


    switch (sign) {
      case 'Áries':
        normalizedSign = 'aries';
        break;
      case 'Touro':
        normalizedSign = 'touro';
        break;
      case 'Gêmeos':
        normalizedSign = 'gemeos';
        break;
      case 'Câncer':
        normalizedSign = 'cancer';
        break;
      case 'Leão':
        normalizedSign = 'leao';
        break;
      case 'Virgem':
        normalizedSign = 'virgem';
        break;
      case 'Libra':
        normalizedSign = 'libra';
        break;
      case 'Escorpião':
        normalizedSign = 'escorpiao';
        break;
      case 'Sagitário':
        normalizedSign = 'sargitario';
        break;
      case 'Capricórnio':
        normalizedSign = 'capricornio';
        break;
      case 'Aquário':
        normalizedSign = 'aquario';
        break;
      case 'Peixes':
        normalizedSign = 'peixes';
        break;
    }

    return 'assets/icons/$normalizedSign.png';
  }

  // Ícones para usar como fallback caso as imagens não sejam encontradas
  IconData _getSignIcon(String sign) {
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
}