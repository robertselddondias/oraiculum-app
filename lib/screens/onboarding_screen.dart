import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/config/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bem-vindo ao Astral Connect',
      description: 'Sua conexão com o universo através da astrologia, tarô e consultas com médiuns experientes.',
      animationPath: 'assets/animations/stars.json',
      icon: Icons.nights_stay_rounded,
    ),
    OnboardingPage(
      title: 'Horóscopo Personalizado',
      description: 'Acesse seu horóscopo diário, mapa astral e análises de compatibilidade com tecnologia avançada de IA.',
      animationPath: 'assets/animations/horoscope.json',
      icon: Icons.auto_graph,
    ),
    OnboardingPage(
      title: 'Tarô e Leituras',
      description: 'Receba interpretações de cartas de tarô e orientação para seus caminhos com leituras detalhadas.',
      animationPath: 'assets/animations/tarot.json',
      icon: Icons.grid_view,
    ),
    OnboardingPage(
      title: 'Consultas com Médiuns',
      description: 'Conecte-se com médiuns experientes e receba orientações personalizadas para sua jornada espiritual.',
      animationPath: 'assets/animations/medium.json',
      icon: Icons.people,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markFirstTimeDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _markFirstTimeDone();
                        Get.offAllNamed(AppRoutes.login);
                      },
                      child: Text(
                        'Pular',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _isLastPage = index == _pages.length - 1;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: AppTheme.accentColor,
                        dotColor: Colors.white.withOpacity(0.3),
                        dotHeight: 8,
                        dotWidth: 8,
                        spacing: 4,
                        expansionFactor: 3,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_isLastPage) {
                          _markFirstTimeDone();
                          Get.offAllNamed(AppRoutes.login);
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _isLastPage ? 'Começar' : 'Próximo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    // Se não tiver o arquivo Lottie, mostrar um ícone animado
    const bool hasLottieFile = false; // Mude para true quando tiver os arquivos Lottie

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasLottieFile)
            Lottie.asset(
              page.animationPath,
              height: 280,
              repeat: true,
            )
          else
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                page.icon,
                size: 100,
                color: Colors.white,
              ),
            ).animate()
                .scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutBack,
            )
                .fadeIn(duration: const Duration(milliseconds: 400)),
          const SizedBox(height: 60),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ).animate(delay: const Duration(milliseconds: 200))
              .slideY(
            begin: 0.2,
            end: 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
          )
              .fadeIn(),
          const SizedBox(height: 20),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.8),
              height: 1.5,
              fontSize: 16,
            ),
          ).animate(delay: const Duration(milliseconds: 400))
              .slideY(
            begin: 0.2,
            end: 0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuad,
          )
              .fadeIn(),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String animationPath;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.animationPath,
    required this.icon,
  });
}