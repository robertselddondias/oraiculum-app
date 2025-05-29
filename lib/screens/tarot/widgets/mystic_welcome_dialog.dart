import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

class MysticWelcomeDialog extends StatefulWidget {
  final VoidCallback onContinue;

  const MysticWelcomeDialog({
    Key? key,
    required this.onContinue,
  }) : super(key: key);

  static Future<void> show(BuildContext context, {required VoidCallback onContinue}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => MysticWelcomeDialog(onContinue: onContinue),
    );
  }

  @override
  State<MysticWelcomeDialog> createState() => _MysticWelcomeDialogState();
}

class _MysticWelcomeDialogState extends State<MysticWelcomeDialog>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 3;

  // Mensagens místicas por página com melhor legibilidade
  final List<Map<String, dynamic>> _mysticMessages = [
    {
      'title': '🌟 Portal dos Arcanos',
      'subtitle': 'As cartas sussurram segredos...',
      'message': 'Respire profundamente e conecte-se com sua energia interior.\n\nO tarô aguarda para revelar os mistérios que cercam seu caminho.',
      'icon': Icons.auto_awesome,
      'gradient': [Color(0xFF6C63FF), Color(0xFF8E78FF)],
    },
    {
      'title': '🔮 Prepare Sua Mente',
      'subtitle': 'Feche os olhos por um momento...',
      'message': 'Pense em uma pergunta que habita seu coração, uma situação que busca clareza.\n\nPermita que sua intuição guie este momento sagrado.',
      'icon': Icons.psychology,
      'gradient': [Color(0xFF8E78FF), Color(0xFFFF9D8A)],
    },
    {
      'title': '✨ O Universo Escuta',
      'subtitle': 'Sua energia está alinhada...',
      'message': 'As cartas já sentem sua presença.\n\nConfie no processo e esteja aberto às mensagens que o universo tem para você.',
      'icon': Icons.favorite,
      'gradient': [Color(0xFFFF9D8A), Color(0xFF6C63FF)],
    },
  ];

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _starController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _closeMysticDialog();
    }
  }

  void _closeMysticDialog() {
    Navigator.of(context).pop();
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isTablet = screenSize.width >= 600;

    // Ajustar altura baseada no tamanho da tela
    final dialogHeight = isSmallScreen
        ? screenSize.height * 0.9 // Mais espaço em telas pequenas
        : isTablet
        ? screenSize.height * 0.8
        : screenSize.height * 0.85;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isSmallScreen ? 8 : isTablet ? 32 : 16), // Reduzir padding em telas pequenas
      child: Container(
        width: double.infinity,
        height: dialogHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Fundo com gradiente melhorado
              _buildEnhancedBackground(screenSize),

              // Estrelas animadas mais sutis
              ...List.generate(isSmallScreen ? 15 : 25, (index) => _buildSubtleAnimatedStar(index, screenSize)),

              // Conteúdo principal com melhor distribuição de espaço
              Column(
                mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
                children: [
                  // Indicador de páginas melhorado
                  _buildEnhancedPageIndicator(isTablet, isSmallScreen),

                  // Conteúdo das páginas - usar Flexible em vez de Expanded
                  Flexible(
                    flex: 1,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _totalPages,
                      itemBuilder: (context, index) {
                        return _buildEnhancedMysticPage(index, isSmallScreen, isTablet);
                      },
                    ),
                  ),

                  // Botões de navegação melhorados
                  _buildEnhancedNavigationButtons(isSmallScreen, isTablet),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedBackground(Size screenSize) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0F0F23),
            const Color(0xFF1A1A2E),
            const Color(0xFF16213E),
            const Color(0xFF0F3460),
          ],
          stops: const [0.0, 0.3, 0.6, 1.0],
        ),
      ),
    );
  }

  Widget _buildSubtleAnimatedStar(int index, Size screenSize) {
    final random = Random(index);
    final size = random.nextDouble() * 2 + 1;
    final left = random.nextDouble() * screenSize.width;
    final top = random.nextDouble() * (screenSize.height * 0.8);
    final animationDelay = random.nextDouble() * 1000;

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _starController,
        builder: (context, child) {
          final opacity = (sin((_starController.value * 2 * pi) + animationDelay) + 1) / 2;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity * 0.4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(opacity * 0.2),
                  blurRadius: size * 1.5,
                  spreadRadius: size * 0.3,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedPageIndicator(bool isTablet, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 12 : (isTablet ? 24 : 16) // Reduzir padding vertical em telas pequenas
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.symmetric(horizontal: 4), // Reduzir margin
            width: _currentPage == index ? (isSmallScreen ? 24 : 32) : 10, // Ajustar tamanhos
            height: 10, // Reduzir altura
            decoration: BoxDecoration(
              gradient: _currentPage == index
                  ? LinearGradient(
                colors: _mysticMessages[_currentPage]['gradient'],
              )
                  : null,
              color: _currentPage == index ? null : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(5),
              boxShadow: _currentPage == index ? [
                BoxShadow(
                  color: _mysticMessages[_currentPage]['gradient'][0].withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEnhancedMysticPage(int index, bool isSmallScreen, bool isTablet) {
    final message = _mysticMessages[index];

    return SingleChildScrollView( // Adicionar scroll para evitar overflow
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 48 : (isSmallScreen ? 16 : 24), // Reduzir padding horizontal
          vertical: isTablet ? 16 : (isSmallScreen ? 8 : 12), // Reduzir padding vertical
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Importante para evitar overflow
          children: [
            // Ícone central com animação de pulso melhorada
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: isTablet ? 100 : (isSmallScreen ? 70 : 80), // Reduzir tamanhos
                    height: isTablet ? 100 : (isSmallScreen ? 70 : 80),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: message['gradient'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: message['gradient'][0].withOpacity(0.6),
                          blurRadius: 20, // Reduzir blur
                          spreadRadius: 6, // Reduzir spread
                        ),
                        BoxShadow(
                          color: message['gradient'][1].withOpacity(0.4),
                          blurRadius: 30, // Reduzir blur
                          spreadRadius: 8, // Reduzir spread
                        ),
                      ],
                    ),
                    child: Icon(
                      message['icon'],
                      color: Colors.white,
                      size: isTablet ? 50 : (isSmallScreen ? 35 : 40), // Reduzir tamanho do ícone
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: isTablet ? 32 : (isSmallScreen ? 20 : 24)), // Reduzir espaçamentos

            // Título principal com melhor hierarquia
            Text(
              message['title'],
              style: TextStyle(
                fontSize: isTablet ? 24 : (isSmallScreen ? 18 : 20), // Reduzir tamanhos de fonte
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.0, // Reduzir letter spacing
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              delay: Duration(milliseconds: 200 + (index * 100)),
              duration: const Duration(milliseconds: 800),
            ),

            SizedBox(height: isTablet ? 12 : (isSmallScreen ? 6 : 8)), // Reduzir espaçamento

            // Subtítulo com estilo diferenciado
            Text(
              message['subtitle'],
              style: TextStyle(
                fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14), // Reduzir fonte
                color: message['gradient'][0].withOpacity(0.9),
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.6, // Reduzir letter spacing
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
              delay: Duration(milliseconds: 400 + (index * 100)),
              duration: const Duration(milliseconds: 800),
            ),

            SizedBox(height: isTablet ? 24 : (isSmallScreen ? 16 : 20)), // Reduzir espaçamento

            // Card de conteúdo com melhor contraste
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 24 : (isSmallScreen ? 16 : 20)), // Reduzir padding
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A18).withOpacity(0.8),
                borderRadius: BorderRadius.circular(16), // Reduzir radius
                border: Border.all(
                  color: message['gradient'][0].withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 15, // Reduzir blur
                    spreadRadius: 1, // Reduzir spread
                  ),
                  BoxShadow(
                    color: message['gradient'][0].withOpacity(0.1),
                    blurRadius: 20, // Reduzir blur
                    spreadRadius: 3, // Reduzir spread
                  ),
                ],
              ),
              child: Text(
                message['message'],
                style: TextStyle(
                  fontSize: isTablet ? 16 : (isSmallScreen ? 13 : 14), // Reduzir fonte
                  color: Colors.white.withOpacity(0.95),
                  height: 1.5, // Reduzir line height
                  letterSpacing: 0.2, // Reduzir letter spacing
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 600 + (index * 100)),
              duration: const Duration(milliseconds: 1000),
            ).slideY(
              begin: 0.05,
              end: 0,
              curve: Curves.easeOutCubic,
            ),

            // Elemento decorativo sutil
            if (index == 1) // Só na página do meio
              Container(
                margin: EdgeInsets.only(top: isTablet ? 20 : (isSmallScreen ? 12 : 16)), // Reduzir margin
                width: 50, // Reduzir largura
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: message['gradient'],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ).animate().scaleX(
                delay: Duration(milliseconds: 800 + (index * 100)),
                duration: const Duration(milliseconds: 600),
              ),

            // Adicionar espaçamento extra na parte inferior para telas pequenas
            if (isSmallScreen) SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedNavigationButtons(bool isSmallScreen, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : (isSmallScreen ? 12 : 16)), // Reduzir padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Pular melhorado
          TextButton(
            onPressed: _closeMysticDialog,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.8),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : (isSmallScreen ? 12 : 16), // Reduzir padding
                vertical: isTablet ? 12 : (isSmallScreen ? 8 : 10), // Reduzir padding
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10), // Reduzir radius
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              'Pular',
              style: TextStyle(
                fontSize: isTablet ? 15 : (isSmallScreen ? 12 : 13), // Reduzir fonte
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Botão Continuar/Começar melhorado
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14), // Reduzir radius
              gradient: LinearGradient(
                colors: _mysticMessages[_currentPage]['gradient'],
              ),
              boxShadow: [
                BoxShadow(
                  color: _mysticMessages[_currentPage]['gradient'][0].withOpacity(0.5),
                  blurRadius: 12, // Reduzir blur
                  spreadRadius: 1, // Reduzir spread
                  offset: const Offset(0, 3), // Reduzir offset
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20), // Reduzir padding
                  vertical: isTablet ? 12 : (isSmallScreen ? 8 : 10), // Reduzir padding
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14), // Reduzir radius
                ),
              ),
              icon: Icon(
                _currentPage == _totalPages - 1 ? Icons.psychology : Icons.arrow_forward,
                size: isTablet ? 20 : (isSmallScreen ? 16 : 18), // Reduzir tamanho do ícone
              ),
              label: Text(
                _currentPage == _totalPages - 1 ? 'Revelar Destino' : 'Continuar',
                style: TextStyle(
                  fontSize: isTablet ? 15 : (isSmallScreen ? 12 : 13), // Reduzir fonte
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3, // Reduzir letter spacing
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}