import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:oraculum/utils/zodiac_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oraculum/config/routes.dart';

class SavedReadingsListScreen extends StatefulWidget {
  const SavedReadingsListScreen({Key? key}) : super(key: key);

  @override
  State<SavedReadingsListScreen> createState() => _SavedReadingsListScreenState();
}

class _SavedReadingsListScreenState extends State<SavedReadingsListScreen> with SingleTickerProviderStateMixin {
  final TarotController _controller = Get.find<TarotController>();

  // Animação para o fundo da tela
  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  // Controle de visualização
  final RxBool _showOnlyFavorites = false.obs;
  final RxString _searchQuery = ''.obs;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Configurar animação do fundo
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

    // Carregar as leituras salvas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadSavedReadings();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Filtrar as leituras com base na pesquisa e favoritos
  List<Map<String, dynamic>> _getFilteredReadings() {
    final allReadings = _controller.savedReadings;
    final query = _searchQuery.value.toLowerCase();

    return allReadings.where((reading) {
      // Filtrar por favoritos, se necessário
      if (_showOnlyFavorites.value && !(reading['isFavorite'] ?? false)) {
        return false;
      }

      // Não há pesquisa, mostrar tudo
      if (query.isEmpty) {
        return true;
      }

      // Tentar encontrar a consulta no campo de interpretação
      final interpretation = reading['interpretation'] ?? '';
      return interpretation.toLowerCase().contains(query);
    }).toList();
  }

  // Formatar data para exibição
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Data desconhecida';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }

    return 'Data inválida';
  }

  // Obter resumo da interpretação
  String _getReadingSummary(String interpretation, int maxLength) {
    try {
      // Tentar analisar como JSON
      final data = Map<String, dynamic>.from(json.decode(interpretation));
      if (data.containsKey('geral') && data['geral'] is Map && data['geral'].containsKey('body')) {
        final general = data['geral']['body'] as String;
        if (general.length <= maxLength) return general;
        return '${general.substring(0, maxLength)}...';
      }
    } catch (_) {
      // Se falhar, usar a própria interpretação
    }

    // Usar a interpretação direta
    if (interpretation.length <= maxLength) return interpretation;
    return '${interpretation.substring(0, maxLength)}...';
  }

  // Confirmar exclusão de leitura
  Future<void> _confirmDeleteReading(String readingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text(
            'Você tem certeza que deseja excluir esta leitura? Esta ação não pode ser desfeita.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteReading(readingId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;

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
          child: Column(
            children: [
              _buildAppBar(isSmallScreen),
              _buildSearchBar(padding),
              _buildFilterToggle(padding),
              Expanded(
                child: _buildReadingsList(isSmallScreen, padding),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.tarotReading),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add),
        tooltip: 'Nova Leitura',
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 20.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão de voltar
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            splashRadius: 24,
          ),

          // Título centralizado
          Text(
            'Minhas Leituras de Tarô',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20.0 : 22.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          // Botão de ajuda
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sobre Leituras Salvas'),
                  content: const Text(
                      'Aqui você encontra todas as suas leituras de tarô salvas. '
                          'Você pode filtrar por favoritos, pesquisar por palavras-chave e '
                          'visualizar os detalhes de cada leitura.\n\n'
                          'Toque em uma leitura para visualizá-la ou use o botão "+" para '
                          'criar uma nova leitura.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(
              Icons.help_outline,
              color: Colors.white,
            ),
            splashRadius: 24,
            tooltip: 'Ajuda',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSearchBar(double padding) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Pesquisar nas leituras...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            onPressed: () {
              _searchController.clear();
              _searchQuery.value = '';
            },
          )
              : null),
        ),
        style: const TextStyle(color: Colors.white),
        onChanged: (value) {
          _searchQuery.value = value;
        },
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 500.ms);
  }

  Widget _buildFilterToggle(double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Row(
        children: [
          const Text(
            'Somente favoritos',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() => Switch(
            value: _showOnlyFavorites.value,
            onChanged: (value) {
              _showOnlyFavorites.value = value;
            },
            activeColor: Colors.amber,
          )),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildReadingsList(bool isSmallScreen, double padding) {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        );
      }

      final readings = _getFilteredReadings();

      if (readings.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.builder(
        padding: EdgeInsets.all(padding),
        itemCount: readings.length,
        itemBuilder: (context, index) {
          final reading = readings[index];
          return _buildReadingCard(reading, isSmallScreen, index);
        },
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyFavorites.value ? Icons.favorite_border : Icons.menu_book,
            size: 80,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _showOnlyFavorites.value
                ? 'Nenhuma leitura favorita encontrada'
                : _searchQuery.value.isNotEmpty
                ? 'Nenhuma leitura encontrada para "${_searchQuery.value}"'
                : 'Você ainda não tem leituras salvas',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              if (_showOnlyFavorites.value || _searchQuery.value.isNotEmpty) {
                // Limpar filtros
                _showOnlyFavorites.value = false;
                _searchController.clear();
                _searchQuery.value = '';
              } else {
                // Ir para nova leitura
                Get.toNamed(AppRoutes.tarotReading);
              }
            },
            icon: Icon(
              _showOnlyFavorites.value || _searchQuery.value.isNotEmpty
                  ? Icons.filter_alt_off
                  : Icons.add,
            ),
            label: Text(
              _showOnlyFavorites.value || _searchQuery.value.isNotEmpty
                  ? 'Limpar Filtros'
                  : 'Nova Leitura',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildReadingCard(Map<String, dynamic> reading, bool isSmallScreen, int index) {
    final readingId = reading['id'] as String;
    final createdAt = _formatDate(reading['createdAt']);
    final isFavorite = reading['isFavorite'] ?? false;
    final interpretation = reading['interpretation'] as String? ?? '';
    final summary = _getReadingSummary(interpretation, 100);

    // Obter IDs das cartas da leitura
    final cardIds = List<String>.from(reading['cardIds'] ?? []);

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isFavorite
            ? const BorderSide(color: Colors.amber, width: 2)
            : BorderSide.none,
      ),
      color: Colors.black.withOpacity(0.3),
      child: InkWell(
        onTap: () {
          // Navegar para a tela de detalhes da leitura
          Get.toNamed(
            AppRoutes.savedReading,
            arguments: readingId,
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho com data e ações
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    createdAt,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      // Botão de favorito
                      IconButton(
                        onPressed: () => _controller.toggleFavoriteReading(readingId),
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.amber : Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                        tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
                      ),
                      const SizedBox(width: 16),
                      // Botão de excluir
                      IconButton(
                        onPressed: () => _confirmDeleteReading(readingId),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                        tooltip: 'Excluir leitura',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cartas da leitura
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: cardIds.length,
                  itemBuilder: (context, cardIndex) {
                    return FutureBuilder<TarotCard?>(
                      future: _controller.getCardById(cardIds[cardIndex]),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const SizedBox(
                            width: 50,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }

                        final card = snapshot.data;
                        if (card == null) {
                          return const SizedBox(width: 50);
                        }

                        return Container(
                          width: 50,
                          margin: const EdgeInsets.only(right: 8),
                          child: Column(
                            children: [
                              Container(
                                height: 60,
                                width: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    card.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) {
                                      return Container(
                                        color: Colors.grey.shade700,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                card.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Resumo da interpretação
              Text(
                'Interpretação:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Botão para ver detalhes
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.toNamed(
                      AppRoutes.savedReading,
                      arguments: readingId,
                    );
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Ver Detalhes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: isSmallScreen ? 8 : 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: const Duration(milliseconds: 400),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 300),
    );
  }
}