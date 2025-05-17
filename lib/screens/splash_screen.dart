import 'dart:math';

import 'package:oraculum/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oraculum/controllers/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _animationController.forward();

    // Verificar autenticação e navegar após animação
    Future.delayed(const Duration(seconds: 3), () async {
      // Verificar se é a primeira execução do app
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstTime = prefs.getBool('first_time') ?? true;

      if (isFirstTime) {
        Get.offAllNamed(AppRoutes.onboarding);
      } else if (_authController.isLoggedIn) {
        Get.offAllNamed(AppRoutes.navigation);
      } else {
        Get.offAllNamed(AppRoutes.login);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo animado
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: _buildLogoAnimation(),
              ),
              const SizedBox(height: 40),
              // Nome do app
              Text(
                'ASTRAL CONNECT',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: const Offset(2, 2),
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Conectando você ao universo',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoAnimation() {
    // Primeiro, tente usar animação Lottie se disponível
    try {
      return Lottie.asset(
        'assets/animations/stars.json',
        controller: _animationController,
        width: 200,
        height: 200,
        errorBuilder: (context, error, stackTrace) {
          // Em caso de erro, usar animação de fallback
          return _buildFallbackAnimation();
        },
      );
    } catch (e) {
      // Se não tiver arquivo Lottie, mostrar ícone com animação simples
      return _buildFallbackAnimation();
    }
  }

  Widget _buildFallbackAnimation() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animationController.value * 2 * 3.14159,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.nights_stay_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.9),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment(
                    0.7 * cos(_animationController.value * 4 * 3.14159),
                    0.7 * sin(_animationController.value * 4 * 3.14159),
                  ),
                  child: Icon(
                    Icons.star,
                    size: 24,
                    color: Colors.yellow.withOpacity(0.9),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment(
                    0.7 * cos((_animationController.value * 4 * 3.14159) + 2),
                    0.7 * sin((_animationController.value * 4 * 3.14159) + 2),
                  ),
                  child: Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment(
                    0.7 * cos((_animationController.value * 4 * 3.14159) + 4),
                    0.7 * sin((_animationController.value * 4 * 3.14159) + 4),
                  ),
                  child: Icon(
                    Icons.star,
                    size: 20,
                    color: Colors.yellow.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}