import 'package:oraculum/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

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
    // Carregar horóscopo padrão se não tiver nenhum selecionado
    if (_controller.currentSign.isEmpty) {
      _controller.getDailyHoroscope('Áries');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Horóscopo Diário'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => Get.toNamed(AppRoutes.compatibility),
            tooltip: 'Compatibilidade',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => Get.toNamed(AppRoutes.birthChart),
            tooltip: 'Mapa Astral',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSignSelector(),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildHoroscopeContent();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSignSelector() {
    return Container(
      height: 120,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        itemCount: _controller.zodiacSigns.length,
        itemBuilder: (context, index) {
          final sign = _controller.zodiacSigns[index];
          return Obx(() {
            final isSelected = _controller.currentSign.value == sign;
            return GestureDetector(
              onTap: () => _controller.getDailyHoroscope(sign),
              child: Container(
                width: 70,
                margin: const EdgeInsets.symmetric(horizontal: 8),
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
                      width: 48,
                      height: 48,
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
                        child: Icon(
                          _getZodiacIcon(sign),
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sign,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
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

  Widget _buildHoroscopeContent() {
    return Obx(() {
      final horoscope = _controller.dailyHoroscope.value;
      if (horoscope == null) {
        return const Center(child: Text('Selecione um signo para ver o horóscopo'));
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getZodiacIcon(_controller.currentSign.value),
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _controller.currentSign.value,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMMd().format(horoscope.date),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // Implementar compartilhamento
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  horoscope.content,
                  style: Theme.of(context).textTheme.bodyLarge,
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
                  icon: Icons.compare_arrows,
                  label: 'Compatibilidade',
                  onTap: () => Get.toNamed(AppRoutes.compatibility),
                ),
                _buildActionButton(
                  icon: Icons.account_circle,
                  label: 'Mapa Astral',
                  onTap: () => Get.toNamed(AppRoutes.birthChart),
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
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
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
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
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