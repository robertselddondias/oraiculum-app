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
      'title': '🌟 Bem-vindo ao Portal dos Arcanos',
      'subtitle': 'As cartas sussurram segredos do universo...',
      'message': 'Respire profundamente e conecte-se com sua energia interior.\n\nO tarô aguarda para revelar os mistérios que cercam seu caminho.',
      'icon': Icons.auto_awesome,
      'gradient': [Color(0xFF6C63FF), Color(0xFF8E78FF)],
    },
    {
      'title': '🔮 Prepare Sua Mente e Coração',
      'subtitle': 'Feche os olhos por um momento...',
      'message': 'Pense em uma pergunta que habita seu coração, uma situação que busca clareza.\n\nPermita que sua intuição guie este momento sagrado.',
      'icon': Icons.psychology,
      'gradient': [Color(0xFF8E78FF), Color(0xFFFF9D8A)],
    },
    {
      'title': '✨ O Universo Está Ouvindo',
      'subtitle': 'Sua energia está alinhada...',
      'message': 'As cartas já sentem sua presença.\n\nConfie no processo, permita que sua intuição flua e esteja aberto às mensagens que o universo tem para você.',
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isSmallScreen ? 12 : isTablet ? 32 : 20),
      child: Container(
        width: double.infinity,
        height: screenSize.height * (isTablet ? 0.8 : 0.85),
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
              ...List.generate(25, (index) => _buildSubtleAnimatedStar(index, screenSize)),

              // Conteúdo principal
              Column(
                children: [
                  // Indicador de páginas melhorado
                  _buildEnhancedPageIndicator(isTablet),

                  // Conteúdo das páginas
                  Expanded(
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

  Widget _buildEnhancedPageIndicator(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 24 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: _currentPage == index ? 32 : 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: _currentPage == index
                  ? LinearGradient(
                colors: _mysticMessages[_currentPage]['gradient'],
              )
                  : null,
              color: _currentPage == index ? null : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(6),
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : (isSmallScreen ? 24 : 32),
        vertical: isTablet ? 20 : 16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone central com animação de pulso melhorada
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.15);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: isTablet ? 120 : (isSmallScreen ? 90 : 100),
                  height: isTablet ? 120 : (isSmallScreen ? 90 : 100),
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
                        blurRadius: 25,
                        spreadRadius: 8,
                      ),
                      BoxShadow(
                        color: message['gradient'][1].withOpacity(0.4),
                        blurRadius: 40,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    message['icon'],
                    color: Colors.white,
                    size: isTablet ? 60 : (isSmallScreen ? 45 : 50),
                  ),
                ),
              );
            },
          ),

          SizedBox(height: isTablet ? 40 : (isSmallScreen ? 32 : 36)),

          // Título principal com melhor hierarquia
          Text(
            message['title'],
            style: TextStyle(
              fontSize: isTablet ? 28 : (isSmallScreen ? 22 : 24),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
            delay: Duration(milliseconds: 200 + (index * 100)),
            duration: const Duration(milliseconds: 800),
          ),

          SizedBox(height: isTablet ? 16 : 12),

          // Subtítulo com estilo diferenciado
          Text(
            message['subtitle'],
            style: TextStyle(
              fontSize: isTablet ? 18 : (isSmallScreen ? 16 : 17),
              color: message['gradient'][0].withOpacity(0.9),
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
            delay: Duration(milliseconds: 400 + (index * 100)),
            duration: const Duration(milliseconds: 800),
          ),

          SizedBox(height: isTablet ? 32 : (isSmallScreen ? 24 : 28)),

          // Card de conteúdo com melhor contraste
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isTablet ? 28 : (isSmallScreen ? 20 : 24)),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A18).withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: message['gradient'][0].withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: message['gradient'][0].withOpacity(0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Text(
              message['message'],
              style: TextStyle(
                fontSize: isTablet ? 18 : (isSmallScreen ? 16 : 17),
                color: Colors.white.withOpacity(0.95),
                height: 1.7,
                letterSpacing: 0.3,
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
              margin: EdgeInsets.only(top: isTablet ? 24 : 20),
              width: 60,
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
        ],
      ),
    );
  }

  Widget _buildEnhancedNavigationButtons(bool isSmallScreen, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 32 : (isSmallScreen ? 20 : 24)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Pular melhorado
          TextButton(
            onPressed: _closeMysticDialog,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.8),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : (isSmallScreen ? 16 : 20),
                vertical: isTablet ? 16 : (isSmallScreen ? 12 : 14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Text(
              'Pular',
              style: TextStyle(
                fontSize: isTablet ? 16 : (isSmallScreen ? 14 : 15),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Botão Continuar/Começar melhorado
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: _mysticMessages[_currentPage]['gradient'],
              ),
              boxShadow: [
                BoxShadow(
                  color: _mysticMessages[_currentPage]['gradient'][0].withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
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
                  horizontal: isTablet ? 32 : (isSmallScreen ? 20 : 24),
                  vertical: isTablet ? 16 : (isSmallScreen ? 12 : 14),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(
                _currentPage == _totalPages - 1 ? Icons.psychology : Icons.arrow_forward,
                size: isTablet ? 22 : (isSmallScreen ? 18 : 20),
              ),
              label: Text(
                _currentPage == _totalPages - 1 ? 'Revelar Destino' : 'Continuar',
                style: TextStyle(
                  fontSize: isTablet ? 16 : (isSmallScreen ? 14 : 15),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}