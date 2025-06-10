import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/models/tarot_model.dart';

class CardDetailsScreen extends StatefulWidget {
  const CardDetailsScreen({super.key});

  @override
  State<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends State<CardDetailsScreen> with TickerProviderStateMixin {
  final TarotController _controller = Get.find<TarotController>();
  bool _isReversed = false;
  bool _showMeaning = true;

  // Animações
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Para o efeito parallax
  double _dragStartPosition = 0.0;
  double _offsetX = 0.0;
  double _offsetY = 0.0;
  final double _maxOffset = 10.0;

  // Controller para o PageView de palavras-chave
  final PageController _keywordsPageController = PageController();

  @override
  void initState() {
    super.initState();

    // Verificar se tem cardId nos argumentos
    if (Get.arguments != null && Get.arguments is String) {
      final cardId = Get.arguments as String;
      _controller.viewCardDetails(cardId);
    }

    // Animação de virar a carta
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOutBack),
    );

    // Animação de fade para o conteúdo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Efeito haptico ao entrar na tela
    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _flipController.dispose();
    _fadeController.dispose();
    _keywordsPageController.dispose();
    super.dispose();
  }

  void _flipCard() async {
    // Efeito haptico
    HapticFeedback.lightImpact();

    // Fade out do conteúdo
    await _fadeController.forward();

    setState(() {
      _isReversed = !_isReversed;
    });

    // Animação de virar a carta
    if (_isReversed) {
      await _flipController.forward();
    } else {
      await _flipController.reverse();
    }

    // Fade in do conteúdo
    await _fadeController.reverse();
  }

  void _onPanStart(DragStartDetails details) {
    _dragStartPosition = details.globalPosition.dy;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Efeito parallax com base no movimento do dedo
      _offsetX = (details.globalPosition.dx / MediaQuery.of(context).size.width - 0.5) * _maxOffset;
      _offsetY = (details.globalPosition.dy / MediaQuery.of(context).size.height - 0.5) * _maxOffset;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Verificar se foi um movimento para cima ou para baixo
    final endPosition = details.velocity.pixelsPerSecond.dy;
    final difference = endPosition - _dragStartPosition;

    // Se o movimento for significativo para baixo, mostrar significado
    if (difference > 300) {
      setState(() {
        _showMeaning = true;
      });
    }
    // Se o movimento for significativo para cima, mostrar apenas a carta
    else if (difference < -300) {
      setState(() {
        _showMeaning = false;
      });
    }

    // Resetar o efeito parallax gradualmente
    setState(() {
      _offsetX = 0;
      _offsetY = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      body: Obx(() {
        final card = _controller.currentCard.value;

        if (card == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // Background com gradiente e efeito
            _buildAnimatedBackground(),

            // Conteúdo principal
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(card),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildCardSection(card),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _showMeaning
                                ? _buildMeaningSection(card)
                                : const SizedBox(height: 100),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Indicador de arraste
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: _buildSwipeIndicator(),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        // Mudar a cor de fundo com base no estado da carta
        final startColor = _isReversed ? const Color(0xFF2D2D44) : const Color(0xFF1E1E2E);
        final endColor = _isReversed ? const Color(0xFF3F3D56) : const Color(0xFF2A2A40);

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [startColor, endColor],
            ),
          ),
          child: Stack(
            children: [
              // Elementos decorativos animados
              Positioned(
                top: -50 + (_offsetY * 2),
                right: -50 + (_offsetX * 2),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _isReversed
                            ? const Color(0xFF6C63FF).withOpacity(0.3)
                            : const Color(0xFF8E78FF).withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -100 - (_offsetY * 2),
                left: -50 - (_offsetX * 2),
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _isReversed
                            ? const Color(0xFFFF9D8A).withOpacity(0.2)
                            : const Color(0xFFFF9D8A).withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Efeito de partículas ou estrelas
              ..._buildStars(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildStars() {
    final random = DateTime.now().millisecondsSinceEpoch;
    const starCount = 20;
    final stars = <Widget>[];

    for (var i = 0; i < starCount; i++) {
      final size = (random % (10 * (i + 1))) % 4 + 1.0;
      final left = (random % (100 * (i + 1))) % MediaQuery.of(context).size.width;
      final top = (random % (200 * (i + 1))) % MediaQuery.of(context).size.height;
      final opacity = ((random % (10 * (i + 1))) % 10) / 10;

      stars.add(
          Positioned(
            left: left.toDouble(),
            top: top.toDouble(),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5 + (opacity * 0.5)),
                shape: BoxShape.circle,
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: i * 100),
            duration: const Duration(milliseconds: 1000),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .fadeOut(
            begin: 1.0,
            duration: Duration(milliseconds: 1000 + (i * 200)),
          )
      );
    }

    return stars;
  }

  Widget _buildAppBar(TarotCard card) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            splashRadius: 24,
          ),
          Text(
            card.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          IconButton(
            onPressed: () {
              // Implementar compartilhamento
            },
            icon: const Icon(Icons.share, color: Colors.white),
            splashRadius: 24,
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    ).slideY(begin: -0.1, end: 0);
  }

  Widget _buildCardSection(TarotCard card) {
    return GestureDetector(
      onTap: _flipCard,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedBuilder(
          animation: _flipAnimation,
          builder: (context, child) {
            // Calcular a rotação para o efeito 3D
            final value = _flipAnimation.value;
            final rotate = value * 3.14159; // 180 graus em radianos

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspectiva
                ..rotateY(rotate) // Rotação no eixo Y para efeito de virar
                ..translate(_offsetX, _offsetY, 0) // Translação para efeito parallax
                ..scale(1.0 + (value * 0.05)), // Leve aumento de escala durante a animação
              child: Container(
                width: double.infinity,
                height: 420,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _isReversed
                          ? const Color(0xFFFF9D8A).withOpacity(0.5)
                          : const Color(0xFF6C63FF).withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Imagem da carta
                      Positioned.fill(
                        child: Image.network(
                          card.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.black26,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white54,
                                  size: 42,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Overlay gradiente para melhorar legibilidade
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(_isReversed ? 0.8 : 0.6),
                              ],
                              stops: const [0.7, 1.0],
                            ),
                          ),
                        ),
                      ),

                      // Nome da carta e indicador de estado
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  card.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black87,
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_isReversed)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9D8A).withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    'Invertida',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Indicador de toque
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app,
                                color: Colors.white70,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Toque para virar',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 800),
    ).slideY(begin: 0.2, end: 0);
  }

  Widget _buildMeaningSection(TarotCard card) {
    final meaning = _isReversed ? card.reversedMeaning : card.uprightMeaning;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título da seção de significado
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isReversed
                        ? const Color(0xFFFF9D8A).withOpacity(0.2)
                        : const Color(0xFF6C63FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _isReversed ? Icons.psychology : Icons.lightbulb_outline,
                    color: _isReversed
                        ? const Color(0xFFFF9D8A)
                        : const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _isReversed ? 'Significado Invertido' : 'Significado',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Texto do significado
            Text(
              meaning,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 30),

            // Palavras-chave em carrossel
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.label_outline,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Palavras-chave',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: PageView.builder(
                    controller: _keywordsPageController,
                    itemCount: (card.keywords.length / 3).ceil(),
                    itemBuilder: (context, pageIndex) {
                      final startIndex = pageIndex * 3;
                      final endIndex = (startIndex + 3) < card.keywords.length
                          ? (startIndex + 3)
                          : card.keywords.length;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          endIndex - startIndex,
                              (index) => _buildKeywordChip(card.keywords[startIndex + index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Informações adicionais
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Informações',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Arcano', _getArcanoType(card.suit)),
                      const SizedBox(height: 12),
                      _buildInfoRow('Naipe', card.suit),
                      const SizedBox(height: 12),
                      _buildInfoRow('Número', card.number.toString()),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Botão de ação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Implementar adição a uma leitura
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 10,
                  shadowColor: const Color(0xFF6C63FF).withOpacity(0.5),
                ),
                child: const Text(
                  'Adicionar à Leitura',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 100), // Espaço extra no final
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildKeywordChip(String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isReversed
            ? const Color(0xFFFF9D8A).withOpacity(0.2)
            : const Color(0xFF6C63FF).withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _isReversed
              ? const Color(0xFFFF9D8A).withOpacity(0.5)
              : const Color(0xFF6C63FF).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        keyword,
        style: TextStyle(
          color: _isReversed
              ? const Color(0xFFFF9D8A)
              : const Color(0xFF6C63FF),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _showMeaning ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            _showMeaning ? 'Deslize para cima para esconder' : 'Deslize para baixo para ver o significado',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).slideY(
      begin: 0,
      end: 0.2,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
    );
  }

  String _getArcanoType(String suit) {
    if (suit.toLowerCase().contains('arcanos maiores')) {
      return 'Maior';
    } else {
      return 'Menor';
    }
  }
}