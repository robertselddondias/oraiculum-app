import 'package:oraculum/screens/astrology/horoscope_screen.dart';
import 'package:oraculum/screens/home/home_screen.dart';
import 'package:oraculum/screens/mediums/mediums_list_screen.dart';
import 'package:oraculum/screens/profile/profile_screen.dart';
import 'package:oraculum/screens/tarot/tarot_reading_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({Key? key}) : super(key: key);

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _selectedIndex = 0;

  // Páginas que serão exibidas na navegação
  final List<Widget> _screens = [
    const HomeScreen(),
    const HoroscopeScreen(),
    const TarotReadingScreen(),
    const MediumsListScreen(),
    const ProfileScreen(),
  ];

  // Controlador para gerenciar a navegação entre abas
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Opcionalmente configurar a cor da barra de status
    _setStatusBarColor();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setStatusBarColor() {
    // Deixar a barra de status com cores claras em iOS
    if (Platform.isIOS) {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Transição suave entre as páginas
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Detectar o tamanho da tela para ajustes responsivos
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Ajustar tamanho dos ícones e fontes com base no tamanho da tela
    final iconSize = isSmallScreen ? 22.0 : 24.0;
    final fontSize = isSmallScreen ? 11.0 : 12.0;
    final bottomNavBarHeight = isSmallScreen ? 56.0 : 60.0;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Desativar deslizar entre páginas
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
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
                icon: Icon(Icons.grid_view_outlined),
                activeIcon: Icon(Icons.grid_view),
                label: 'Tarot',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Médiuns',
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