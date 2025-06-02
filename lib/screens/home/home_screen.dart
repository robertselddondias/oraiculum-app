import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final AuthController _authController = Get.find<AuthController>();
  final HoroscopeController _horoscopeController = Get.find<HoroscopeController>();
  final MediumController _mediumController = Get.find<MediumController>();
  final PaymentController _paymentController = Get.find<PaymentController>();

  final RxMap<String, dynamic> _parsedHoroscope = <String, dynamic>{}.obs;
  final RxBool _dataLoaded = false.obs;

  // Controlador para animações
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    // Registrar o observer para o ciclo de vida do app
    WidgetsBinding.instance.addObserver(this);

    // Configurar animações
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Carregar dados iniciais
    _loadInitialData();

    ever(_horoscopeController.dailyHoroscope, (horoscope) {
      if (horoscope != null) {
        _parseHoroscopeData(horoscope.content);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFcmTokenOnHomeStart();
    });

    // Iniciar animações
    _animationController.forward();
  }

  Future<void> _updateFcmTokenOnHomeStart() async {
    try {
      debugPrint('🏠 Home iniciada - verificando FCM Token...');

      // Aguardar carregamento inicial
      await Future.delayed(const Duration(seconds: 1));

      final authController = Get.find<AuthController>();
      await authController.updateUserFcmToken();

      debugPrint('✅ FCM Token verificado na home');
    } catch (e) {
      debugPrint('❌ Erro ao verificar FCM Token na home: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar dados quando as dependências mudarem
    _loadInitialData();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarregar dados quando o widget for atualizado
    _loadInitialData();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recarregar dados quando o aplicativo voltar ao primeiro plano
    if (state == AppLifecycleState.resumed) {
      _dataLoaded.value = false;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
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
    // Evitar carregamento múltiplo desnecessário se os dados já estão carregados
    if (_dataLoaded.value) return;

    _dataLoaded.value = true;

    try {
      if (_authController.userModel.value != null) {
        // Determinar o signo do usuário com base na data de nascimento
        final birthDate = _authController.userModel.value!.birthDate;
        final sign = ZodiacUtils.getZodiacSignFromDate(birthDate);

        // Carregar horóscopo do usuário
        await _horoscopeController.getDailyHoroscope(sign);

        // Carregar créditos do usuário
        await _paymentController.loadUserCredits();
      } else {
        // Carregar horóscopo padrão
        await _horoscopeController.getDailyHoroscope('Áries');
      }

      // Carregar médiuns em destaque
      await _mediumController.loadMediums();
    } catch (e) {
      // Em caso de erro, permitir tentar novamente
      _dataLoaded.value = false;
      debugPrint('Erro ao carregar dados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões da tela para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Ajustar padding baseado no tamanho da tela
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Reset o status para forçar recarga de dados
          _dataLoaded.value = false;
          await _loadInitialData();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(isSmallScreen),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16.0,
                ),
                child: AnimatedBuilder(
                  animation: _fadeInAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeInAnimation.value,
                      child: child,
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserProfileCard(isSmallScreen),
                      const SizedBox(height: 24),
                      _buildCreditDisplay(isSmallScreen),
                      const SizedBox(height: 24),
                      _buildMainServices(context),
                      const SizedBox(height: 24),
                      _buildDailyHoroscope(isSmallScreen),
                      const SizedBox(height: 24),
                      // _buildFeaturedMediums(isSmallScreen),
                      // const SizedBox(height: 24),
                      _buildPromotionalBanner(isSmallScreen),
                      // Garantir espaço no final da página
                      const SizedBox(height: 24),
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

  Widget _buildSliverAppBar(bool isSmallScreen) {
    final userSign = _authController.userModel.value != null
        ? ZodiacUtils.getZodiacSignFromDate(_authController.userModel.value!.birthDate)
        : 'Áries';
    final signColor = ZodiacUtils.getSignColor(userSign);

    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nights_stay_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Oraculum',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF392F5A),
                signColor.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Partículas para o efeito de estrelas
              ...ZodiacUtils.buildStarParticles(context, 30),

              // Ícone do signo do usuário com baixa opacidade
              Positioned(
                right: -30,
                bottom: -30,
                child: Opacity(
                  opacity: 0.12,
                  child: Icon(
                    ZodiacUtils.getZodiacFallbackIcon(userSign),
                    size: 120,
                    color: Colors.white,
                  ),
                ),
              ),

              // Gradiente de sobreposição para melhorar a legibilidade do texto
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.4),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.notifications_outlined),
      //     onPressed: () {
      //       Get.toNamed('/notificationList');
      //     },
      //     tooltip: 'Notificações',
      //   ),
      //   const SizedBox(width: 8),
      // ],
    );
  }

  Widget _buildUserProfileCard(bool isSmallScreen) {
    return Obx(() {
      final user = _authController.userModel.value;
      final greeting = _getGreeting();
      final userName = user != null ? user.name.split(' ')[0] : 'Visitante';

      // Determinar o signo do usuário
      final userSign = user != null
          ? ZodiacUtils.getZodiacSignFromDate(user.birthDate)
          : 'Áries';

      final signColor = ZodiacUtils.getSignColor(userSign);

      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).cardColor,
                Theme.of(context).cardColor.withOpacity(0.9),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar do usuário
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: signColor.withOpacity(0.1),
                      backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      child: user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty
                          ? Icon(
                        Icons.person,
                        size: 28,
                        color: signColor,
                      )
                          : null,
                    ),
                    // Indicador de signo
                    ZodiacUtils.buildZodiacImage(
                      userSign,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$greeting, $userName!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            ZodiacUtils.getZodiacFallbackIcon(userSign),
                            size: 14,
                            color: signColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            userSign,
                            style: TextStyle(
                              fontSize: 14,
                              color: signColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            ZodiacUtils.getElement(userSign),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_right),
                  onPressed: () => Get.toNamed(AppRoutes.profile),
                  tooltip: 'Ver perfil',
                ),
              ],
            ),
          ),
        ),
      ).animate()
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad, duration: 500.ms);
    });
  }

  // Novo widget para exibir os créditos do usuário
  Widget _buildCreditDisplay(bool isSmallScreen) {
    return Obx(() {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF392F5A).withOpacity(0.9),
                const Color(0xFF8C6BAE).withOpacity(0.9),
              ],
            ),
          ),
          child: Row(
            children: [
              // Ícone de carteira
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Informações de crédito
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seus Créditos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Botão para adicionar créditos
              ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6C63FF),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Adicionar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
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
        'subtitle': 'Seu guia diário',
        'icon': Icons.auto_graph,
        'color': const Color(0xFF6C63FF),
        'route': AppRoutes.horoscope,
      },
      {
        'title': 'Tarô',
        'subtitle': 'Orientação das cartas',
        'icon': Icons.grid_view,
        'color': const Color(0xFFFF9D8A),
        'route': AppRoutes.tarotReading,
      },
      // {
      //   'title': 'Médiuns',
      //   'subtitle': 'Consultas ao vivo',
      //   'icon': Icons.people,
      //   'color': const Color(0xFF8E78FF),
      //   'route': AppRoutes.mediumsList,
      // },
      {
        'title': 'Mapa Astral',
        'subtitle': 'Análise completa',
        'icon': Icons.public,
        'color': const Color(0xFF392F5A),
        'route': AppRoutes.birthChart,
      },
    ];

    // Obtendo o tamanho da tela
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Calculando se é uma tela pequena
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
    final subtitleFontSize = isSmallScreen ? 11.0 : 12.0;

    // Tamanho do ícone responsivo
    final iconSize = isSmallScreen ? 40.0 : 50.0;
    final iconInnerSize = isSmallScreen ? 20.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Serviços',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Navegar para tela de todos os serviços
              },
              icon: const Icon(Icons.explore, size: 16),
              label: const Text('Explorar'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        SizedBox(height: spacing * 0.5),
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
                    subtitle: service['subtitle'] as String,
                    icon: service['icon'] as IconData,
                    color: service['color'] as Color,
                    onTap: () => Get.toNamed(service['route'] as String),
                    iconSize: iconSize,
                    iconInnerSize: iconInnerSize,
                    titleFontSize: cardTitleFontSize,
                    subtitleFontSize: subtitleFontSize,
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 100 * index),
                    duration: const Duration(milliseconds: 400),
                  ).scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
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
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double iconSize,
    required double iconInnerSize,
    required double titleFontSize,
    required double subtitleFontSize,
  }) {
    // Obter o brilho atual do tema para determinar sombras e contrastes
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.08),
                color.withOpacity(0.03),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDarkMode ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconInnerSize,
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyHoroscope(bool isSmallScreen) {
    return Obx(() {
      final horoscope = _horoscopeController.dailyHoroscope.value;
      final isLoading = _horoscopeController.isLoading.value;

      // Detectar o signo atual
      final currentSign = horoscope?.sign ?? 'Áries';
      final signColor = ZodiacUtils.getSignColor(currentSign);

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
              TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.horoscope),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver Mais'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 3,
            shadowColor: signColor.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).cardColor,
                    Theme.of(context).cardColor.withOpacity(0.9),
                  ],
                ),
              ),
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
                      ZodiacUtils.buildSignAvatar(
                        context: context,
                        sign: currentSign,
                        size: 50,
                        highlight: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSign,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: signColor,
                              ),
                            ),
                            Text(
                              DateFormat.MMMMEEEEd('pt_BR').format(horoscope.date),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildHoroscopeTag(
                                  ZodiacUtils.getElement(currentSign),
                                  signColor,
                                ),
                                _buildHoroscopeTag(
                                  ZodiacUtils.getModality(currentSign),
                                  signColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Linha com ícone de destaque
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: signColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _parsedHoroscope['geral'] != null && _parsedHoroscope['geral']['body'] != null
                              ? (_parsedHoroscope['geral']['body'].length > 180
                              ? '${_parsedHoroscope['geral']['body'].substring(0, 180)}...'
                              : _parsedHoroscope['geral']['body'])
                              : 'Carregando...',
                          style: const TextStyle(
                            height: 1.4,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Números da sorte se disponíveis
                  if (_parsedHoroscope.containsKey('numeros_sorte') &&
                      _parsedHoroscope['numeros_sorte'] is List &&
                      _parsedHoroscope['numeros_sorte'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Números da Sorte:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _parsedHoroscope['numeros_sorte'].length,
                            itemBuilder: (context, index) {
                              final number = _parsedHoroscope['numeros_sorte'][index].toString();
                              return Container(
                                width: 36,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: signColor.withOpacity(0.15),
                                  border: Border.all(
                                    color: signColor,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    number,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: signColor,
                                    ),
                                  ),
                                ),
                              ).animate(delay: Duration(milliseconds: index * 100))
                                  .scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1.0, 1.0),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.elasticOut,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Botão para ler mais
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.toNamed(AppRoutes.horoscope),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: signColor,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  Widget _buildHoroscopeTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFeaturedMediums(bool isSmallScreen) {
    return Obx(() {
      final mediums = _mediumController.allMediums;
      final isLoading = _mediumController.isLoading.value;

      // Ajuste de altura baseado no tamanho da tela
      final cardHeight = isSmallScreen ? 220.0 : 240.0;

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
              TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.mediumsList),
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Ver Todos'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                final cardWidth = isSmallScreen ? 150.0 : 170.0;

                return GestureDetector(
                  onTap: () {
                    _mediumController.selectMedium(medium.id);
                    Get.toNamed(AppRoutes.mediumProfile);
                  },
                  child: Container(
                    width: cardWidth,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(0.1),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Área superior com imagem e disponibilidade
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              SizedBox(
                                height: 100,
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: medium.imageUrl.isNotEmpty
                                      ? Image.network(
                                    medium.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 100,
                                    errorBuilder: (context, error, stack) {
                                      return Container(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        child: const Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.white54,
                                        ),
                                      );
                                    },
                                  )
                                      : Container(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                              ),
                              // Indicador de disponibilidade
                              if (medium.isAvailable)
                                Container(
                                  margin: const EdgeInsets.all(8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Online',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // Detalhes do médium
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  medium.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
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
                                    Text(
                                      ' (${medium.reviewsCount})',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Especialidades do médium
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: medium.specialties
                                      .take(2)
                                      .map((specialty) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      specialty,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                                      .toList(),
                                ),
                                const SizedBox(height: 12),
                                // Preço
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}/min',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 400),
                ).slideX(
                  begin: 0.1,
                  end: 0,
                  duration: const Duration(milliseconds: 300),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildPromotionalBanner(bool isSmallScreen) {
    return GestureDetector(
      onTap: () {
        // Implementar navegação para promoção
        Get.toNamed(AppRoutes.paymentMethods);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF392F5A),
                  Color(0xFF8C6BAE),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Elementos de design de fundo
                ...ZodiacUtils.buildStarParticles(context, 20, maxHeight: 140),

                // Ícone decorativo
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: Icon(
                    Icons.nights_stay_rounded,
                    size: 120,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                // Conteúdo do banner
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'OFERTA ESPECIAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ganhe ate 15% de desconto em créditos',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oferta válida por tempo limitado',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF392F5A),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Aproveitar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Text('Saiba mais'),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 500),
      duration: const Duration(milliseconds: 500),
    );
  }
}