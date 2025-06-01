import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:share_plus/share_plus.dart';

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  final HoroscopeController _controller = Get.find<HoroscopeController>();
  final AuthController _authController = Get.find<AuthController>();
  final RxMap<String, dynamic> _parsedHoroscope = <String, dynamic>{}.obs;
  final RxBool _isInitialLoadComplete = false.obs;

  @override
  void initState() {
    super.initState();
    // Inicializar formatação de data em português
    initializeDateFormatting('pt_BR', null);

    // Carregar o signo do usuário logado ou padrão automaticamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserSign();
    });

    // Observar mudanças no horóscopo diário
    ever(_controller.dailyHoroscope, (horoscope) {
      if (horoscope != null) {
        _parseHoroscopeData(horoscope.content);
        _isInitialLoadComplete.value = true;
      }
    });
  }

  // Método para carregar o signo do usuário logado
  Future<void> _loadUserSign() async {
    // Verificar se o usuário está logado e tem um perfil
    if (_authController.userModel.value != null && _authController.isLoggedIn) {
      final birthDate = _authController.userModel.value!.birthDate;
      final userSign = _getZodiacSignFromDate(birthDate);

      // Carregar o horóscopo para o signo do usuário
      await _controller.getDailyHoroscope(userSign);
    } else {
      // Carregar horóscopo padrão se não tiver nenhum usuário logado
      await _controller.getDailyHoroscope('Áries');
    }
  }

  // Método para determinar o signo com base na data de nascimento
  String _getZodiacSignFromDate(DateTime birthDate) {
    final day = birthDate.day;
    final month = birthDate.month;

    if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) return 'Aquário';
    if ((month == 2 && day >= 19) || (month == 3 && day <= 20)) return 'Peixes';
    if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'Áries';
    if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'Touro';
    if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'Gêmeos';
    if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'Câncer';
    if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'Leão';
    if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'Virgem';
    if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'Libra';
    if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'Escorpião';
    if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) return 'Sagitário';

    return 'Capricórnio';
  }

  void _parseHoroscopeData(String content) {
    try {
      // Tentar analisar o conteúdo como JSON
      final Map<String, dynamic> data = json.decode(content);
      _parsedHoroscope.value = data;
    } catch (e) {
      // Se falhar, usar o conteúdo como texto geral
      _parsedHoroscope.value = {
        'geral': {'title': 'Geral', 'body': content},
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 200.0,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Obx(() => Text(
                  _controller.currentSign.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                )),
                background: Obx(() => _buildSignBackground()),
              ),
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
          ];
        },
        body: Column(
          children: [
            _buildSignSelector(isSmallScreen),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value || !_isInitialLoadComplete.value) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Carregando seu horóscopo...'),
                      ],
                    ),
                  );
                }
                return _buildHoroscopeContent(isSmallScreen, padding);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignBackground() {
    final sign = _controller.currentSign.value;
    final color = _getSignColor(sign);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.7),
            color.withOpacity(0.9),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Efeito de partículas estreladas
          ...List.generate(20, (index) {
            final top = 20.0 + (index * 10);
            final left = (index % 5) * 80.0;
            final size = 2.0 + (index % 3);

            return Positioned(
              top: top,
              left: left,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            );
          }),

          // Imagem do signo com opacidade
          Positioned(
            right: -50,
            bottom: -20,
            child: Opacity(
              opacity: 0.2,
              child: _buildZodiacImage(sign, size: 200),
            ),
          ),

          // Gradiente de sobreposição para melhorar a legibilidade
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5],
              ),
            ),
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
            final signColor = _getSignColor(sign);

            // Destacar o signo do usuário se estiver logado
            final isUserSign = _authController.userModel.value != null &&
                _getZodiacSignFromDate(_authController.userModel.value!.birthDate) == sign;

            return GestureDetector(
              onTap: () => _controller.getDailyHoroscope(sign),
              child: Container(
                width: itemWidth,
                margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 4 : 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? signColor.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Signo selecionado - versão melhorada com efeito de destaque
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? signColor
                                  : isUserSign
                                  ? signColor.withOpacity(0.5)
                                  : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: signColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                                : null,
                          ),
                          child: ClipOval(
                            child: _buildZodiacImage(
                              sign,
                              size: iconSize * 0.6,
                            ),
                          ),
                        ),

                        // Indicador de que é o signo do usuário
                        if (isUserSign && !isSelected)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: signColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sign,
                      style: TextStyle(
                        fontWeight: isSelected || isUserSign ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? signColor
                            : isUserSign
                            ? signColor.withOpacity(0.7)
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

      final mainColor = _getSignColor(_controller.currentSign.value);

      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: mainColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: mainColor.withOpacity(0.3))
                  ),
                  child: Text(
                    DateFormat.MMMMEEEEd('pt_BR').format(horoscope.date),
                    style: TextStyle(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seções do horóscopo
            if (_parsedHoroscope.containsKey('geral'))
              _buildHoroscopeSection(
                title: _parsedHoroscope['geral']['title'] ?? 'Visão Geral',
                content: _parsedHoroscope['geral']['body'] ?? '',
                icon: Icons.auto_awesome,
                color: mainColor,
                isSmallScreen: isSmallScreen,
              ),

            if (_parsedHoroscope.containsKey('amor'))
              _buildHoroscopeSection(
                title: _parsedHoroscope['amor']['title'] ?? 'Amor e Relacionamentos',
                content: _parsedHoroscope['amor']['body'] ?? '',
                icon: Icons.favorite,
                color: Colors.redAccent,
                isSmallScreen: isSmallScreen,
              ),

            if (_parsedHoroscope.containsKey('profissional'))
              _buildHoroscopeSection(
                title: _parsedHoroscope['profissional']['title'] ?? 'Carreira e Finanças',
                content: _parsedHoroscope['profissional']['body'] ?? '',
                icon: Icons.work,
                color: Colors.blueAccent,
                isSmallScreen: isSmallScreen,
              ),

            if (_parsedHoroscope.containsKey('conselhos'))
              _buildHoroscopeSection(
                title: _parsedHoroscope['conselhos']['title'] ?? 'Conselhos',
                content: _parsedHoroscope['conselhos']['body'] ?? '',
                icon: Icons.lightbulb,
                color: Colors.amberAccent,
                isSmallScreen: isSmallScreen,
              ),

            if (_parsedHoroscope.containsKey('numeros_sorte'))
              _buildLuckyNumbers(
                numbers: _parsedHoroscope['numeros_sorte'] ?? [],
                isSmallScreen: isSmallScreen,
                mainColor: mainColor,
              ),

            const SizedBox(height: 32),

            // Botões de ação
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  context: context,
                  icon: Icons.compare_arrows,
                  label: 'Compatibilidade',
                  onTap: () => Get.toNamed('/compatibility'),
                  isSmallScreen: isSmallScreen,
                  color: mainColor,
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.account_circle,
                  label: 'Mapa Astral',
                  onTap: () => Get.toNamed('/birthChart'),
                  isSmallScreen: isSmallScreen,
                  color: mainColor,
                ),
              ],
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 500),
            ),

            const SizedBox(height: 16),

            // Botão compartilhar
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  String horoscopo = _parsedHoroscope['geral']['body'].substring(0, 180);
                  SharePlus.instance.share(
                      ShareParams(text: 'Meu horóscopo de hoje:\n$horoscopo... \n\nBaixe agora o Oraculum.')
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar Horóscopo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: mainColor,
                  side: BorderSide(color: mainColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHoroscopeSection({
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
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.2),
                ),
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
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildLuckyNumbers({
    required List<dynamic> numbers,
    required bool isSmallScreen,
    required Color mainColor,
  }) {
    final numbersList = numbers.map((e) => e.toString()).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.casino,
                  color: mainColor,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Números da Sorte',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: mainColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: numbersList.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 50,
                  height: 50,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        mainColor,
                        mainColor.withAlpha(200),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: mainColor.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      numbersList[index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ).animate().scale(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSmallScreen,
    required Color color,
  }) {
    final buttonWidth = isSmallScreen ? 150.0 : 170.0;
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: iconSize,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
              ),
            ),
          ],
        ),
      ),
    );
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