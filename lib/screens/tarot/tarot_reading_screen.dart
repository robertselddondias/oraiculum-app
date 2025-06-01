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
import 'package:oraculum/widgets/app_card_image.dart';
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
          child: Obx(() {
            // Mostrar tela de carregamento inicial até que o diálogo seja mostrado
            if (!_isReadyToStart.value) {
              return _buildMysticLoadingState();
            }

            if (_controller.isLoading.value) {
              return _buildLoadingState();
            }

            if (_controller.selectedCards.isEmpty) {
              return _buildEmptyState();
            }

            // Mostrar detalhes da carta, quando selecionada
            if (_isCardDetailsVisible.value && _selectedCardForDetails.value != null) {
              return _buildCardDetailsView(isSmallScreen, padding);
            }

            return Column(
              children: [
                _buildAppBar(isSmallScreen),
                // Adicionar widget de status das leituras diárias
                _buildDailyReadingStatus(isSmallScreen),
                Expanded(
                  child: _readingPerformed.value
                      ? _buildReadingResult(isSmallScreen, padding, screenHeight)
                      : _buildCardsDeck(isSmallScreen, screenHeight),
                ),
                if (_allCardsRevealed.value && !_readingPerformed.value)
                  _buildPerformReadingButton(isSmallScreen),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMysticLoadingState() {
    return Center(
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
                  width: 80,
                  height: 80,
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
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            '🌟 Preparando o Portal dos Arcanos...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'O universo está alinhando as energias para você',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildDailyReadingStatus(bool isSmallScreen) {
    return Obx(() {
      final hasFreeReading = _controller.hasFreeReadingToday.value;
      final readingsUsed = _controller.dailyReadingsUsed.value;

      return Container(
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 16.0 : 20.0,
          vertical: 8.0,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
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
              size: isSmallScreen ? 20 : 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasFreeReading ? 'Leitura Gratuita Disponível' : 'Leitura Gratuita Usada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasFreeReading
                        ? 'Você pode fazer 1 leitura gratuita hoje'
                        : 'Leituras extras custam ${_controller.additionalReadingCost.toStringAsFixed(0)} créditos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!hasFreeReading)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Usadas: $readingsUsed',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: isSmallScreen ? 10 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
    });
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
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            splashRadius: 24,
          ),

          // Título centralizado
          Text(
            'Leitura de Tarô',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmallScreen ? 20.0 : 22.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),

          // Linha de ações (botões)
          Row(
            children: [
              // Botão para reiniciar a experiência mística
              IconButton(
                onPressed: () => Get.toNamed(AppRoutes.savedReadingsList),
                icon: const Icon(
                  Icons.history,
                  color: Colors.white,
                ),
                splashRadius: 24,
                tooltip: 'Minhas Leituras',
              ),
              // Botão de atualizar/nova leitura
              IconButton(
                onPressed: _loadRandomCards,
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.white,
                ),
                splashRadius: 24,
                tooltip: 'Nova leitura',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            'Preparando as cartas...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view,
            size: 60,
            color: Colors.white.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando cartas de tarô...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsDeck(bool isSmallScreen, double screenHeight) {
    final instructionFontSize = isSmallScreen ? 16.0 : 18.0;
    final cardScale = min(screenHeight / 800, 1.2);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Partículas/estrelas para o fundo
        ...ZodiacUtils.buildStarParticles(context, 20),

        // Conteúdo principal
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Instrução para o usuário
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _allCardsRevealed.value
                      ? 'Toque nas cartas para ver detalhes'
                      : 'Toque nas cartas para revelá-las',
                  style: TextStyle(
                    fontSize: instructionFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.2, end: 0),

              SizedBox(height: screenHeight * 0.05),

              // Cartas de tarô
              SizedBox(
                height: screenHeight * 0.45 * cardScale,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(3, (index) {
                    return _buildTarotCard(
                      index,
                      isSmallScreen,
                      delay: Duration(milliseconds: 300 + (index * 200)),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTarotCard(int index, bool isSmallScreen, {Duration? delay}) {
    final cardWidth = isSmallScreen ? 90.0 : 110.0;
    final cardHeight = cardWidth * 1.8;

    return AnimatedBuilder(
      animation: _flipAnimations[index],
      builder: (context, child) {
        final value = _flipAnimations[index].value;
        final isRevealed = value >= 0.5;

        return GestureDetector(
          onTap: () => _flipCard(index),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(pi * value),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: isRevealed
                  ? _buildCardFront(index, cardWidth, cardHeight)
                  : _buildCardBack(cardWidth, cardHeight),
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

  Widget _buildCardFront(int index, double width, double height) {
    final card = _controller.selectedCards[index];

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Imagem da carta
            AppCardImage(imageUrl: card.imageUrl),

            // Gradiente para melhorar a legibilidade do texto
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
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
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                card.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 5,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Indicador para informar que o usuário pode clicar para ver detalhes
            if (_cardRevealed[index])
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack(double width, double height) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildCardDetailsView(bool isSmallScreen, double padding) {
    final card = _selectedCardForDetails.value!;

    return Stack(
      children: [
        // Partículas/estrelas para o fundo
        ...ZodiacUtils.buildStarParticles(context, 30),

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
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                      splashRadius: 24,
                    ),
                    Expanded(
                      child: Text(
                        card.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _hideCardDetails,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),

              // Card image
              Center(
                child: Container(
                  height: isSmallScreen ? 280 : 320,
                  width: isSmallScreen ? 170 : 200,
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
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
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stack) {
                        return Container(
                          color: Colors.black26,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 50,
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
                elevation: 4,
                color: Colors.black.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Informações básicas
                      _buildInfoRow(
                        icon: Icons.style,
                        title: 'Arcano',
                        value: card.suit,
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.format_list_numbered,
                        title: 'Número',
                        value: card.number.toString(),
                      ),

                      const Divider(
                        height: 32,
                        color: Colors.white24,
                      ),

                      // Significado Upright
                      _buildMeaningSection(
                        title: 'Significado',
                        content: card.uprightMeaning,
                        icon: Icons.arrow_upward,
                        color: Colors.green,
                      ),

                      const SizedBox(height: 24),

                      // Significado Reversed
                      _buildMeaningSection(
                        title: 'Significado Invertido',
                        content: card.reversedMeaning,
                        icon: Icons.arrow_downward,
                        color: Colors.redAccent,
                      ),

                      const SizedBox(height: 16),

                      // Palavras-chave
                      const Text(
                        'Palavras-chave:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: card.keywords.map((keyword) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white24,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              keyword,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
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

              const SizedBox(height: 24),

              // Botão para voltar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _hideCardDetails,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar para a Leitura'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ).animate().fadeIn(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 300),
              ),

              const SizedBox(height: 32),
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
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white70,
            size: 18,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformReadingButton(bool isSmallScreen) {
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
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          children: [
            // Botão principal
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
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
                icon: Icon(buttonIcon),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            // Informação adicional se não tiver créditos
            if (!hasFreeReading && !canAffordPaid) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Get.toNamed('/payment-methods'),
                icon: const Icon(Icons.add_card, size: 20),
                label: const Text('Adicionar Créditos'),
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

  Widget _buildReadingResult(bool isSmallScreen, double padding, double screenHeight) {
    final titleSize = isSmallScreen ? 18.0 : 22.0;

    return Stack(
      children: [
        // Partículas/estrelas para o fundo
        ...ZodiacUtils.buildStarParticles(context, 30),

        // Conteúdo principal
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mostrar as cartas selecionadas em miniatura
              _buildCardsMiniGallery(isSmallScreen),

              SizedBox(height: screenHeight * 0.03),

              // Título da interpretação com decoração
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Título principal
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Sua Interpretação',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    // Linha decorativa
                    Positioned(
                      left: 8,
                      bottom: -8,
                      child: Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(1.5),
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
                  delay: 400,
                ),

              if (_parsedInterpretation.containsKey('amor'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['amor']['title'] ?? 'Amor',
                  content: _parsedInterpretation['amor']['body'] ?? '',
                  icon: Icons.favorite,
                  color: Colors.pinkAccent,
                  isSmallScreen: isSmallScreen,
                  delay: 600,
                ),

              if (_parsedInterpretation.containsKey('trabalho'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['trabalho']['title'] ?? 'Trabalho',
                  content: _parsedInterpretation['trabalho']['body'] ?? '',
                  icon: Icons.work,
                  color: Colors.blueAccent,
                  isSmallScreen: isSmallScreen,
                  delay: 800,
                ),

              if (_parsedInterpretation.containsKey('saude'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['saude']['title'] ?? 'Saúde',
                  content: _parsedInterpretation['saude']['body'] ?? '',
                  icon: Icons.favorite_border,
                  color: Colors.greenAccent,
                  isSmallScreen: isSmallScreen,
                  delay: 1000,
                ),

              if (_parsedInterpretation.containsKey('conselho'))
                _buildInterpretationSection(
                  title: _parsedInterpretation['conselho']['title'] ?? 'Conselho',
                  content: _parsedInterpretation['conselho']['body'] ?? '',
                  icon: Icons.lightbulb_outline,
                  color: Colors.amberAccent,
                  isSmallScreen: isSmallScreen,
                  delay: 1200,
                ),

              // Se não houver nenhuma seção ou apenas a geral, mostrar todo o texto
              if (_parsedInterpretation.isEmpty || (_parsedInterpretation.length == 1 && _parsedInterpretation.containsKey('geral')))
                Card(
                  elevation: 4,
                  color: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _controller.interpretation.value,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

              SizedBox(height: screenHeight * 0.04),

              // Botões de ação
              _buildActionButtons(isSmallScreen),

              // Espaçamento final
              SizedBox(height: screenHeight * 0.03),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardsMiniGallery(bool isSmallScreen) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _controller.selectedCards.length,
        itemBuilder: (context, index) {
          final card = _controller.selectedCards[index];
          return GestureDetector(
            onTap: () => _showCardDetails(card),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 90,
                        width: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
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
                        top: 5,
                        right: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 11,
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
    int delay = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            color: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
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

  Widget _buildActionButtons(bool isSmallScreen) {
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
              ),
            ),
            const SizedBox(width: 16),
            // Botão Salvar
            Expanded(
              child: _buildActionButton(
                icon: Icons.save,
                label: 'Salvar',
                color: const Color(0xFF6C63FF),
                textColor: Colors.white,
                onPressed: () => _controller.saveReading(),
                isPrimary: true,
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          isFullWidth: true,
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
    bool isOutlined = false,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        icon: Icon(icon, size: isSmallScreen ? 18 : 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
          ),
        ),
      )
          : ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: isSmallScreen ? 18 : 20),
        label: Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: isPrimary ? 0 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.symmetric(
            vertical: isSmallScreen ? 12 : 16,
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