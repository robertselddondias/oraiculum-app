import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedReadingDetailScreen extends StatefulWidget {
  const SavedReadingDetailScreen({Key? key}) : super(key: key);

  @override
  State<SavedReadingDetailScreen> createState() => _SavedReadingDetailScreenState();
}

class _SavedReadingDetailScreenState extends State<SavedReadingDetailScreen>
    with SingleTickerProviderStateMixin {
  final TarotController _controller = Get.find<TarotController>();

  // Estados locais
  final RxString _readingId = ''.obs;
  final Rx<Map<String, dynamic>> _readingData = Rx<Map<String, dynamic>>({});
  final RxBool _isLoading = true.obs;
  final RxMap<String, dynamic> _parsedInterpretation = <String, dynamic>{}.obs;
  final RxList<TarotCard> _cards = <TarotCard>[].obs;

  // Controle de animação para o fundo da tela
  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

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

    // Carregar os dados da leitura
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReadingData();
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _loadReadingData() async {
    _isLoading.value = true;

    try {
      // Obter o ID da leitura dos argumentos
      final args = Get.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('readingId')) {
        _readingId.value = args['readingId'] as String;
      } else {
        Get.snackbar(
          'Erro',
          'ID da leitura não fornecido',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back();
        return;
      }

      // Buscar os dados da leitura
      final readingData = await _controller.getReadingById(_readingId.value);
      if (readingData != null) {
        _readingData.value = readingData;

        // Analisar a interpretação
        _parseInterpretationData(readingData['interpretation'] as String? ?? '');

        // Carregar os dados das cartas
        await _loadCards(readingData);
      } else {
        Get.snackbar(
          'Erro',
          'Leitura não encontrada',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        Get.back();
      }
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível carregar os detalhes da leitura: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadCards(Map<String, dynamic> readingData) async {
    final cardIds = List<String>.from(readingData['cardIds'] ?? []);
    final loadedCards = <TarotCard>[];

    for (final cardId in cardIds) {
      final card = await _controller.getCardById(cardId);
      if (card != null) {
        loadedCards.add(card);
      }
    }

    _cards.value = loadedCards;
  }

  void _parseInterpretationData(String content) {
    try {
      // Tentar analisar o conteúdo como JSON
      final Map<String, dynamic> data = json.decode(content);
      _parsedInterpretation.value = data;
    } catch (e) {
      // Se falhar, usar o conteúdo como texto geral
      _parsedInterpretation.value = {
        'geral': {'title': 'Interpretação Geral', 'body': content},
      };
    }
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

  void _shareReading() {
    try {
      String shareText = 'Minha leitura de Tarô:\n\n';

      // Adicionar cartas
      shareText += '🃏 Cartas: ${_cards.map((card) => card.name).join(', ')}\n\n';

      // Adicionar interpretação resumida
      if (_parsedInterpretation.containsKey('geral')) {
        final generalText = _parsedInterpretation['geral']['body'] as String;
        final maxLength = generalText.length > 150 ? 150 : generalText.length;
        shareText += '✨ ${generalText.substring(0, maxLength)}...\n\n';
      }

      shareText += 'Descubra seu futuro com o app Astral Connect!';

      SharePlus.instance.share(
          ShareParams(text: shareText)
      );
    } catch (e) {
      Get.snackbar(
        'Erro ao compartilhar',
        'Não foi possível compartilhar sua leitura: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _toggleFavorite() async {
    try {
      final isFavorite = _readingData.value['isFavorite'] ?? false;
      await _controller.toggleFavoriteReading(_readingId.value);

      // Atualizar localmente
      final updatedData = Map<String, dynamic>.from(_readingData.value);
      updatedData['isFavorite'] = !isFavorite;
      _readingData.value = updatedData;

      Get.snackbar(
        'Sucesso',
        isFavorite ? 'Removido dos favoritos' : 'Adicionado aos favoritos',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar os favoritos: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obter informações sobre o tamanho da tela
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final padding = isSmallScreen ? 12.0 : isTablet ? 24.0 : 16.0;

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
          child: Obx(() {
            if (_isLoading.value) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            final reading = _readingData.value;
            final isFavorite = reading['isFavorite'] ?? false;
            final createdAt = _formatDate(reading['createdAt']);

            return Column(
              children: [
                _buildAppBar(isSmallScreen, isTablet, isFavorite),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(padding),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(createdAt, isSmallScreen, isTablet),
                        SizedBox(height: isTablet ? 32.0 : 24.0),
                        _buildCardsGallery(isSmallScreen, isTablet),
                        SizedBox(height: isTablet ? 32.0 : 24.0),
                        _buildInterpretation(isSmallScreen, isTablet),
                        SizedBox(height: isTablet ? 32.0 : 24.0),
                        _buildActions(isSmallScreen, isTablet),
                        SizedBox(height: isTablet ? 32.0 : 24.0),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen, bool isTablet, bool isFavorite) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : isTablet ? 24.0 : 20.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button - Fix the navigation issue
          IconButton(
            // Instead of Get.back(), use Navigator.of(context).pop()
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            splashRadius: 24,
          ),

          // Título centralizado
          Expanded(
            child: Text(
              'Detalhes da Leitura',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 20.0 : isTablet ? 24.0 : 22.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Botão de favorito
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.amber : Colors.white,
              size: isTablet ? 28.0 : 24.0,
            ),
            splashRadius: 24,
            tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildHeader(String createdAt, bool isSmallScreen, bool isTablet) {
    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;
    final subtitleSize = isTablet ? 16.0 : isSmallScreen ? 12.0 : 14.0;

    return Card(
      elevation: 4,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: Colors.white,
                  size: isTablet ? 24.0 : 20.0,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data da Leitura',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: subtitleSize,
                      ),
                    ),
                    Text(
                      createdAt,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildCardsGallery(bool isSmallScreen, bool isTablet) {
    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;
    final cardHeight = isTablet ? 300.0 : isSmallScreen ? 200.0 : 250.0;
    final cardWidth = cardHeight * 0.6;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cartas da Leitura',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isTablet ? 16.0 : 12.0),
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _cards.length,
            itemBuilder: (context, index) {
              final card = _cards[index];
              return _buildCardItem(card, cardWidth, cardHeight, isSmallScreen, isTablet, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(TarotCard card, double width, double height, bool isSmallScreen, bool isTablet, int index) {
    return Container(
      width: width,
      margin: EdgeInsets.only(right: isTablet ? 24.0 : 16.0),
      child: Column(
        children: [
          // Imagem da carta
          Container(
            height: height * 0.8,
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
              child: Image.network(
                card.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) {
                  return Container(
                    color: Colors.grey.shade700,
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white,
                      size: isTablet ? 48.0 : 32.0,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: isTablet ? 12.0 : 8.0),
          // Nome da carta
          Text(
            card.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 16.0 : 14.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Tipo da carta
          Text(
            card.suit,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isTablet ? 14.0 : 12.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 200 + (index * 100)),
      duration: const Duration(milliseconds: 400),
    ).slideX(
      begin: 0.2,
      end: 0,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildInterpretation(bool isSmallScreen, bool isTablet) {
    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;
    final sectionTitleSize = isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0;
    final textSize = isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Interpretação',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isTablet ? 16.0 : 12.0),

        // Mostrar seções estruturadas se houver, ou texto completo
        ..._parsedInterpretation.entries.map((entry) {
          // Pular se não for um mapa (para evitar mostrar a lista de números)
          if (entry.key == 'numeros_sorte' || !(entry.value is Map)) {
            return const SizedBox.shrink();
          }

          final section = entry.value as Map<String, dynamic>;
          final title = section['title'] as String? ?? entry.key.capitalize!;
          final body = section['body'] as String? ?? '';

          final color = _getSectionColor(entry.key);
          final icon = _getSectionIcon(entry.key);

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
            margin: EdgeInsets.only(bottom: isTablet ? 16.0 : 12.0),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: isTablet ? 24.0 : 20.0,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: sectionTitleSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 16.0 : 12.0),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: textSize,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 400),
          );
        }).toList(),

        // Se não há seções estruturadas, mostrar o texto completo
        if (_parsedInterpretation.isEmpty)
          Card(
            elevation: 4,
            color: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
              child: Text(
                _readingData.value['interpretation'] as String? ?? 'Sem interpretação disponível',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: textSize,
                  height: 1.5,
                ),
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 400),
          ),
      ],
    );
  }

  Color _getSectionColor(String sectionKey) {
    switch (sectionKey.toLowerCase()) {
      case 'geral':
        return const Color(0xFF6C63FF);
      case 'amor':
        return Colors.pinkAccent;
      case 'trabalho':
      case 'profissional':
        return Colors.blueAccent;
      case 'saude':
        return Colors.greenAccent;
      case 'conselho':
      case 'conselhos':
        return Colors.amberAccent;
      default:
        return Colors.purpleAccent;
    }
  }

  IconData _getSectionIcon(String sectionKey) {
    switch (sectionKey.toLowerCase()) {
      case 'geral':
        return Icons.auto_awesome;
      case 'amor':
        return Icons.favorite;
      case 'trabalho':
      case 'profissional':
        return Icons.work;
      case 'saude':
        return Icons.favorite_border;
      case 'conselho':
      case 'conselhos':
        return Icons.lightbulb_outline;
      default:
        return Icons.brightness_7;
    }
  }

  Widget _buildActions(bool isSmallScreen, bool isTablet) {
    final buttonHeight = isTablet ? 56.0 : isSmallScreen ? 48.0 : 52.0;
    final textSize = isTablet ? 16.0 : isSmallScreen ? 14.0 : 15.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botão Compartilhar
        SizedBox(
          height: buttonHeight,
          child: ElevatedButton.icon(
            onPressed: _shareReading,
            icon: Icon(
              Icons.share,
              size: isTablet ? 24.0 : 20.0,
            ),
            label: Text(
              'Compartilhar Leitura',
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
              ),
            ),
          ),
        ),
        SizedBox(height: isTablet ? 16.0 : 12.0),
        // Botão Nova Leitura
        SizedBox(
          height: buttonHeight,
          child: OutlinedButton.icon(
            onPressed: () {
              Get.offNamed(AppRoutes.tarotReading);
            },
            icon: Icon(
              Icons.add,
              size: isTablet ? 24.0 : 20.0,
            ),
            label: Text(
              'Nova Leitura',
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 16.0 : 12.0),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(
      delay: Duration(milliseconds: 500),
      duration: const Duration(milliseconds: 400),
    );
  }
}