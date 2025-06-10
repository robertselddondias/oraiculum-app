import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:oraculum/utils/zodiac_utils.dart';
import 'package:oraculum/screens/tarot/widgets/mystic_welcome_dialog.dart';
import 'package:share_plus/share_plus.dart';

class TarotReadingScreen extends StatefulWidget {
  const TarotReadingScreen({super.key});

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> with TickerProviderStateMixin {
  final TarotController _controller = Get.find<TarotController>();

  // Controladores para animações de virar cartas
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;

  // Controlador para animação do gradiente de fundo
  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  // Estados das cartas
  final RxList<bool> _cardRevealed = [false, false, false].obs;
  final RxBool _allCardsRevealed = false.obs;
  final RxBool _readingPerformed = false.obs;
  final RxMap<String, dynamic> _parsedInterpretation = <String, dynamic>{}.obs;
  final RxBool _isCardDetailsVisible = false.obs;
  final Rx<TarotCard?> _selectedCardForDetails = Rx<TarotCard?>(null);

  // Controle do diálogo místico
  final RxBool _hasShownMysticDialog = false.obs;
  final RxBool _isReadyToStart = false.obs;

  @override
  void initState() {
    super.initState();

    // Inicializar controlador de animação do gradiente
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

    // Inicializar controladores de animação para as cartas
    _flipControllers = List.generate(
      3,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      ),
    );

    _flipAnimations = _flipControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutBack),
      );
    }).toList();

    // Aguardar o build inicial e mostrar o diálogo místico
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showMysticWelcomeDialog();
    });

    // Observar mudanças no estado das cartas e na interpretação
    ever(_cardRevealed, (_) {
      _allCardsRevealed.value = !_cardRevealed.contains(false);
    });

    ever(_controller.interpretation, (interpretation) {
      if (interpretation.isNotEmpty) {
        _parseInterpretationData(interpretation);
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Mostrar o diálogo místico de boas-vindas
  void _showMysticWelcomeDialog() {
    if (!_hasShownMysticDialog.value) {
      _hasShownMysticDialog.value = true;

      Future.delayed(const Duration(milliseconds: 500), () {
        MysticWelcomeDialog.show(
          context,
          onContinue: () {
            _isReadyToStart.value = true;
            _loadRandomCards();

            // Efeito tátil quando o usuário está pronto para começar
            HapticFeedback.mediumImpact();
          },
        );
      });
    }
  }

  void _loadRandomCards() async {
    // Verificar se já temos cartas carregadas
    if (_controller.allCards.isEmpty) {
      await _controller.loadTarotCards();
    }

    // Limpar seleção anterior
    _controller.resetReading();

    // Selecionar três cartas aleatórias
    final randomCards = _controller.getRandomCards(3);

    // Adicionar às cartas selecionadas
    for (var card in randomCards) {
      _controller.selectedCards.add(card);
    }

    // Resetar estado das cartas
    _cardRevealed.value = [false, false, false];
    _readingPerformed.value = false;
    _allCardsRevealed.value = false;
    _isCardDetailsVisible.value = false;
    _selectedCardForDetails.value = null;
  }

  void _flipCard(int index) {
    if (!_cardRevealed[index]) {
      _flipControllers[index].forward();

      // Usar HapticFeedback para efeito tátil ao virar a carta
      HapticFeedback.mediumImpact();

      _cardRevealed[index] = true;
    } else {
      // Se a carta já foi revelada, mostrar detalhes ao clicar novamente
      _showCardDetails(_controller.selectedCards[index]);
    }
  }

  void _showCardDetails(TarotCard card) {
    _selectedCardForDetails.value = card;
    _isCardDetailsVisible.value = true;

    // Feedback tátil ao abrir detalhes
    HapticFeedback.selectionClick();
  }

  void _hideCardDetails() {
    _isCardDetailsVisible.value = false;
    _selectedCardForDetails.value = null;
  }

  void _performReading() async {
    if (_allCardsRevealed.value && !_readingPerformed.value) {
      await _controller.performReading();
      _readingPerformed.value = true;

      // Efeito tátil quando a leitura estiver pronta
      HapticFeedback.heavyImpact();
    }
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

  void _shareReading() {
    try {
      String shareText = 'Minha leitura de Tarô:\n\n';

      // Adicionar cartas
      shareText += '🃏 Cartas: ${_controller.selectedCards.map((card) => card.name).join(', ')}\n\n';

      // Adicionar interpretação resumida
      if (_parsedInterpretation.containsKey('geral')) {
        final generalText = _parsedInterpretation['geral']['body'] as String;
        shareText += '✨ ${generalText.substring(0, min(150, generalText.length))}...\n\n';
      }

      shareText += 'Descubra seu futuro com o app Oraculum!';

      SharePlus.instance.share(
          ShareParams(text: shareText)
      );
    } catch (e) {
      Get.snackbar(
        'Erro ao compartilhar',
        'Não foi possível compartilhar sua leitura.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // Reiniciar experiência (mostrar diálogo místico novamente)
  void _restartMysticExperience() {
    _hasShownMysticDialog.value = false;
    _isReadyToStart.value = false;
    _showMysticWelcomeDialog();
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;
    final isLandscape = screenWidth > screenHeight;
    final padding = _getResponsivePadding(screenWidth);

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
            // Mostrar tela de carregamento inicial até que o diálogo seja mostrado
            if (!_isReadyToStart.value) {
              return _buildMysticLoadingState(isSmallScreen, isTablet);
            }

            if (_controller.isLoading.value) {
              return _buildLoadingState(isSmallScreen);
            }

            if (_controller.selectedCards.isEmpty) {
              return _buildEmptyState(isSmallScreen);
            }

            // Mostrar detalhes da carta, quando selecionada
            if (_isCardDetailsVisible.value && _selectedCardForDetails.value != null) {
              return _buildCardDetailsView(isSmallScreen, isTablet, padding);
            }

            return Column(
              children: [
                _buildAppBar(isSmallScreen, isTablet),
                // Adicionar widget de status das leituras diárias
                _buildDailyReadingStatus(isSmallScreen, isTablet),
                Expanded(
                  child: _readingPerformed.value
                      ? _buildReadingResult(isSmallScreen, isTablet, isLandscape, padding, screenHeight)
                      : _buildCardsDeck(isSmallScreen, isTablet, isLandscape, screenHeight),
                ),
                if (_allCardsRevealed.value && !_readingPerformed.value)
                  _buildPerformReadingButton(isSmallScreen, isTablet),
              ],
            );
          }),
        ),
      ),
    );
  }

  // Função para obter padding responsivo
  double _getResponsivePadding(double screenWidth) {
    if (screenWidth < 360) return 12.0;
    if (screenWidth >= 600) return 24.0;
    return 16.0;
  }

  // Função para obter tamanhos de fonte responsivos
  Map<String, double> _getResponsiveFontSizes(bool isSmallScreen, bool isTablet) {
    return {
      'title': isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0,
      'subtitle': isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0,
      'body': isTablet ? 16.0 : isSmallScreen ? 14.0 : 15.0,
      'caption': isTablet ? 14.0 : isSmallScreen ? 12.0 : 13.0,
    };
  }

  Widget _buildMysticLoadingState(bool isSmallScreen, bool isTablet) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _getResponsivePadding(MediaQuery.of(context).size.width)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ícone místico com animação de rotação
            AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _backgroundController.value * 2 * pi,
                  child: Container(
                    width: isTablet ? 100 : isSmallScreen ? 60 : 80,
                    height: isTablet ? 100 : isSmallScreen ? 60 : 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C63FF).withOpacity(0.3),
                          const Color(0xFF8E78FF).withOpacity(0.7),
                          const Color(0xFFFF9D8A).withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: isTablet ? 50 : isSmallScreen ? 30 : 40,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              '🌟 Preparando o Portal dos Arcanos...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: fontSizes['subtitle']!,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'O universo está alinhando as energias para você',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: fontSizes['body']!,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildDailyReadingStatus(bool isSmallScreen, bool isTablet) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);
    final padding = _getResponsivePadding(MediaQuery.of(context).size.width);

    return Obx(() {
      final hasFreeReading = _controller.hasFreeReadingToday.value;
      final readingsUsed = _controller.dailyReadingsUsed.value;

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: 8.0,
        ),
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
          border: Border.all(
            color: hasFreeReading ? Colors.green.withOpacity(0.5) : Colors.orange.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFreeReading ? Icons.casino : Icons.account_balance_wallet,
              color: hasFreeReading ? Colors.green : Colors.orange,
              size: isTablet ? 28 : isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: isTablet ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFreeReading ? 'Leitura Gratuita Disponível' : 'Leitura Gratuita Usada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSizes['body']!,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 6 : 4),
                  Text(
                    hasFreeReading
                        ? 'Você pode fazer 1 leitura gratuita hoje'
                        : 'Leituras extras custam ${_controller.additionalReadingCost.toStringAsFixed(0)} créditos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: fontSizes['caption']!,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasFreeReading)
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 12 : 8,
                    vertical: isTablet ? 6 : 4
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                ),
                child: Text(
                  'Usadas: $readingsUsed',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: fontSizes['caption']! - 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
    });
  }

  Widget _buildAppBar(bool isSmallScreen, bool isTablet) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);
    final padding = _getResponsivePadding(MediaQuery.of(context).size.width);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão de voltar
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: isTablet ? 28 : 24,
            ),
            splashRadius: isTablet ? 28 : 24,
          ),

          // Título centralizado
          Expanded(
            child: Text(
              'Leitura de Tarô',
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSizes['title']!,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Linha de ações (botões)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botão para histórico
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.savedReadingsList),
                icon: Icon(
                  Icons.history,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
                splashRadius: isTablet ? 28 : 24,
                tooltip: 'Minhas Leituras',
              ),
              // Botão de atualizar/nova leitura
              IconButton(
                onPressed: _loadRandomCards,
                icon: Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
                splashRadius: isTablet ? 28 : 24,
                tooltip: 'Nova leitura',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: isSmallScreen ? 2 : 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Preparando as cartas...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: fontSizes['body']!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, false);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view,
            size: isSmallScreen ? 50 : 60,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando cartas de tarô...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: fontSizes['body']!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsDeck(bool isSmallScreen, bool isTablet, bool isLandscape, double screenHeight) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);
    final padding = _getResponsivePadding(MediaQuery.of(context).size.width);
    final cardScale = isTablet ? 1.3 : min(screenHeight / 800, 1.2);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Partículas/estrelas para o fundo
        ...ZodiacUtils.buildStarParticles(context, isTablet ? 30 : 20),

        // Conteúdo principal
        Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instrução para o usuário
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16,
                    vertical: isTablet ? 14 : 10
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
                ),
                child: Text(
                  _allCardsRevealed.value
                      ? 'Toque nas cartas para ver detalhes'
                      : 'Toque nas cartas para revelá-las',
                  style: TextStyle(
                    fontSize: fontSizes['subtitle']!,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2, end: 0),

              SizedBox(height: isLandscape ? screenHeight * 0.08 : screenHeight * 0.05),

              // Cartas de tarô
              Flexible(
                child: SizedBox(
                  height: isLandscape
                      ? screenHeight * 0.6 * cardScale
                      : screenHeight * 0.45 * cardScale,
                  child: isLandscape
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      return _buildTarotCard(
                        index,
                        isSmallScreen,
                        isTablet,
                        delay: Duration(milliseconds: 300 + (index * 200)),
                      );
                    }),
                  )
                      : Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      return _buildTarotCard(
                        index,
                        isSmallScreen,
                        isTablet,
                        delay: Duration(milliseconds: 300 + (index * 200)),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTarotCard(int index, bool isSmallScreen, bool isTablet, {Duration? delay}) {
    final cardWidth = isTablet ? 140.0 : isSmallScreen ? 80.0 : 100.0;
    final cardHeight = cardWidth * 1.8;

    return AnimatedBuilder(
      animation: _flipAnimations[index],
      builder: (context, child) {
        final value = _flipAnimations[index].value;
        final isRevealed = value >= 0.5;

        return GestureDetector(
          onTap: () => _flipCard(index),
          child: Container(
            margin: EdgeInsets.all(isTablet ? 12 : isSmallScreen ? 6 : 8),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(pi * value),
              child: Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: isTablet ? 15 : 10,
                      spreadRadius: isTablet ? 3 : 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: isRevealed
                    ? _buildCardFront(index, cardWidth, cardHeight, isTablet)
                    : _buildCardBack(cardWidth, cardHeight, isTablet),
              ),
            ),
          ),
        );
      },
    ).animate(target: delay != null ? 1 : 0).fadeIn(
      delay: delay ?? Duration.zero,
      duration: const Duration(milliseconds: 600),
    ).scaleXY(
      begin: 0.7,
      end: 1.0,
      delay: delay ?? Duration.zero,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildCardFront(int index, double width, double height, bool isTablet) {
    final card = _controller.selectedCards[index];

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        child: Stack(
          children: [
            // Imagem da carta
            Positioned.fill(
              child: Image.network(
                card.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade700,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade700,
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Gradiente para melhorar a legibilidade do texto
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.7, 1.0],
                ),
              ),
            ),

            // Nome da carta
            Positioned(
              bottom: isTablet ? 16 : 12,
              left: isTablet ? 16 : 12,
              right: isTablet ? 16 : 12,
              child: Text(
                card.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 16 : 14,
                  shadows: const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 5,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Indicador para informar que o usuário pode clicar para ver detalhes
            if (_cardRevealed[index])
              Positioned(
                top: isTablet ? 12 : 10,
                right: isTablet ? 12 : 10,
                child: Container(
                  padding: EdgeInsets.all(isTablet ? 6 : 5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: isTablet ? 18 : 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(double width, double height, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A3988), Color(0xFF704A9C)],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Padrão decorativo
          CustomPaint(
            painter: TarotBackPatternPainter(),
          ),

          // Sobreposição central
          Center(
            child: Container(
              width: width * 0.7,
              height: width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white.withOpacity(0.8),
                  size: width * 0.35,
                ),
              ),
            ),
          ),

          // Borda luminosa animada
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    border: Border.all(
                      color: Colors.white.withOpacity(
                        0.2 + (0.2 * sin(_backgroundController.value * 2 * pi)),
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetailsView(bool isSmallScreen, bool isTablet, double padding) {
    final card = _selectedCardForDetails.value!;
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);

    return Stack(
      children: [
        // Partículas/estrelas para o fundo
        ...ZodiacUtils.buildStarParticles(context, isTablet ? 40 : 30),

        // Content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App bar
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _hideCardDetails,
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                      splashRadius: isTablet ? 28 : 24,
                    ),
                    Expanded(
                      child: Text(
                        card.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizes['title']!,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _hideCardDetails,
                      icon: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: isTablet ? 28 : 24,
                      ),
                      splashRadius: isTablet ? 28 : 24,
                    ),
                  ],
                ),
              ),

              // Card image
              Center(
                child: Container(
                  height: isTablet ? 400 : isSmallScreen ? 250 : 320,
                  width: isTablet ? 250 : isSmallScreen ? 150 : 200,
                  margin: EdgeInsets.symmetric(vertical: isTablet ? 20 : 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: isTablet ? 20 : 15,
                        spreadRadius: isTablet ? 3 : 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    child: Image.network(
                      card.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.black26,
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                              strokeWidth: isTablet ? 3 : 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) {
                        return Container(
                          color: Colors.black26,
                          child: Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: isTablet ? 60 : 50,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.0, 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
              ),

              // Info card
              Card(
                elevation: isTablet ? 6 : 4,
                color: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isTablet ? 24 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações básicas
                      _buildInfoRow(
                        icon: Icons.style,
                        title: 'Arcano',
                        value: card.suit,
                        isTablet: isTablet,
                        fontSizes: fontSizes,
                      ),
                      SizedBox(height: isTablet ? 20 : 16),
                      _buildInfoRow(
                        icon: Icons.format_list_numbered,
                        title: 'Número',
                        value: card.number.toString(),
                        isTablet: isTablet,
                        fontSizes: fontSizes,
                      ),

                      Divider(
                        height: isTablet ? 40 : 32,
                        color: Colors.white24,
                      ),

                      // Significado Upright
                      _buildMeaningSection(
                        title: 'Significado',
                        content: card.uprightMeaning,
                        icon: Icons.arrow_upward,
                        color: Colors.green,
                        isTablet: isTablet,
                        fontSizes: fontSizes,
                      ),

                      SizedBox(height: isTablet ? 28 : 24),

                      // Significado Reversed
                      _buildMeaningSection(
                        title: 'Significado Invertido',
                        content: card.reversedMeaning,
                        icon: Icons.arrow_downward,
                        color: Colors.redAccent,
                        isTablet: isTablet,
                        fontSizes: fontSizes,
                      ),

                      SizedBox(height: isTablet ? 20 : 16),

                      // Palavras-chave
                      Text(
                        'Palavras-chave:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSizes['body']!,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Wrap(
                        spacing: isTablet ? 10 : 8,
                        runSpacing: isTablet ? 10 : 8,
                        children: card.keywords.map((keyword) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12,
                              vertical: isTablet ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              keyword,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSizes['caption']!,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
              ),

              SizedBox(height: isTablet ? 32 : 24),

              // Botão para voltar
              SizedBox(
                width: double.infinity,
                height: isTablet ? 56 : 48,
                child: ElevatedButton.icon(
                  onPressed: _hideCardDetails,
                  icon: Icon(
                      Icons.arrow_back,
                      size: isTablet ? 24 : 20
                  ),
                  label: Text(
                      'Voltar para a Leitura',
                      style: TextStyle(fontSize: fontSizes['body']!)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    ),
                  ),
                ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 300),
              ),

              SizedBox(height: isTablet ? 40 : 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isTablet,
    required Map<String, double> fontSizes,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 10 : 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white70,
            size: isTablet ? 22 : 18,
          ),
        ),
        SizedBox(width: isTablet ? 20 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: fontSizes['caption']!,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSizes['body']!,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeaningSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isTablet,
    required Map<String, double> fontSizes,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: isTablet ? 22 : 18,
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: fontSizes['body']!,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 12 : 8),
        Text(
          content,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSizes['caption']! + 1,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformReadingButton(bool isSmallScreen, bool isTablet) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);
    final padding = _getResponsivePadding(MediaQuery.of(context).size.width);

    return Obx(() {
      final hasFreeReading = _controller.hasFreeReadingToday.value;
      final canAffordPaid = _controller.canPerformPaidReading();

      // Determinar texto e cor do botão
      String buttonText;
      Color buttonColor;
      IconData buttonIcon;

      if (hasFreeReading) {
        buttonText = 'Interpretar Cartas - Grátis';
        buttonColor = const Color(0xFF6C63FF);
        buttonIcon = Icons.psychology;
      } else if (canAffordPaid) {
        buttonText = 'Interpretar Cartas - ${_controller.additionalReadingCost.toStringAsFixed(0)} Créditos';
        buttonColor = Colors.orange;
        buttonIcon = Icons.account_balance_wallet;
      } else {
        buttonText = 'Créditos Insuficientes';
        buttonColor = Colors.grey;
        buttonIcon = Icons.block;
      }

      return Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          children: [
            // Botão principal
            Container(
              width: double.infinity,
              height: isTablet ? 56 : 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: (hasFreeReading || canAffordPaid) ? _performReading : null,
                icon: Icon(buttonIcon, size: isTablet ? 24 : 20),
                label: Text(
                    buttonText,
                    style: TextStyle(fontSize: fontSizes['body']!)
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // Informação adicional se não tiver créditos
            if (!hasFreeReading && !canAffordPaid) ...[
              SizedBox(height: isTablet ? 16 : 12),
              TextButton.icon(
                onPressed: () => Get.toNamed('/payment-methods'),
                icon: Icon(
                    Icons.add_card,
                    size: isTablet ? 24 : 20
                ),
                label: Text(
                    'Adicionar Créditos',
                    style: TextStyle(fontSize: fontSizes['body']!)
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ).animate().fadeIn(
        duration: const Duration(milliseconds: 600),
      ).scaleXY(
        begin: 0.95,
        end: 1.0,
        duration: const Duration(milliseconds: 600),
      );
    });
  }

  Widget _buildReadingResult(bool isSmallScreen, bool isTablet, bool isLandscape, double padding, double screenHeight) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);

    return Stack(
      children: [
        // Partículas/estrelas para o fundo
        ...ZodiacUtils.buildStarParticles(context, isTablet ? 40 : 30),

        // Conteúdo principal
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar as cartas selecionadas em miniatura
              _buildCardsMiniGallery(isSmallScreen, isTablet),

              SizedBox(height: isTablet ? screenHeight * 0.04 : screenHeight * 0.03),

              // Título da interpretação com decoração
              Container(
                margin: EdgeInsets.only(bottom: isTablet ? 24 : 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Título principal
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Sua Interpretação',
                        style: TextStyle(
                          fontSize: fontSizes['title']!,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Linha decorativa
                    Positioned(
                      left: 8,
                      bottom: isTablet ? -10 : -8,
                      child: Container(
                        width: isTablet ? 80 : 60,
                        height: isTablet ? 4 : 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

              // Interpretação - seções com base no JSON
              if (_parsedInterpretation.containsKey('geral'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['geral']['title'] ?? 'Interpretação Geral',
                  content: _parsedInterpretation['geral']['body'] ?? '',
                  icon: Icons.auto_awesome,
                  color: const Color(0xFF6C63FF),
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                  delay: 400,
                ),

              if (_parsedInterpretation.containsKey('amor'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['amor']['title'] ?? 'Amor',
                  content: _parsedInterpretation['amor']['body'] ?? '',
                  icon: Icons.favorite,
                  color: Colors.pinkAccent,
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                  delay: 600,
                ),

              if (_parsedInterpretation.containsKey('trabalho'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['trabalho']['title'] ?? 'Trabalho',
                  content: _parsedInterpretation['trabalho']['body'] ?? '',
                  icon: Icons.work,
                  color: Colors.blueAccent,
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                  delay: 800,
                ),

              if (_parsedInterpretation.containsKey('saude'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['saude']['title'] ?? 'Saúde',
                  content: _parsedInterpretation['saude']['body'] ?? '',
                  icon: Icons.favorite_border,
                  color: Colors.greenAccent,
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                  delay: 1000,
                ),

              if (_parsedInterpretation.containsKey('conselho'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['conselho']['title'] ?? 'Conselho',
                  content: _parsedInterpretation['conselho']['body'] ?? '',
                  icon: Icons.lightbulb_outline,
                  color: Colors.amberAccent,
                  isSmallScreen: isSmallScreen,
                  isTablet: isTablet,
                  delay: 1200,
                ),

              // Se não houver nenhuma seção ou apenas a geral, mostrar todo o texto
              if (_parsedInterpretation.isEmpty || (_parsedInterpretation.length == 1 && _parsedInterpretation.containsKey('geral')))
                Card(
                  elevation: isTablet ? 6 : 4,
                  color: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 24 : 20),
                    child: Text(
                      _controller.interpretation.value,
                      style: TextStyle(
                        fontSize: fontSizes['body']!,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

              SizedBox(height: isTablet ? screenHeight * 0.05 : screenHeight * 0.04),

              // Botões de ação
              _buildActionButtons(isSmallScreen, isTablet),

              // Espaçamento final
              SizedBox(height: isTablet ? screenHeight * 0.04 : screenHeight * 0.03),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardsMiniGallery(bool isSmallScreen, bool isTablet) {
    final cardSize = isTablet ? 100.0 : isSmallScreen ? 70.0 : 80.0;
    final cardHeight = cardSize * 1.5;

    return SizedBox(
      height: cardHeight + 40, // Espaço extra para o texto
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _controller.selectedCards.length,
        itemBuilder: (context, index) {
          final card = _controller.selectedCards[index];
          return GestureDetector(
            onTap: () => _showCardDetails(card),
            child: Container(
              width: cardSize + 20,
              margin: EdgeInsets.only(right: isTablet ? 20 : 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: cardHeight,
                        width: cardSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: isTablet ? 12 : 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                          child: Image.network(
                            card.imageUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade700,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Indicador para informar que o usuário pode clicar para ver detalhes
                      Positioned(
                        top: isTablet ? 8 : 5,
                        right: isTablet ? 8 : 5,
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 6 : 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                          ),
                          child: Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: isTablet ? 16 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 8 : 6),
                  Text(
                    card.name,
                    style: TextStyle(
                      fontSize: isTablet ? 13 : 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 200 * index),
            duration: const Duration(milliseconds: 400),
          ).slideX(
            begin: 0.2,
            end: 0,
            duration: const Duration(milliseconds: 400),
          );
        },
      ),
    );
  }

  Widget _buildInterpretationSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
    required bool isTablet,
    int delay = 0,
  }) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 28 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 12 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isTablet ? 28 : isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: fontSizes['subtitle']!,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Card(
            elevation: isTablet ? 6 : 4,
            color: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              side: BorderSide(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: fontSizes['body']!,
                  height: 1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: delay),
      duration: const Duration(milliseconds: 500),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildActionButtons(bool isSmallScreen, bool isTablet) {
    final fontSizes = _getResponsiveFontSizes(isSmallScreen, isTablet);

    return Column(
      children: [
        // Botões primários em linha
        Row(
          children: [
            // Botão Nova Leitura
            Expanded(
              child: _buildActionButton(
                icon: Icons.refresh,
                label: 'Nova Leitura',
                color: Colors.white,
                textColor: const Color(0xFF392F5A),
                onPressed: _loadRandomCards,
                isPrimary: false,
                isSmallScreen: isSmallScreen,
                isTablet: isTablet,
                fontSizes: fontSizes,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 20 : 16),
        // Botão Compartilhar (largura total)
        _buildActionButton(
          icon: Icons.share,
          label: 'Compartilhar Leitura',
          color: Colors.transparent,
          textColor: Colors.white,
          onPressed: _shareReading,
          isPrimary: false,
          isOutlined: true,
          isSmallScreen: isSmallScreen,
          isTablet: isTablet,
          isFullWidth: true,
          fontSizes: fontSizes,
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 1300),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isSmallScreen,
    required bool isTablet,
    required Map<String, double> fontSizes,
    bool isOutlined = false,
    bool isFullWidth = false,
  }) {
    final buttonHeight = isTablet ? 56.0 : isSmallScreen ? 44.0 : 50.0;
    final iconSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;
    final borderRadius = isTablet ? 20.0 : 16.0;

    return Container(
      width: isFullWidth ? double.infinity : null,
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPrimary ? [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: isOutlined
          ? OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(
          label,
          style: TextStyle(
            fontSize: fontSizes['body']!,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : isSmallScreen ? 12 : 14,
          ),
        ),
      )
          : ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        label: Text(
          label,
          style: TextStyle(
            fontSize: fontSizes['body']!,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isTablet ? 16 : isSmallScreen ? 12 : 14,
          ),
        ),
      ),
    );
  }
}

// Classe para pintar o fundo das cartas
class TarotBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Desenhar padrão geométrico
    final spacing = size.width / 8;

    // Desenhar estrela de seis pontas (símbolo esotérico)
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width * 0.3;

    // Primeiro triângulo
    final pathTriangle1 = Path();
    pathTriangle1.moveTo(centerX, centerY - radius);
    pathTriangle1.lineTo(centerX + radius * cos(pi/6), centerY + radius * sin(pi/6));
    pathTriangle1.lineTo(centerX - radius * cos(pi/6), centerY + radius * sin(pi/6));
    pathTriangle1.close();

    // Segundo triângulo
    final pathTriangle2 = Path();
    pathTriangle2.moveTo(centerX, centerY + radius);
    pathTriangle2.lineTo(centerX + radius * cos(pi/6), centerY - radius * sin(pi/6));
    pathTriangle2.lineTo(centerX - radius * cos(pi/6), centerY - radius * sin(pi/6));
    pathTriangle2.close();

    canvas.drawPath(pathTriangle1, paint);
    canvas.drawPath(pathTriangle2, paint);

    // Desenhar círculo ao redor da estrela
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 1.1,
      paint,
    );

    // Desenhar linhas nos cantos para efeito de textura
    for (var i = 1; i < 5; i++) {
      // Canto superior esquerdo
      canvas.drawLine(
        Offset(0, i * spacing / 2),
        Offset(i * spacing / 2, 0),
        paint,
      );

      // Canto superior direito
      canvas.drawLine(
        Offset(size.width, i * spacing / 2),
        Offset(size.width - i * spacing / 2, 0),
        paint,
      );

      // Canto inferior esquerdo
      canvas.drawLine(
        Offset(0, size.height - i * spacing / 2),
        Offset(i * spacing / 2, size.height),
        paint,
      );

      // Canto inferior direito
      canvas.drawLine(
        Offset(size.width, size.height - i * spacing / 2),
        Offset(size.width - i * spacing / 2, size.height),
        paint,
      );
    }

    // Desenhar símbolos lunares nos cantos
    final moonPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Desenhar lua nos quatro cantos
    _drawMoonSymbol(canvas, Offset(size.width * 0.15, size.height * 0.15), size.width * 0.06, moonPaint);
    _drawMoonSymbol(canvas, Offset(size.width * 0.85, size.height * 0.15), size.width * 0.06, moonPaint);
    _drawMoonSymbol(canvas, Offset(size.width * 0.15, size.height * 0.85), size.width * 0.06, moonPaint);
    _drawMoonSymbol(canvas, Offset(size.width * 0.85, size.height * 0.85), size.width * 0.06, moonPaint);
  }

  void _drawMoonSymbol(Canvas canvas, Offset center, double radius, Paint paint) {
    // Desenhar um círculo
    canvas.drawCircle(center, radius, paint);

    // Desenhar uma forma de lua crescente sobreposta
    final circlePath = Path()
      ..addOval(Rect.fromCircle(center: Offset(center.dx + radius * 0.3, center.dy), radius: radius * 0.9));

    // Usar o modo de composição para criar o efeito de lua crescente
    canvas.drawPath(
      circlePath,
      Paint()
        ..color = const Color(0xFF4A3988)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.clear,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}