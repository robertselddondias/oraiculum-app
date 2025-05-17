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

  @override
  void initState() {
    super.initState();
    // Carregar dados iniciais
    _loadInitialData();
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
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 24),
                    _buildMainServices(),
                    const SizedBox(height: 24),
                    _buildDailyHoroscope(),
                    const SizedBox(height: 24),
                    _buildFeaturedMediums(),
                    const SizedBox(height: 24),
                    _buildPromotionalBanner(),
                    const SizedBox(height: 24),
                  ],
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
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Row(
          children: [
            Icon(
              Icons.nights_stay_rounded,
              size: 24,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              'Astral Connect',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
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
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Obx(() {
      final user = _authController.userModel.value;
      final greeting = _getGreeting();
      final userName = user != null ? user.name.split(' ')[0] : 'Visitante';

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                        ? NetworkImage(user.profileImageUrl!)
                        : null,
                    child: user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty
                        ? Icon(
                      Icons.person,
                      size: 25,
                      color: Theme.of(context).colorScheme.primary,
                    )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $userName!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'O que o universo tem para você hoje?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildMainServices() {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Serviços',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return _buildServiceCard(
              title: service['title'] as String,
              icon: service['icon'] as IconData,
              color: service['color'] as Color,
              onTap: () => Get.toNamed(service['route'] as String),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 100 * index),
              duration: const Duration(milliseconds: 300),
            );
          },
        ),
      ],
    );
  }

  Widget _buildServiceCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
                'Seu Horóscopo de Hoje',
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : horoscope == null
                  ? const Center(
                child: Text('Carregando seu horóscopo...'),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getZodiacIcon(horoscope.sign),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            horoscope.sign,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMMd().format(horoscope.date),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    horoscope.content.length > 150
                        ? '${horoscope.content.substring(0, 150)}...'
                        : horoscope.content,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.toNamed(AppRoutes.horoscope),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Ler Horóscopo Completo'),
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

  Widget _buildFeaturedMediums() {
    return Obx(() {
      final mediums = _mediumController.allMediums;
      final isLoading = _mediumController.isLoading.value;

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
            height: 200,
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
                return GestureDetector(
                  onTap: () {
                    _mediumController.selectMedium(medium.id);
                    Get.toNamed(AppRoutes.mediumProfile);
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(medium.imageUrl),
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              onBackgroundImageError: (_, __) {},
                              child: medium.imageUrl.isEmpty
                                  ? Icon(
                                Icons.person,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              medium.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  medium.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  ' (${medium.reviewsCount})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              medium.specialties.take(2).join(', '),
                              style: TextStyle(
                                fontSize: 12,
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
      },
      child: Container(
        height: 150,
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
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.nights_stay_rounded,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Oferta Especial',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ganhe 20% de desconto em créditos na primeira compra',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
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