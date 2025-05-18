import 'dart:convert';

import 'package:oraculum/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final HoroscopeController _horoscopeController = Get.find<HoroscopeController>();
  final MediumController _mediumController = Get.find<MediumController>();

  final RxMap<String, dynamic> _parsedHoroscope = <String, dynamic>{}.obs;

  @override
  void initState() {
    super.initState();
    // Carregar dados iniciais
    _loadInitialData();

    ever(_horoscopeController.dailyHoroscope, (horoscope) {
      if (horoscope != null) {
        _parseHoroscopeData(horoscope.content);
      }
    });

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

  Future<void> _loadInitialData() async {
    if (_authController.userModel.value != null) {
      // Determinar o signo do usuário com base na data de nascimento
      final birthDate = _authController.userModel.value!.birthDate;
      final sign = _getZodiacSign(birthDate);

      // Carregar horóscopo do usuário
      _horoscopeController.getDailyHoroscope(sign);
    } else {
      // Carregar horóscopo padrão
      _horoscopeController.getDailyHoroscope('Áries');
    }

    // Carregar médiuns em destaque
    _mediumController.loadMediums();
  }

  String _getZodiacSign(DateTime birthDate) {
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

  @override
  Widget build(BuildContext context) {
    // Obter dimensões da tela para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final padding = MediaQuery.of(context).padding;
    final isSmallScreen = screenWidth < 360;

    // Ajustar padding baseado no tamanho da tela
    final horizontalPadding = isSmallScreen ? 8.0 : 16.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenHeight - padding.top - padding.bottom - 80,  // Considerando bottom nav bar height
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(),
                      const SizedBox(height: 16),
                      _buildMainServices(context),
                      const SizedBox(height: 16),
                      _buildDailyHoroscope(),
                      const SizedBox(height: 16),
                      _buildFeaturedMediums(isSmallScreen),
                      const SizedBox(height: 16),
                      _buildPromotionalBanner(),
                      // Garantir espaço no final da página
                      SizedBox(height: padding.bottom + 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Oraculum',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
            ),
          ),
          child: const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 52, bottom: 16),
              child: Icon(
                Icons.nights_stay_rounded,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // Implementar notificações
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Obx(() {
      final user = _authController.userModel.value;
      final greeting = _getGreeting();
      final userName = user != null ? user.name.split(' ')[0] : 'Visitante';

      return Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty
                    ? Icon(
                  Icons.person,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$greeting, $userName!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'O que o universo tem para você hoje?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(
        begin: 0.2,
        end: 0,
        curve: Curves.easeOutQuad,
        duration: const Duration(milliseconds: 500),
      );
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  Widget _buildMainServices(BuildContext context) {
    final services = [
      {
        'title': 'Horóscopo',
        'icon': Icons.auto_graph,
        'color': const Color(0xFF6C63FF),
        'route': AppRoutes.horoscope,
      },
      {
        'title': 'Tarô',
        'icon': Icons.grid_view,
        'color': const Color(0xFFFF9D8A),
        'route': AppRoutes.tarotReading,
      },
      {
        'title': 'Médiuns',
        'icon': Icons.people,
        'color': const Color(0xFF8E78FF),
        'route': AppRoutes.mediumsList,
      },
      {
        'title': 'Mapa Astral',
        'icon': Icons.public,
        'color': const Color(0xFF392F5A),
        'route': AppRoutes.birthChart,
      },
    ];

    // Obtendo o tamanho da tela
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculando se é uma tela pequena (pode ajustar os valores conforme necessário)
    final isSmallScreen = screenWidth < 360 || screenHeight < 600;

    // Ajustes responsivos
    final crossAxisCount = screenWidth < 300 ? 1 : 2;
    final aspectRatio = screenWidth / screenHeight < 0.5
        ? 1.2  // Telas muito altas e estreitas
        : isSmallScreen
        ? 1.5
        : screenWidth > 500
        ? 2.0  // Tablets e telas maiores
        : 1.8; // Telas médias

    // Espaçamento responsivo
    final spacing = isSmallScreen ? 8.0 : 16.0;

    // Tamanho de fonte responsivo
    final titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final cardTitleFontSize = isSmallScreen ? 13.0 : 14.0;

    // Tamanho do ícone responsivo
    final iconSize = isSmallScreen ? 40.0 : 50.0;
    final iconInnerSize = isSmallScreen ? 20.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Serviços',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: spacing * 0.75),
        LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: aspectRatio,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _buildServiceCard(
                    context: context,
                    title: service['title'] as String,
                    icon: service['icon'] as IconData,
                    color: service['color'] as Color,
                    onTap: () => Get.toNamed(service['route'] as String),
                    iconSize: iconSize,
                    iconInnerSize: iconInnerSize,
                    titleFontSize: cardTitleFontSize,
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 * index),
                    duration: const Duration(milliseconds: 300),
                  );
                },
              );
            }
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double iconSize,
    required double iconInnerSize,
    required double titleFontSize,
  }) {
    // Obter o brilho atual do tema para determinar sombras e contrastes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: iconInnerSize,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyHoroscope() {
    return Obx(() {
      final horoscope = _horoscopeController.dailyHoroscope.value;
      final isLoading = _horoscopeController.isLoading.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seu Horóscopo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.horoscope),
                child: const Text('Ver Mais'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(
                child: SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
                  : horoscope == null
                  ? const Center(
                child: SizedBox(
                  height: 150,
                  child: Center(
                    child: Text('Carregando seu horóscopo...'),
                  ),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Positioned(
                          right: -50,
                          bottom: -20,
                          child: Opacity(
                            opacity: 0.2,
                            child: _buildZodiacImage(horoscope.sign, size: 200),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              horoscope.sign,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat.MMMMEEEEd('pt_BR').format(horoscope.date),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _parsedHoroscope['geral']['body'].length > 150
                        ? '${_parsedHoroscope['geral']['body'].substring(0, 150)}...'
                        : _parsedHoroscope['geral']['body'],
                    style: const TextStyle(height: 1.4, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.horoscope),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Ler Horóscopo Completo'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(
        delay: const Duration(milliseconds: 300),
        duration: const Duration(milliseconds: 500),
      );
    });
  }

  Widget _buildFeaturedMediums(bool isSmallScreen) {
    return Obx(() {
      final mediums = _mediumController.allMediums;
      final isLoading = _mediumController.isLoading.value;

      // Ajuste de altura baseado no tamanho da tela
      final cardHeight = isSmallScreen ? 180.0 : 200.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Médiuns em Destaque',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.mediumsList),
                child: const Text('Ver Todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: cardHeight,
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : mediums.isEmpty
                ? const Center(
              child: Text('Nenhum médium disponível no momento.'),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mediums.length > 5 ? 5 : mediums.length,
              itemBuilder: (context, index) {
                final medium = mediums[index];
                // Ajuste de largura baseado no tamanho da tela
                final cardWidth = isSmallScreen ? 140.0 : 160.0;

                return GestureDetector(
                  onTap: () {
                    _mediumController.selectMedium(medium.id);
                    Get.toNamed(AppRoutes.mediumProfile);
                  },
                  child: Container(
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: isSmallScreen ? 35 : 40,
                              backgroundImage: NetworkImage(medium.imageUrl),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              onBackgroundImageError: (_, __) {},
                              child: medium.imageUrl.isEmpty
                                  ? Icon(
                                Icons.person,
                                size: isSmallScreen ? 35 : 40,
                                color: Theme.of(context).colorScheme.primary,
                              )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              medium.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 14 : 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  medium.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    ' (${medium.reviewsCount})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              medium.specialties.take(1).join(', '),
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPromotionalBanner() {
    return GestureDetector(
      onTap: () {
        // Implementar navegação para promoção
        Get.toNamed(AppRoutes.paymentMethods);
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            // Efeito de fundo
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.nights_stay_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Oferta Especial',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ganhe 20% de desconto em créditos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Aproveitar',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 500),
      duration: const Duration(milliseconds: 500),
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