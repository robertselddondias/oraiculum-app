import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/screens/astrology/widgets/interpretation_section.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/utils/zodiac_utils.dart';
import 'package:share_plus/share_plus.dart';

class BirthChartHistoryScreen extends StatefulWidget {
  const BirthChartHistoryScreen({super.key});

  @override
  State<BirthChartHistoryScreen> createState() => _BirthChartHistoryScreenState();
}

class _BirthChartHistoryScreenState extends State<BirthChartHistoryScreen>
    with SingleTickerProviderStateMixin {
  final HoroscopeController _controller = Get.find<HoroscopeController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  final RxList<Map<String, dynamic>> _birthCharts = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _selectedChartId = ''.obs;
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();

  // Animação de fundo
  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadBirthCharts();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadBirthCharts() async {
    if (_authController.currentUser.value == null) return;

    _isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.uid;
      final charts = await _firebaseService.getUserBirthCharts(userId);
      _birthCharts.value = charts;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar o histórico: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _deleteBirthChart(String chartId) async {
    try {
      await _controller.deleteBirthChart(chartId);
      _birthCharts.removeWhere((chart) => chart['id'] == chartId);
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível remover o mapa astral: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _toggleFavorite(String chartId, bool currentFavorite) async {
    try {
      await _controller.toggleBirthChartFavorite(chartId, !currentFavorite);

      final chartIndex = _birthCharts.indexWhere((chart) => chart['id'] == chartId);
      if (chartIndex != -1) {
        _birthCharts[chartIndex]['isFavorite'] = !currentFavorite;
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar favorito: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _searchCharts(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _loadBirthCharts();
    } else {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    if (_authController.currentUser.value == null) return;

    _isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.uid;
      final results = await _firebaseService.searchBirthCharts(userId, query);
      _birthCharts.value = results;
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro na busca: $e',
        backgroundColor: AppTheme.errorColor,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void _showChartDetails(Map<String, dynamic> chart) {
    _selectedChartId.value = chart['id'];
    Get.bottomSheet(
      _buildChartDetailsBottomSheet(chart),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _shareChart(Map<String, dynamic> chart) {
    final chartData = _controller.exportBirthChartAsText(chart);
    SharePlus.instance.share(ShareParams(text: chartData));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
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
              // Partículas de fundo
              ...ZodiacUtils.buildStarParticles(context, 30),

              Column(
                children: [
                  _buildAppBar(context, isSmallScreen, isTablet),
                  _buildSearchBar(isSmallScreen, isTablet),
                  Expanded(
                    child: Obx(() {
                      if (_isLoading.value) {
                        return _buildLoadingState();
                      }

                      if (_birthCharts.isEmpty) {
                        return _buildEmptyState(isSmallScreen, isTablet);
                      }

                      return _buildChartsList(isSmallScreen, isTablet);
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isSmallScreen, bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : isTablet ? 24.0 : 20.0,
        vertical: 16.0,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.2),
            Colors.black.withOpacity(0.1),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico de Mapas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 24 : isSmallScreen ? 18 : 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() => Text(
                  '${_birthCharts.length} ${_birthCharts.length == 1 ? 'mapa encontrado' : 'mapas encontrados'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isTablet ? 16 : isSmallScreen ? 12 : 14,
                  ),
                )),
              ],
            ),
          ),
          IconButton(
            onPressed: _loadBirthCharts,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSearchBar(bool isSmallScreen, bool isTablet) {
    final searchPadding = isSmallScreen ? 12.0 : isTablet ? 24.0 : 16.0;

    return Container(
      margin: EdgeInsets.all(searchPadding),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _searchCharts,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Buscar por nome, local ou data...',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: isTablet ? 16 : isSmallScreen ? 14 : 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.white.withOpacity(0.7),
            size: isTablet ? 24 : 20,
          ),
          suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              _searchCharts('');
            },
            icon: Icon(
              Icons.clear,
              color: Colors.white.withOpacity(0.7),
              size: isTablet ? 24 : 20,
            ),
          )
              : const SizedBox.shrink()),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : 12,
            horizontal: isTablet ? 20 : 16,
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
          const SizedBox(height: 20),
          Text(
            'Carregando histórico...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState(bool isSmallScreen, bool isTablet) {
    final isEmpty = _searchQuery.value.isEmpty;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 20.0 : isTablet ? 40.0 : 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmpty ? Icons.auto_awesome_outlined : Icons.search_off,
                size: isTablet ? 80 : isSmallScreen ? 60 : 70,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              isEmpty
                  ? 'Nenhum mapa astral encontrado'
                  : 'Nenhum resultado para "${_searchQuery.value}"',
              style: TextStyle(
                fontSize: isTablet ? 24 : isSmallScreen ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              isEmpty
                  ? 'Gere seu primeiro mapa astral para começar sua jornada espiritual e descobrir os segredos das estrelas.'
                  : 'Tente usar termos diferentes ou verifique a ortografia.',
              style: TextStyle(
                fontSize: isTablet ? 16 : isSmallScreen ? 14 : 15,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 40 : 32),
            SizedBox(
              width: isTablet ? 250 : double.infinity,
              height: isTablet ? 56 : 48,
              child: ElevatedButton.icon(
                onPressed: isEmpty
                    ? () => Get.back()
                    : () {
                  _searchController.clear();
                  _searchCharts('');
                },
                icon: Icon(
                  isEmpty ? Icons.add_circle_outline : Icons.clear_all,
                  size: isTablet ? 24 : 20,
                ),
                label: Text(
                  isEmpty ? 'Gerar Mapa Astral' : 'Limpar Busca',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  foregroundColor: const Color(0xFF392F5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildChartsList(bool isSmallScreen, bool isTablet) {
    return RefreshIndicator(
      onRefresh: _loadBirthCharts,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : isTablet ? 24.0 : 16.0),
        itemCount: _birthCharts.length,
        itemBuilder: (context, index) {
          final chart = _birthCharts[index];
          return _buildChartCard(chart, index, isSmallScreen, isTablet);
        },
      ),
    );
  }

  Widget _buildChartCard(
      Map<String, dynamic> chart,
      int index,
      bool isSmallScreen,
      bool isTablet,
      ) {
    final createdAt = chart['createdAt'] as DateTime;
    final isFavorite = chart['isFavorite'] as bool;
    final name = chart['name'] ?? 'Sem nome';
    final birthDate = chart['birthDate'] ?? '';

    // Detectar signo zodiacal
    String zodiacSign = '';
    if (birthDate.isNotEmpty) {
      try {
        final parsedDate = DateFormat('dd/MM/yyyy').parse(birthDate);
        zodiacSign = ZodiacUtils.getZodiacSignFromDate(parsedDate);
      } catch (e) {
        // Ignorar erro de parsing
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 20 : isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showChartDetails(chart),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 24.0 : isSmallScreen ? 16.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho com avatar do signo
                Row(
                  children: [
                    // Avatar do signo ou ícone padrão
                    if (zodiacSign.isNotEmpty)
                      ZodiacUtils.buildSignAvatar(
                        context: context,
                        sign: zodiacSign,
                        size: isTablet ? 60 : isSmallScreen ? 48 : 56,
                        highlight: true,
                      )
                    else
                      Container(
                        width: isTablet ? 60 : isSmallScreen ? 48 : 56,
                        height: isTablet ? 60 : isSmallScreen ? 48 : 56,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: isTablet ? 32 : isSmallScreen ? 24 : 28,
                        ),
                      ),

                    SizedBox(width: isTablet ? 20 : 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isFavorite)
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: isTablet ? 18 : 16,
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 8 : 6),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Colors.white.withOpacity(0.6),
                                size: isTablet ? 16 : 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                birthDate.isNotEmpty ? birthDate : 'Data não informada',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: isTablet ? 14 : isSmallScreen ? 12 : 13,
                                ),
                              ),
                              if (zodiacSign.isNotEmpty) ...[
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: isTablet ? 14 : isSmallScreen ? 12 : 13,
                                  ),
                                ),
                                Text(
                                  zodiacSign,
                                  style: TextStyle(
                                    color: ZodiacUtils.getSignColor(zodiacSign),
                                    fontSize: isTablet ? 14 : isSmallScreen ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: isTablet ? 12 : isSmallScreen ? 10 : 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Menu de ações
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'favorite':
                            await _toggleFavorite(chart['id'], isFavorite);
                            break;
                          case 'share':
                            _shareChart(chart);
                            break;
                          case 'delete':
                            _showDeleteConfirmation(chart);
                            break;
                        }
                      },
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.white.withOpacity(0.8),
                        size: isTablet ? 24 : 20,
                      ),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'favorite',
                          child: Row(
                            children: [
                              Icon(
                                isFavorite ? Icons.favorite_border : Icons.favorite,
                                size: 20,
                                color: isFavorite ? Colors.grey : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Text(isFavorite ? 'Remover favorito' : 'Favoritar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20, color: AppTheme.primaryColor),
                              SizedBox(width: 12),
                              Text('Compartilhar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Excluir', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: isTablet ? 20 : 16),

                // Divider com gradiente
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                SizedBox(height: isTablet ? 20 : 16),

                // Informações do mapa
                _buildChartInfo(chart, isSmallScreen, isTablet),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildChartInfo(Map<String, dynamic> chart, bool isSmallScreen, bool isTablet) {
    return Row(
      children: [
        // Local
        Expanded(
          child: _buildInfoChip(
            icon: Icons.location_on,
            label: 'Local',
            value: chart['birthPlace'] ?? 'Não informado',
            color: AppTheme.accentColor,
            isSmallScreen: isSmallScreen,
            isTablet: isTablet,
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        // Horário
        _buildInfoChip(
          icon: Icons.access_time,
          label: 'Horário',
          value: chart['birthTime'] ?? 'Não informado',
          color: AppTheme.successColor,
          isSmallScreen: isSmallScreen,
          isTablet: isTablet,
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isSmallScreen,
    required bool isTablet,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 8 : 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: isTablet ? 16 : isSmallScreen ? 12 : 14,
          ),
        ),
        SizedBox(width: isTablet ? 10 : 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: isTablet ? 12 : isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isTablet ? 14 : isSmallScreen ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => Get.back(),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text(
        'Novo Mapa',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    ).animate()
        .scale(delay: 1000.ms, duration: 300.ms, curve: Curves.elasticOut);
  }

  Widget _buildChartDetailsBottomSheet(Map<String, dynamic> chart) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF392F5A),
            Color(0xFF483D8B),
            Color(0xFF8C6BAE),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          // Partículas de fundo
          ...ZodiacUtils.buildStarParticles(context, 20, maxHeight: 300),

          Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailHeader(chart),
                      const SizedBox(height: 24),
                      _buildDetailSection(
                        'Informações Pessoais',
                        [
                          'Data: ${chart['birthDate'] ?? 'Não informado'}',
                          'Horário: ${chart['birthTime'] ?? 'Não informado'}',
                          'Local: ${chart['birthPlace'] ?? 'Não informado'}',
                          'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(chart['createdAt'] ?? DateTime.now())}',
                        ],
                      ),
                      const SizedBox(height: 24),
                      BirthChartInterpretation(
                        interpretation: chart['interpretation'] ?? '',
                        isSmallScreen: isSmallScreen,
                        isTablet: isTablet,
                      ),
                      const SizedBox(height: 24),
                      _buildActionButtons(chart),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(Map<String, dynamic> chart) {
    final name = chart['name'] ?? 'Mapa Astral';
    final birthDate = chart['birthDate'] ?? '';
    final isFavorite = chart['isFavorite'] ?? false;

    // Detectar signo zodiacal
    String zodiacSign = '';
    if (birthDate.isNotEmpty) {
      try {
        final parsedDate = DateFormat('dd/MM/yyyy').parse(birthDate);
        zodiacSign = ZodiacUtils.getZodiacSignFromDate(parsedDate);
      } catch (e) {
        // Ignorar erro de parsing
      }
    }

    return Row(
      children: [
        // Avatar do signo
        if (zodiacSign.isNotEmpty)
          ZodiacUtils.buildSignAvatar(
            context: context,
            sign: zodiacSign,
            size: 60,
            highlight: true,
          )
        else
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 30,
            ),
          ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFavorite)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                ],
              ),
              if (zodiacSign.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Signo Solar: ',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      zodiacSign,
                      style: TextStyle(
                        color: ZodiacUtils.getSignColor(zodiacSign),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInterpretationSection(String interpretation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Interpretação do Mapa Astral',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Text(
            interpretation.isNotEmpty
                ? interpretation
                : 'Interpretação não disponível para este mapa astral.',
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> chart) {
    final isFavorite = chart['isFavorite'] as bool;

    return Column(
      children: [
        // Primeira linha de botões
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _shareChart(chart),
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _toggleFavorite(chart['id'], isFavorite);
                  Get.back();
                },
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(isFavorite ? 'Favorito' : 'Favoritar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFavorite ? Colors.red : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Segunda linha - botão de deletar
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Get.back();
              _showDeleteConfirmation(chart);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Excluir Mapa'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> chart) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF392F5A),
                Color(0xFF483D8B),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Confirmar Exclusão',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tem certeza que deseja excluir o mapa astral de "${chart['name']}"?\n\nEsta ação não pode ser desfeita.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Get.back();
                          await _deleteBirthChart(chart['id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Excluir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}