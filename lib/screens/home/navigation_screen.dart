import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/screens/astrology/horoscope_screen.dart';
import 'package:oraculum/screens/home/home_screen.dart';
import 'package:oraculum/screens/mediums/mediums_list_screen.dart';
import 'package:oraculum/screens/mystic_circle/mystic_circles_screen.dart';
import 'package:oraculum/screens/profile/profile_screen.dart';
import 'package:oraculum/screens/tarot/tarot_reading_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  // Páginas que serão exibidas na navegação
  final List<Widget> _screens = const [
    HomeScreen(),
    HoroscopeScreen(),
    TarotReadingScreen(),
    MysticCirclesScreen(),
    ProfileScreen(),
  ];

  // Controlador para gerenciar a navegação entre abas
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _setStatusBarColor();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFcmTokenOnAppStart();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _updateFcmTokenOnAppStart() async {
    try {
      debugPrint('📱 App iniciado - atualizando FCM Token...');

      final authController = Get.find<AuthController>();

      // Aguardar um pouco para garantir que tudo esteja inicializado
      await Future.delayed(const Duration(seconds: 2));

      // Atualizar via AuthController
      await authController.updateUserFcmToken();

      debugPrint('✅ FCM Token atualizado na inicialização do app');
    } catch (e) {
      debugPrint('❌ Erro ao atualizar FCM Token na inicialização: $e');
    }
  }

  void _setStatusBarColor() {
    if (Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // Salta direto para a página sem exibir as intermediárias
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final iconSize = isSmallScreen ? 22.0 : 24.0;
    final fontSize = isSmallScreen ? 11.0 : 12.0;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) {
          setState(() => _selectedIndex = idx);
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E1E)
                : Colors.white,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            elevation: 16,
            selectedFontSize: fontSize,
            unselectedFontSize: fontSize,
            iconSize: iconSize,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.auto_graph_outlined),
                activeIcon: Icon(Icons.auto_graph),
                label: 'Horóscopo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.style_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: 'Tarô',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Círculo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}