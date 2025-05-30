import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/services/firebase_service.dart';

class BirthChartHistoryDialog {
  static Future<void> show({
    required BuildContext context,
    required HoroscopeController controller,
    required Function(Map<String, dynamic>) onChartSelected,
  }) async {
    final authController = Get.find<AuthController>();
    final firebaseService = Get.find<FirebaseService>();

    if (authController.currentUser.value == null) {
      Get.snackbar(
        'Erro',
        'Você precisa estar logado para ver o histórico',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Carregar histórico
    final userId = authController.currentUser.value!.uid;
    final snapshot = await firebaseService.firestore
        .collection('birth_charts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final birthCharts = snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': data['name'] ?? 'Sem nome',
        'birthDate': data['birthDate'] ?? '',
        'birthTime': data['birthTime'] ?? '',
        'birthPlace': data['birthPlace'] ?? '',
        'interpretation': data['interpretation'] ?? '',
        'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
        'paymentId': data['paymentId'] ?? '',
        'isFavorite': data['isFavorite'] ?? false,
      };
    }).toList();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BirthChartHistoryBottomSheet(
        birthCharts: birthCharts,
        onChartSelected: onChartSelected,
      ),
    );
  }
}

class _BirthChartHistoryBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> birthCharts;
  final Function(Map<String, dynamic>) onChartSelected;

  const _BirthChartHistoryBottomSheet({
    required this.birthCharts,
    required this.onChartSelected,
  });

  @override
  State<_BirthChartHistoryBottomSheet> createState() =>
      _BirthChartHistoryBottomSheetState();
}

