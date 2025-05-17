import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';

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

  @override
  Widget build(BuildContext context) {
    // Obter dimensões para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibilidade'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildSignSelectors(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildAnalyzeButton(isSmallScreen),
            SizedBox(height: isSmallScreen ? 16 : 24),
            _buildResultCard(isSmallScreen, padding),
          ],
        ),
      ),
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
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Descubra a compatibilidade entre dois signos do zodíaco e entenda como suas energias interagem.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: subtitleSize,
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
    final containerPadding = isSmallScreen ? 12.0 : 16.0;
    final labelSize = isSmallScreen ? 12.0 : 14.0;
    final iconSize = isSmallScreen ? 40.0 : 50.0;

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
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
              SizedBox(width: isSmallScreen ? 8 : 16),
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                  size: iconSize * 0.6,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 16),
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
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildSignSelector({
    required String title,
    required String currentSign,
    required ValueChanged<String?> onChanged,
    required bool isSmallScreen,
  }) {
    final titleSize = isSmallScreen ? 12.0 : 14.0;
    final dropdownItemSize = isSmallScreen ? 13.0 : 15.0;
    final iconSize = isSmallScreen ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: titleSize,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentSign,
              icon: const Icon(Icons.arrow_drop_down),
              isExpanded: true,
              padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12
              ),
              borderRadius: BorderRadius.circular(12),
              items: _controller.zodiacSigns.map((String sign) {
                return DropdownMenuItem<String>(
                  value: sign,
                  child: Row(
                    children: [
                      Icon(
                        _getZodiacIcon(sign),
                        size: iconSize,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: isSmallScreen ? 4 : 8),
                      Text(
                        sign,
                        style: TextStyle(
                            fontSize: dropdownItemSize
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
      ],
    );
  }

  Widget _buildAnalyzeButton(bool isSmallScreen) {
    final buttonHeight = isSmallScreen ? 48.0 : 56.0;
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final iconSize = isSmallScreen ? 18.0 : 22.0;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton.icon(
        onPressed: _analyzeCompatibility,
        icon: Icon(
          Icons.psychology,
          size: iconSize,
        ),
        label: Text(
          'Analisar Compatibilidade',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildResultCard(bool isSmallScreen, double padding) {
    final titleSize = isSmallScreen ? 16.0 : 18.0;
    final contentSize = isSmallScreen ? 14.0 : 16.0;
    final iconSize = isSmallScreen ? 32.0 : 40.0;
    final buttonSize = isSmallScreen ? 14.0 : 16.0;

    return Obx(() {
      if (_isLoading.value) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_compatibilityResult.isEmpty) {
        return Container();
      }

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    radius: iconSize / 2,
                    child: Icon(
                      _getZodiacIcon(_sign1),
                      color: Theme.of(context).colorScheme.primary,
                      size: iconSize / 2,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      indent: isSmallScreen ? 8 : 16,
                      endIndent: isSmallScreen ? 8 : 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    radius: iconSize / 2,
                    child: Icon(
                      _getZodiacIcon(_sign2),
                      color: Theme.of(context).colorScheme.primary,
                      size: iconSize / 2,
                    ),
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
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _compatibilityResult.value,
                style: TextStyle(
                  fontSize: contentSize,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // Implementar compartilhamento
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compatibilidade compartilhada!')),
                  );
                },
                icon: const Icon(Icons.share),
                label: Text(
                  'Compartilhar Análise',
                  style: TextStyle(
                    fontSize: buttonSize,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(
        delay: const Duration(milliseconds: 300),
        duration: const Duration(milliseconds: 500),
      );
    });
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
    try {
      final result = await _controller.getCompatibilityAnalysis(_sign1, _sign2);
      _compatibilityResult.value = result;
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

  IconData _getZodiacIcon(String sign) {
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