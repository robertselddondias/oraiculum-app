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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibilidade'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSignSelectors(),
            const SizedBox(height: 24),
            _buildAnalyzeButton(),
            const SizedBox(height: 24),
            _buildResultCard(),
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
          'Análise de Compatibilidade',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Descubra a compatibilidade entre dois signos do zodíaco e entenda como suas energias interagem.',
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

  Widget _buildSignSelectors() {
    return Container(
      padding: const EdgeInsets.all(16),
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
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontSize: 14,
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
              borderRadius: BorderRadius.circular(12),
              items: _controller.zodiacSigns.map((String sign) {
                return DropdownMenuItem<String>(
                  value: sign,
                  child: Row(
                    children: [
                      Icon(
                        _getZodiacIcon(sign),
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(sign),
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

  Widget _buildAnalyzeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _analyzeCompatibility,
        icon: const Icon(Icons.psychology),
        label: const Text('Analisar Compatibilidade'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildResultCard() {
    return Obx(() {
      if (_isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      _getZodiacIcon(_sign1),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      indent: 16,
                      endIndent: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      _getZodiacIcon(_sign2),
                      color: Theme.of(context).colorScheme.primary,
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
                    style: const TextStyle(
                      fontSize: 18,
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
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Implementar compartilhamento
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Compartilhar Análise'),
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