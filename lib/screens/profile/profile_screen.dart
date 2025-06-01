import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final PaymentController _paymentController = Get.find<PaymentController>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  // Estatísticas reais do usuário
  int _totalReadings = 0;
  int _favoriteReadings = 0;
  int _totalCharts = 0;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _paymentController.loadUserCredits();
    _setupAnimations();
    _loadUserStats();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _topAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  /// Carregar estatísticas reais do usuário
  Future<void> _loadUserStats() async {
    try {
      final userId = _authController.currentUser.value?.uid;
      if (userId == null) return;

      setState(() {
        _statsLoading = true;
      });

      // Carregar cada estatística individualmente para melhor controle de tipos
      int totalReadings = 0;
      int favoriteReadings = 0;
      int totalCharts = 0;

      try {
        // 1. Buscar leituras de tarô
        final tarotReadingsSnapshot = await _firebaseService.getUserTarotReadings(userId);
        totalReadings = tarotReadingsSnapshot.docs.length;
        debugPrint('✅ Leituras de tarô carregadas: $totalReadings');
      } catch (e) {
        debugPrint('❌ Erro ao carregar leituras de tarô: $e');
      }

      try {
        // 2. Buscar cards favoritos
        final favoriteCardsList = await _firebaseService.getUserFavoriteTarotCards(userId);
        favoriteReadings = favoriteCardsList.length;
        debugPrint('✅ Cards favoritos carregados: $favoriteReadings');
      } catch (e) {
        debugPrint('❌ Erro ao carregar cards favoritos: $e');
      }

      try {
        // 3. Buscar mapas astrais
        final birthChartsList = await _firebaseService.getUserBirthCharts(userId);
        totalCharts = birthChartsList.length;
        debugPrint('✅ Mapas astrais carregados: $totalCharts');
      } catch (e) {
        debugPrint('❌ Erro ao carregar mapas astrais: $e');
      }

      setState(() {
        _totalReadings = totalReadings;
        _favoriteReadings = favoriteReadings;
        _totalCharts = totalCharts;
        _statsLoading = false;
      });

      debugPrint('✅ Estatísticas finais: $_totalReadings leituras, $_favoriteReadings favoritas, $_totalCharts mapas');

    } catch (e) {
      debugPrint('❌ Erro geral ao carregar estatísticas: $e');
      setState(() {
        _statsLoading = false;
      });

      Get.snackbar(
        'Aviso',
        'Não foi possível carregar todas as estatísticas',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Refresh das informações quando o usuário retorna à tela
  Future<void> _refreshProfile() async {
    try {
      // Executar refresh em paralelo, mas de forma mais controlada
      await Future.wait([
        _paymentController.loadUserCredits(),
        _authController.loadUserData(),
      ]);

      // Carregar estatísticas separadamente para evitar conflitos de tipo
      await _loadUserStats();

    } catch (e) {
      debugPrint('❌ Erro ao fazer refresh do perfil: $e');
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar todas as informações',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }

  // Função responsiva para obter dimensões
  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    return {
      'padding': isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0,
      'avatarSize': isTablet ? 70.0 : isSmallScreen ? 50.0 : 60.0,
      'titleSize': isTablet ? 28.0 : isSmallScreen ? 20.0 : 24.0,
      'subtitleSize': isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0,
      'bodySize': isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0,
      'captionSize': isTablet ? 14.0 : isSmallScreen ? 11.0 : 12.0,
      'cardPadding': isTablet ? 24.0 : isSmallScreen ? 16.0 : 20.0,
      'iconSize': isTablet ? 28.0 : isSmallScreen ? 20.0 : 24.0,
      'spacing': isTablet ? 24.0 : isSmallScreen ? 16.0 : 20.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: const [
                  Color(0xFF392F5A),
                  Color(0xFF483D8B),
                  Color(0xFF8C6BAE),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Partículas/estrelas para o fundo
              ...ZodiacUtils.buildStarParticles(context, isTablet ? 35 : 25),

              Column(
                children: [
                  _buildAppBar(dimensions),
                  Expanded(
                    child: Obx(() {
                      if (_authController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }

                      final user = _authController.userModel.value;
                      if (user == null) {
                        return Center(
                          child: Card(
                            margin: EdgeInsets.all(dimensions['padding']!),
                            color: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(dimensions['cardPadding']!),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: dimensions['iconSize']! * 2,
                                  ),
                                  SizedBox(height: dimensions['spacing']!),
                                  Text(
                                    'Não foi possível carregar os dados do usuário',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: dimensions['bodySize']!,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: dimensions['spacing']!),
                                  ElevatedButton(
                                    onPressed: _refreshProfile,
                                    child: const Text('Tentar Novamente'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _refreshProfile,
                        color: const Color(0xFF6C63FF),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(dimensions['padding']!),
                          child: Column(
                            children: [
                              _buildProfileHeader(user, dimensions),
                              SizedBox(height: dimensions['spacing']!),
                              _buildCreditsCard(dimensions),
                              SizedBox(height: dimensions['spacing']!),
                              _buildStatsRow(dimensions),
                              SizedBox(height: dimensions['spacing']!),
                              _buildMenuOptions(dimensions),
                              SizedBox(height: dimensions['spacing']!),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Map<String, double> dimensions) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions['padding']!,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: dimensions['iconSize']!,
            ),
            splashRadius: 24,
          ),
          Expanded(
            child: Text(
              'Meu Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: dimensions['titleSize']! - 4,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              color: Colors.white,
              size: dimensions['iconSize']!,
            ),
            onPressed: () => Get.toNamed(AppRoutes.settings),
            splashRadius: 24,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildProfileHeader(user, Map<String, double> dimensions) {
    final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate);
    final signColor = ZodiacUtils.getSignColor(userSign);

    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        child: Column(
          children: [
            // Avatar e informações básicas
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Círculo de fundo com cor do signo
                    Container(
                      width: dimensions['avatarSize']! + 20,
                      height: dimensions['avatarSize']! + 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            signColor.withOpacity(0.3),
                            signColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                    // Avatar principal
                    CircleAvatar(
                      radius: dimensions['avatarSize']! / 2,
                      backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                          ? NetworkImage(user.profileImageUrl!)
                          : null,
                      backgroundColor: signColor.withOpacity(0.2),
                      child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                          ? Icon(
                        Icons.person,
                        size: dimensions['avatarSize']! / 2,
                        color: signColor,
                      )
                          : null,
                    ),
                    // Botão de editar foto
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: signColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: signColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: dimensions['bodySize']!,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: dimensions['spacing']!),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: dimensions['titleSize']! - 4,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: dimensions['spacing']! / 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: dimensions['bodySize']!,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: dimensions['spacing']! / 2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: dimensions['spacing']! / 2,
                          vertical: dimensions['spacing']! / 4,
                        ),
                        decoration: BoxDecoration(
                          color: signColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: signColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ZodiacUtils.buildZodiacImage(
                              userSign,
                              size: dimensions['bodySize']!,
                            ),
                            SizedBox(width: dimensions['spacing']! / 3),
                            Text(
                              userSign,
                              style: TextStyle(
                                color: signColor,
                                fontSize: dimensions['captionSize']! + 1,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão de editar perfil
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.white.withOpacity(0.7),
                    size: dimensions['bodySize']! + 2,
                  ),
                  onPressed: _showEditProfileDialog,
                  tooltip: 'Editar Perfil',
                ),
              ],
            ),

            Divider(
              height: dimensions['spacing']! * 2,
              color: Colors.white24,
            ),

            // Informações adicionais
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.calendar_today,
                    title: 'Membro desde',
                    value: DateFormat.yMMMd('pt_BR').format(user.createdAt),
                    color: Colors.blue,
                    dimensions: dimensions,
                  ),
                ),
                SizedBox(width: dimensions['spacing']!),
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.star,
                    title: 'Elemento',
                    value: ZodiacUtils.getElement(userSign),
                    color: signColor,
                    dimensions: dimensions,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 600),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Map<String, double> dimensions,
  }) {
    return Container(
      padding: EdgeInsets.all(dimensions['spacing']! / 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: dimensions['bodySize']! + 2,
          ),
          SizedBox(height: dimensions['spacing']! / 3),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: dimensions['captionSize']!,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: dimensions['spacing']! / 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: dimensions['captionSize']! + 1,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsCard(Map<String, double> dimensions) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8E78FF), Color(0xFFFF9D8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seus Créditos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: dimensions['bodySize']!,
                      ),
                    ),
                    SizedBox(height: dimensions['spacing']! / 4),
                    Obx(() => Text(
                      'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: dimensions['titleSize']!,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    )),
                  ],
                ),
                Container(
                  padding: EdgeInsets.all(dimensions['spacing']! / 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: dimensions['iconSize']!,
                  ),
                ),
              ],
            ),
            SizedBox(height: dimensions['spacing']!),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
                icon: Icon(
                  Icons.add_card,
                  size: dimensions['bodySize']! + 2,
                ),
                label: Text(
                  'Adicionar Créditos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: dimensions['bodySize']!,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6C63FF),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: dimensions['spacing']! / 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 600),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildStatsRow(Map<String, double> dimensions) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.auto_awesome,
            title: 'Leituras',
            value: _statsLoading ? '...' : _totalReadings.toString(),
            color: Colors.purple,
            dimensions: dimensions,
            isLoading: _statsLoading,
          ),
        ),
        SizedBox(width: dimensions['spacing']! / 2),
        Expanded(
          child: _buildStatCard(
            icon: Icons.favorite,
            title: 'Favoritas',
            value: _statsLoading ? '...' : _favoriteReadings.toString(),
            color: Colors.pink,
            dimensions: dimensions,
            isLoading: _statsLoading,
          ),
        ),
        SizedBox(width: dimensions['spacing']! / 2),
        Expanded(
          child: _buildStatCard(
            icon: Icons.timeline,
            title: 'Mapas',
            value: _statsLoading ? '...' : _totalCharts.toString(),
            color: Colors.blue,
            dimensions: dimensions,
            isLoading: _statsLoading,
          ),
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 600),
      duration: const Duration(milliseconds: 600),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required Map<String, double> dimensions,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 4,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(dimensions['spacing']! / 1.5),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: dimensions['iconSize']!,
            ),
            SizedBox(height: dimensions['spacing']! / 3),
            isLoading
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
                : Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: dimensions['subtitleSize']!,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: dimensions['spacing']! / 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: dimensions['captionSize']!,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions(Map<String, double> dimensions) {
    final menuItems = [
      {
        'title': 'Leituras Favoritas',
        'icon': Icons.favorite,
        'color': Colors.pink,
        'onTap': () => Get.toNamed(AppRoutes.savedReadingsList),
      },
      {
        'title': 'Histórico de Pagamentos',
        'icon': Icons.receipt_long,
        'color': Colors.green,
        'onTap': () => Get.toNamed(AppRoutes.paymentHistory),
      },
      {
        'title': 'Configurações',
        'icon': Icons.settings,
        'color': Colors.blue,
        'onTap': () => Get.toNamed(AppRoutes.settings),
      },
      {
        'title': 'Sair',
        'icon': Icons.exit_to_app,
        'color': Colors.red,
        'onTap': _logout,
      },
    ];

    return Card(
      elevation: 4,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dimensions['spacing']! / 2),
        child: Column(
          children: menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: dimensions['cardPadding']!,
                    vertical: dimensions['spacing']! / 4,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(dimensions['spacing']! / 2.5),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                      size: dimensions['bodySize']! + 2,
                    ),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: dimensions['bodySize']!,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withOpacity(0.5),
                    size: dimensions['bodySize']!,
                  ),
                  onTap: item['onTap'] as VoidCallback,
                ),
                if (index < menuItems.length - 1)
                  Divider(
                    height: 1,
                    color: Colors.white.withOpacity(0.1),
                    indent: dimensions['cardPadding']! + dimensions['iconSize']! + 20,
                    endIndent: dimensions['cardPadding']!,
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 800),
      duration: const Duration(milliseconds: 600),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 500),
    );
  }

  /// Dialog para editar informações básicas do perfil
  void _showEditProfileDialog() {
    final user = _authController.userModel.value;
    if (user == null) return;

    final nameController = TextEditingController(text: user.name);
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Editar Perfil',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nome Completo',
                    labelStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(
                      Icons.person,
                      color: Color(0xFF6C63FF),
                    ),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Colors.white24,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(
                        color: Color(0xFF6C63FF),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nome é obrigatório';
                    }
                    if (value.trim().split(' ').length < 2) {
                      return 'Digite seu nome completo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Email e data de nascimento não podem ser alterados por questões de segurança.',
                          style: TextStyle(
                            color: Colors.orange.shade300,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                try {
                  await _authController.updateUserProfile(
                    displayName: nameController.text.trim(),
                  );

                  Get.back();
                  Get.snackbar(
                    'Sucesso',
                    'Perfil atualizado com sucesso!',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Erro',
                    'Não foi possível atualizar o perfil: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      try {
        _authController.isLoading.value = true;

        // Upload da imagem para o Firebase Storage
        final firebaseService = Get.find<FirebaseService>();
        final downloadUrl = await firebaseService.uploadProfileImage(
          _authController.currentUser.value!.uid,
          imageFile.path,
        );

        // Atualizar o perfil do usuário
        await _authController.updateUserProfile(photoURL: downloadUrl);

        Get.snackbar(
          'Sucesso',
          'Foto de perfil atualizada com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Não foi possível atualizar a foto de perfil: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        _authController.isLoading.value = false;
      }
    }
  }

  void _logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Sair',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Você realmente deseja sair da sua conta?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authController.signOut();
    }
  }
}