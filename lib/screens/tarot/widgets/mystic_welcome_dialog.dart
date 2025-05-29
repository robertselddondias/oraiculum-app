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
      barrierColor: Colors.black87,
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

  // Mensagens místicas por página
  final List<Map<String, dynamic>> _mysticMessages = [
    {
      'title': '🌟 Bem-vindo ao Portal dos Arcanos',
      'message': 'As cartas sussurram segredos do universo...\n\nRespire profundamente e conecte-se com sua energia interior. O tarô aguarda para revelar os mistérios que cercam seu caminho.',
      'icon': Icons.auto_awesome,
      'gradient': [Color(0xFF6C63FF), Color(0xFF8E78FF)],
    },
    {
      'title': '🔮 Prepare Sua Mente e Coração',
      'message': 'Feche os olhos por um momento...\n\nPense em uma pergunta que habita seu coração, uma situação que busca clareza, ou simplesmente permita que sua intuição guie este momento sagrado.',
      'icon': Icons.psychology,
      'gradient': [Color(0xFF8E78FF), Color(0xFFFF9D8A)],
    },
    {
      'title': '✨ O Universo Está Ouvindo',
      'message': 'Sua energia está alinhada...\n\nAs cartas já sentem sua presença. Confie no processo, permita que sua intuição flua e esteja aberto às mensagens que o universo tem para você.',
      'icon': Icons.favorite,
      'gradient': [Color(0xFFFF9D8A), Color(0xFF6C63FF)],
    },
  ];

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      child: AnimatedBuilder(
        animation: _starController,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: screenSize.height * 0.75,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Estrelas animadas de fundo
                ...List.generate(30, (index) => _buildAnimatedStar(index, screenSize)),

                // Conteúdo principal
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    children: [
                      // Indicador de páginas
                      _buildPageIndicator(),

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
                            return _buildMysticPage(index, isSmallScreen);
                          },
                        ),
                      ),

                      // Botões de navegação
                      _buildNavigationButtons(isSmallScreen),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedStar(int index, Size screenSize) {
    final random = Random(index);
    final size = random.nextDouble() * 3 + 1;
    final left = random.nextDouble() * screenSize.width;
    final top = random.nextDouble() * (screenSize.height * 0.75);
    final animationDelay = random.nextDouble() * 2000;

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _starController,
        builder: (context, child) {
          final opacity = (sin(_starController.value * 2 * pi + animationDelay) + 1) / 2;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(opacity * 0.8),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(opacity * 0.3),
                  blurRadius: size * 2,
                  spreadRadius: size * 0.5,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_totalPages, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: _currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
              boxShadow: _currentPage == index ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMysticPage(int index, bool isSmallScreen) {
    final message = _mysticMessages[index];

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone central com animação de pulso
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.2);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: isSmallScreen ? 80 : 100,
                  height: isSmallScreen ? 80 : 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: message['gradient'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: message['gradient'][0].withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    message['icon'],
                    color: Colors.white,
                    size: isSmallScreen ? 40 : 50,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: isSmallScreen ? 30 : 40),

          // Título
          Text(
            message['title'],
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(
            delay: Duration(milliseconds: 200 * index),
            duration: const Duration(milliseconds: 800),
          ),

          SizedBox(height: isSmallScreen ? 20 : 30),

          // Mensagem principal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Text(
              message['message'],
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.white.withOpacity(0.9),
                height: 1.6,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 400 * index),
            duration: const Duration(milliseconds: 1000),
          ).slideY(
            begin: 0.1,
            end: 0,
            curve: Curves.easeOutQuart,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Pular
          TextButton(
            onPressed: _closeMysticDialog,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Pular',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),

          // Botão Continuar/Começar
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final isLastPage = _currentPage == _totalPages - 1;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: LinearGradient(
                    colors: _mysticMessages[_currentPage]['gradient'],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _mysticMessages[_currentPage]['gradient'][0].withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
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
                      horizontal: isSmallScreen ? 20 : 30,
                      vertical: isSmallScreen ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(
                    isLastPage ? Icons.psychology : Icons.arrow_forward,
                    size: isSmallScreen ? 18 : 20,
                  ),
                  label: Text(
                    isLastPage ? 'Revelar Destino' : 'Continuar',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
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
}