class _BirthChartHistoryBottomSheetState
    extends State<_BirthChartHistoryBottomSheet> {
  final RxList<Map<String, dynamic>> _filteredCharts = <Map<String, dynamic>>[].obs;
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxBool _showFavoritesOnly = false.obs;

  @override
  void initState() {
    super.initState();
    _filteredCharts.value = widget.birthCharts;

    // Observar mudanças na busca
    ever(_searchQuery, (query) => _filterCharts());
    ever(_showFavoritesOnly, (favoritesOnly) => _filterCharts());
  }

  void _filterCharts() {
    final query = _searchQuery.value.toLowerCase();
    final favoritesOnly = _showFavoritesOnly.value;

    _filteredCharts.value = widget.birthCharts.where((chart) {
      final matchesSearch = query.isEmpty ||
          chart['name'].toString().toLowerCase().contains(query) ||
          chart['birthPlace'].toString().toLowerCase().contains(query) ||
          chart['birthDate'].toString().contains(query);

      final matchesFavorites = !favoritesOnly || chart['isFavorite'] == true;

      return matchesSearch && matchesFavorites;
    }).toList();
  }

  Future<void> _toggleFavorite(String chartId, bool currentFavorite) async {
    try {
      final firebaseService = Get.find<FirebaseService>();
      await firebaseService.firestore
          .collection('birth_charts')
          .doc(chartId)
          .update({'isFavorite': !currentFavorite});

      // Atualizar a lista local
      final chartIndex = widget.birthCharts.indexWhere((chart) => chart['id'] == chartId);
      if (chartIndex != -1) {
        widget.birthCharts[chartIndex]['isFavorite'] = !currentFavorite;
        _filterCharts(); // Refiltra para refletir a mudança
      }

      Get.snackbar(
        'Sucesso',
        !currentFavorite ? 'Adicionado aos favoritos' : 'Removido dos favoritos',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível atualizar favorito: $e');
    }
  }

  Future<void> _deleteChart(String chartId) async {
    try {
      final firebaseService = Get.find<FirebaseService>();
      await firebaseService.firestore
          .collection('birth_charts')
          .doc(chartId)
          .delete();

      // Remover da lista local
      widget.birthCharts.removeWhere((chart) => chart['id'] == chartId);
      _filterCharts();

      Get.snackbar(
        'Sucesso',
        'Mapa astral removido do histórico',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível remover o mapa astral: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      height: screenHeight * 0.85,
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 20.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Text(
                  'Histórico de Mapas Astrais',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Fechar',
                ),
              ],
            ),
          ),

          // Search and filters
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 20.0,
            ),
            child: Column(
              children: [
                // Search field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _searchQuery.value = value,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nome ou local...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                      suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                          ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _searchQuery.value = '';
                        },
                        icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.8)),
                      )
                          : const SizedBox.shrink()),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter toggle
                Row(
                  children: [
                    Obx(() => Container(
                      decoration: BoxDecoration(
                        color: _showFavoritesOnly.value
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showFavoritesOnly.value = !_showFavoritesOnly.value,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showFavoritesOnly.value ? Icons.favorite : Icons.favorite_border,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Apenas Favoritos',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                    const Spacer(),
                    Obx(() => Text(
                      '${_filteredCharts.length} ${_filteredCharts.length == 1 ? 'mapa' : 'mapas'}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Charts list with white background container
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16.0 : 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Obx(() {
                if (_filteredCharts.isEmpty) {
                  return _buildEmptyState(isSmallScreen);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredCharts.length,
                  itemBuilder: (context, index) {
                    final chart = _filteredCharts[index];
                    return _buildChartCard(chart, index, isSmallScreen);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF392F5A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _showFavoritesOnly.value
                    ? Icons.favorite_border
                    : Icons.search_off,
                size: isSmallScreen ? 60 : 80,
                color: const Color(0xFF392F5A).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _showFavoritesOnly.value
                  ? 'Nenhum favorito encontrado'
                  : widget.birthCharts.isEmpty
                  ? 'Nenhum mapa astral encontrado'
                  : 'Nenhum resultado para sua busca',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF392F5A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _showFavoritesOnly.value
                  ? 'Marque alguns mapas como favoritos para vê-los aqui'
                  : widget.birthCharts.isEmpty
                  ? 'Gere seu primeiro mapa astral para começar'
                  : 'Tente usar termos diferentes na busca',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.birthCharts.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Gerar Mapa Astral'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF392F5A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20 : 24,
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(Map<String, dynamic> chart, int index, bool isSmallScreen) {
    final createdAt = chart['createdAt'] as DateTime;
    final isFavorite = chart['isFavorite'] as bool;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Card(
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
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            border: Border.all(
              color: const Color(0xFF392F5A).withOpacity(0.1),
            ),
          ),
          child: InkWell(
            onTap: () {
              Navigator.of(context).pop();
              widget.onChartSelected(chart);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF392F5A), Color(0xFF483D8B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF392F5A).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chart['name'] ?? 'Sem nome',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 15 : 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF392F5A),
                                    ),
                                  ),
                                ),
                                if (isFavorite)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.favorite,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM/yyyy \'às\' HH:mm').format(createdAt),
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'favorite':
                              await _toggleFavorite(chart['id'], isFavorite);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(chart);
                              break;
                          }
                        },
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey.shade600,
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(
                                  isFavorite ? Icons.favorite_border : Icons.favorite,
                                  size: 18,
                                  color: isFavorite ? Colors.grey : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(isFavorite ? 'Remover favorito' : 'Favoritar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF392F5A).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF392F5A).withOpacity(0.1),
                      ),
                    ),
                    child: _buildChartInfo(chart, isSmallScreen),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildChartInfo(Map<String, dynamic> chart, bool isSmallScreen) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.calendar_today,
          chart['birthDate'] ?? 'Não informado',
          isSmallScreen,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.access_time,
          chart['birthTime'] ?? 'Não informado',
          isSmallScreen,
        ),
        const SizedBox(height: 4),
        _buildInfoRow(
          Icons.location_on,
          chart['birthPlace'] ?? 'Não informado',
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String value, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF483D8B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: isSmallScreen ? 14 : 16,
              color: const Color(0xFF483D8B),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> chart) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o mapa astral de "${chart['name']}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _deleteChart(chart['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}