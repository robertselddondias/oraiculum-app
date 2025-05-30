import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:share_plus/share_plus.dart';

class BirthChartHistoryScreen extends StatefulWidget {
  const BirthChartHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BirthChartHistoryScreen> createState() => _BirthChartHistoryScreenState();
}

class _BirthChartHistoryScreenState extends State<BirthChartHistoryScreen> {
  final HoroscopeController _controller = Get.find<HoroscopeController>();
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  final RxList<Map<String, dynamic>> _birthCharts = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _selectedChartId = ''.obs;

  @override
  void initState() {
    super.initState();
    _loadBirthCharts();
  }

  Future<void> _loadBirthCharts() async {
    if (_authController.currentUser.value == null) return;

    _isLoading.value = true;
    try {
      final userId = _authController.currentUser.value!.uid;
      final snapshot = await _firebaseService.firestore
          .collection('birth_charts')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      _birthCharts.value = snapshot.docs.map((doc) {
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
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar o histórico: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _deleteBirthChart(String chartId) async {
    try {
      await _firebaseService.firestore
          .collection('birth_charts')
          .doc(chartId)
          .delete();

      _birthCharts.removeWhere((chart) => chart['id'] == chartId);

      Get.snackbar(
        'Sucesso',
        'Mapa astral removido do histórico',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível remover o mapa astral: $e');
    }
  }

  Future<void> _toggleFavorite(String chartId, bool currentFavorite) async {
    try {
      await _firebaseService.firestore
          .collection('birth_charts')
          .doc(chartId)
          .update({'isFavorite': !currentFavorite});

      final chartIndex = _birthCharts.indexWhere((chart) => chart['id'] == chartId);
      if (chartIndex != -1) {
        _birthCharts[chartIndex]['isFavorite'] = !currentFavorite;
      }

      Get.snackbar(
        'Sucesso',
        !currentFavorite ? 'Adicionado aos favoritos' : 'Removido dos favoritos',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível atualizar favorito: $e');
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
    final text = '''
🌟 Meu Mapa Astral - ${chart['name']}

📅 Data: ${chart['birthDate']}
🕐 Horário: ${chart['birthTime']}
📍 Local: ${chart['birthPlace']}
📆 Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(chart['createdAt'])}

Descubra seu destino também no app Oraculum!
    '''.trim();

    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Mapas Astrais'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF392F5A),
                Color(0xFF483D8B),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBirthCharts,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Container(
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
        ),
        child: Obx(() {
          if (_isLoading.value) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Carregando histórico...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          if (_birthCharts.isEmpty) {
            return _buildEmptyState(isSmallScreen, isTablet);
          }

          return _buildChartsList(isSmallScreen, isTablet);
        }),
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen, bool isTablet) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: isSmallScreen ? 80 : 100,
              color: Colors.white.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum mapa astral encontrado',
              style: TextStyle(
                fontSize: isSmallScreen ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Gere seu primeiro mapa astral para começar seu histórico espiritual.',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Gerar Mapa Astral'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
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
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildChartsList(bool isSmallScreen, bool isTablet) {
    return RefreshIndicator(
      onRefresh: _loadBirthCharts,
      color: Colors.white,
      backgroundColor: const Color(0xFF392F5A),
      child: ListView.builder(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
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
      bool isTablet
      ) {
    final createdAt = chart['createdAt'] as DateTime;
    final isFavorite = chart['isFavorite'] as bool;

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      child: Card(
        elevation: 8,
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
          ),
          child: InkWell(
            onTap: () => _showChartDetails(chart),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF392F5A), Color(0xFF483D8B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 24,
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
                                      fontSize: isSmallScreen ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF392F5A),
                                    ),
                                  ),
                                ),
                                if (isFavorite)
                                  const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 12 : 14,
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
                            case 'share':
                              _shareChart(chart);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(chart);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'favorite',
                            child: Row(
                              children: [
                                Icon(
                                  isFavorite ? Icons.favorite_border : Icons.favorite,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(isFavorite ? 'Remover favorito' : 'Favoritar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                Icon(Icons.share, size: 20),
                                SizedBox(width: 8),
                                Text('Compartilhar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Excluir', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildChartInfo(chart, isSmallScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildChartInfo(Map<String, dynamic> chart, bool isSmallScreen) {
    return Column(
      children: [
        _buildInfoRow(
          Icons.calendar_today,
          'Data de Nascimento',
          chart['birthDate'] ?? 'Não informado',
          isSmallScreen,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.access_time,
          'Horário',
          chart['birthTime'] ?? 'Não informado',
          isSmallScreen,
        ),
        const SizedBox(height: 8),
        _buildInfoRow(
          Icons.location_on,
          'Local',
          chart['birthPlace'] ?? 'Não informado',
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value,
      bool isSmallScreen
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 16 : 18,
          color: const Color(0xFF483D8B),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartDetailsBottomSheet(Map<String, dynamic> chart) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chart['name'] ?? 'Mapa Astral',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF392F5A),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildDetailSection(
                    'Informações Pessoais',
                    [
                      'Data: ${chart['birthDate']}',
                      'Horário: ${chart['birthTime']}',
                      'Local: ${chart['birthPlace']}',
                      'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(chart['createdAt'])}',
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildInterpretationSection(chart['interpretation'] ?? ''),
                  const SizedBox(height: 24),
                  _buildActionButtons(chart),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF392F5A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: Color(0xFF483D8B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF392F5A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            interpretation.isNotEmpty
                ? interpretation
                : 'Interpretação não disponível',
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> chart) {
    final isFavorite = chart['isFavorite'] as bool;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareChart(chart),
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              await _toggleFavorite(chart['id'], isFavorite);
              Get.back();
            },
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            label: Text(isFavorite ? 'Favorito' : 'Favoritar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFavorite ? Colors.red : const Color(0xFF392F5A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
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
              await _deleteBirthChart(chart['id']);
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
}