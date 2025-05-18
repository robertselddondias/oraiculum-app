import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:convert';
import 'package:oraculum/utils/zodiac_utils.dart';
import 'compatibility_widgets.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({Key? key}) : super(key: key);

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> with SingleTickerProviderStateMixin {
  final HoroscopeController _controller = Get.find<HoroscopeController>();

  String _sign1 = 'Áries';
  String _sign2 = 'import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:oraculum/controllers/horoscope_controller.dart';
  import 'package:flutter_animate/flutter_animate.dart';
  import 'package:intl/intl.dart';
  import 'package:intl/date_symbol_data_local.dart';
  import 'dart:convert';
  import 'compatibility_widgets.dart';

  class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({Key? key}) : super(key: key);

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
  }

  class _CompatibilityScreenState extends State<CompatibilityScreen> with SingleTickerProviderStateMixin {
  final HoroscopeController _controller = Get.find<HoroscopeController>();

  String _sign1 = 'Áries';
  String _sign2 = 'Touro';
  final RxString _compatibilityResult = ''.obs;
  final RxBool _isLoading = false.obs;
  final RxMap<String, dynamic> _parsedCompatibility = <String, dynamic>{}.obs;

  // Controlador para animação
  late AnimationController _animationController;

  @override
  void initState() {
  super.initState();
  // Inicializar formatação de data em português
  initializeDateFormatting('pt_BR', null);

  // Configurar animação
  _animationController = AnimationController(
  duration: const Duration(milliseconds: 800),
  vsync: this,
  );
  }

  @override
  void dispose() {
  _animationController.dispose();
  super.dispose();
  }

  void _parseCompatibilityData(String content) {
  try {
  // Tentar analisar o conteúdo como JSON
  final Map<String, dynamic> data = json.decode(content);
  _parsedCompatibility.value = data;
  } catch (e) {
  // Se falhar, usar o conteúdo como texto geral
  _parsedCompatibility.value = {
  'geral': {'title': 'Compatibilidade Geral', 'body': content},
  };
  }
  }

  @override
  Widget build(BuildContext context) {
  // Obter dimensões para layout responsivo
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 360;
  final padding = isSmallScreen ? 12.0 : 16.0;

  return Scaffold(
  body: Obx(() {
  return CustomScrollView(
  physics: const BouncingScrollPhysics(),
  slivers: [
  CompatibilityWidgets.buildSliverAppBar(
  context: context,
  sign1: _sign1,
  sign2: _sign2,
  isSmallScreen: isSmallScreen,
  ),
  SliverToBoxAdapter(
  child: Padding(
  padding: EdgeInsets.symmetric(horizontal: padding),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  const SizedBox(height: 16),
  CompatibilityWidgets.buildHeader(context, isSmallScreen),
  const SizedBox(height: 24),
  _buildSignSelectors(isSmallScreen, screenWidth),
  const SizedBox(height: 24),
  _buildAnalyzeButton(isSmallScreen),
  const SizedBox(height: 24),
  if (_isLoading.value)
  CompatibilityWidgets.buildLoadingIndicator(_sign1, _sign2)
  else if (_compatibilityResult.isNotEmpty)
  _buildResultCard(isSmallScreen),
  const SizedBox(height: 40),
  ],
  ),
  ),
  ),
  ],
  );
  }),
  );
  }

  Widget _buildSignSelectors(bool isSmallScreen, double screenWidth) {
  final cardHeight = screenWidth > 600 ? 280.0 : isSmallScreen ? 220.0 : 250.0;
  final iconSize = isSmallScreen ? 80.0 : 100.0;
  final heartSize = isSmallScreen ? 40.0 : 50.0;
  final signSize = isSmallScreen ? 14.0 : 16.0;

  return Container(
  width: double.infinity,
  height: cardHeight,
  decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
  gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
  Theme.of(context).cardColor,
  Theme.of(context).cardColor.withOpacity(0.9),
  ],
  ),
  boxShadow: [
  BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
  spreadRadius: 1,
  ),
  ],
  ),
  child: Column(
  children: [
  Padding(
  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
  child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
  CompatibilityWidgets.buildSignDropdown(
  context: context,
  label: 'Primeiro Signo',
  currentSign: _sign1,
  zodiacSigns: _controller.zodiacSigns,
  onChanged: (String? newSign) {
  if (newSign != null) {
  setState(() {
  _sign1 = newSign;
  });
  _compatibilityResult.value = '';
  _parsedCompatibility.clear();
  }
  },
  isSmallScreen: isSmallScreen,
  ),
  CompatibilityWidgets.buildSignDropdown(
  context: context,
  label: 'Segundo Signo',
  currentSign: _sign2,
  zodiacSigns: _controller.zodiacSigns,
  onChanged: (String? newSign) {
  if (newSign != null) {
  setState(() {
  _sign2 = newSign;
  });
  _compatibilityResult.value = '';
  _parsedCompatibility.clear();
  }
  },
  isSmallScreen: isSmallScreen,
  ),
  ],
  ),
  ),
  Expanded(
  child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
  // Primeiro signo
  CompatibilityWidgets.buildSignPreview(
  context: context,
  sign: _sign1,
  iconSize: iconSize,
  textSize: signSize,
  isSmallScreen: isSmallScreen,
  ).animate(
  onPlay: (controller) => controller.repeat(reverse: true),
  delay: const Duration(milliseconds: 500),
  ).scale(
  begin: const Offset(1.0, 1.0),
  end: const Offset(1.1, 1.1),
  duration: const Duration(seconds: 3),
  curve: Curves.easeInOut,
  ),

  // Ícone do coração pulsante
  Container(
  width: heartSize,
  height: heartSize,
  decoration: BoxDecoration(
  color: Colors.red.withOpacity(0.2),
  shape: BoxShape.circle,
  ),
  child: const Icon(
  Icons.favorite,
  color: Colors.red,
  ),
  ).animate(
  onPlay: (controller) => controller.repeat(reverse: true),
  ).scale(
  begin: const Offset(1.0, 1.0),
  end: const Offset(1.4, 1.4),
  duration: const Duration(seconds: 1),
  curve: Curves.easeInOut,
  ),

  // Segundo signo
  CompatibilityWidgets.buildSignPreview(
  context: context,
  sign: _sign2,
  iconSize: iconSize,
  textSize: signSize,
  isSmallScreen: isSmallScreen,
  ).animate(
  onPlay: (controller) => controller.repeat(reverse: true),
  delay: const Duration(milliseconds: 800),
  ).scale(
  begin: const Offset(1.0, 1.0),
  end: const Offset(1.1, 1.1),
  duration: const Duration(seconds: 3),
  curve: Curves.easeInOut,
  ),
  ],
  ),
  ),
  ],
  ),
  ).animate().fadeIn(
  delay: const Duration(milliseconds: 300),
  duration: const Duration(milliseconds: 500),
  );
  }

  Widget _buildAnalyzeButton(bool isSmallScreen) {
  final buttonTextSize = isSmallScreen ? 14.0 : 16.0;
  final color1 = CompatibilityWidgets.getSignColor(_sign1);
  final color2 = CompatibilityWidgets.getSignColor(_sign2);

  return Container(
  width: double.infinity,
  height: isSmallScreen ? 50 : 56,
  decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
  boxShadow: [
  BoxShadow(
  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
  blurRadius: 10,
  offset: const Offset(0, 5),
  ),
  ],
  gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [color1, color2],
  ),
  ),
  child: ElevatedButton(
  onPressed: _analyzeCompatibility,
  style: ElevatedButton.styleFrom(
  backgroundColor: Colors.transparent,
  foregroundColor: Colors.white,
  shadowColor: Colors.transparent,
  padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
  shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(isSmallScreen ? 14 : 16),
  ),
  elevation: 0,
  ),
  child: Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  const Icon(Icons.psychology_outlined),
  const SizedBox(width: 8),
  Text(
  'Analisar Compatibilidade',
  style: TextStyle(
  fontSize: buttonTextSize,
  fontWeight: FontWeight.bold,
  ),
  ),
  ],
  ),
  ),
  ).animate().fadeIn(
  delay: const Duration(milliseconds: 400),
  duration: const Duration(milliseconds: 500),
  );
  }

  Widget _buildResultCard(bool isSmallScreen) {
  // Calcular as cores com base nos signos selecionados
  final color1 = CompatibilityWidgets.getSignColor(_sign1);
  final color2 = CompatibilityWidgets.getSignColor(_sign2);

  // Formatar a data atual em português
  final today = DateTime.now();
  final formattedDate = DateFormat.MMMMEEEEd('pt_BR').format(today);

  // Calcular o score (compatibilidade simulada)
  final score = CompatibilityWidgets.calculateCompatibilityScore(_sign1, _sign2);

  return Container(
  width: double.infinity,
  decoration: BoxDecoration(
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
  BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 20,
  spreadRadius: 1,
  ),
  ],
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  // Cabeçalho com signos e data
  Container(
  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
  decoration: BoxDecoration(
  borderRadius: const BorderRadius.vertical(
  top: Radius.circular(20),
  ),
  gradient: LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
  color1.withOpacity(0.9),
  color2.withOpacity(0.9),
  ],
  ),
  ),
  child: Column(
  children: [
  Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
  CircleAvatar(
  backgroundColor: Colors.white24,
  radius: isSmallScreen ? 20 : 24,
  child: CompatibilityWidgets.buildZodiacImage(_sign1, size: isSmallScreen ? 24 : 28, color: Colors.white),
  ),
  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 12),
  child: Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(
  color: Colors.white24,
  shape: BoxShape.circle,
  ),
  child: const Icon(
  Icons.favorite,
  color: Colors.white,
  ),
  ),
  ),
  CircleAvatar(
  backgroundColor: Colors.white24,
  radius: isSmallScreen ? 20 : 24,
  child: CompatibilityWidgets.buildZodiacImage(_sign2, size: isSmallScreen ? 24 : 28, color: Colors.white),
  ),
  ],
  ),
  const SizedBox(height: 16),
  Text(
  '$_sign1 & $_sign2',
  style: TextStyle(
  fontSize: isSmallScreen ? 18 : 22,
  fontWeight: FontWeight.bold,
  color: Colors.white,
  ),
  ),
  const SizedBox(height: 8),
  Text(
  formattedDate,
  style: TextStyle(
  fontSize: isSmallScreen ? 12 : 14,
  color: Colors.white.withOpacity(0.8),
  ),
  ),
  const SizedBox(height: 20),
  // Barra de compatibilidade
  CompatibilityWidgets.buildCompatibilityBar(
  context: context,
  score: score,
  isSmallScreen: isSmallScreen,
  animationController: _animationController,
  ),
  ],
  ),
  ),

  // Conteúdo da análise
  Container(
  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
  decoration: BoxDecoration(
  color: Theme.of(context).cardColor,
  borderRadius: const BorderRadius.vertical(
  bottom: Radius.circular(20),
  ),
  ),
  child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
  if (_parsedCompatibility.containsKey('geral'))
  CompatibilityWidgets.buildCompatibilitySection(
  context: context,
  title: _parsedCompatibility['geral']['title'] ?? 'Compatibilidade Geral',
  content: _parsedCompatibility['geral']['body'] ?? '',
  icon: Icons.auto_awesome,
  color: Theme.of(context).colorScheme.primary,
  isSmallScreen: isSmallScreen,
  ),

  if (_parsedCompatibility.containsKey('emocional'))
  CompatibilityWidgets.buildCompatibilitySection(
  context: context,
  title: _parsedCompatibility['emocional']['title'] ?? 'Compatibilidade Emocional',
  content: _parsedCompatibility['emocional']['body'] ?? '',
  icon: Icons.favorite,
  color: Colors.redAccent,
  isSmallScreen: isSmallScreen,
  ),

  if (_parsedCompatibility.containsKey('comunicacao'))
  CompatibilityWidgets.buildCompatibilitySection(
  context: context,
  title: _parsedCompatibility['comunicacao']['title'] ?? 'Comunicação',
  content: _parsedCompatibility['comunicacao']['body'] ?? '',
  icon: Icons.message,
  color: Colors.blueAccent,
  isSmallScreen: isSmallScreen,
  ),

  if (_parsedCompatibility.containsKey('sexual'))
  CompatibilityWidgets.buildCompatibilitySection(
  context: context,
  title: _parsedCompatibility['sexual']['title'] ?? 'Compatibilidade Sexual',
  content: _parsedCompatibility['sexual']['body'] ?? '',
  icon: Icons.spa,
  color: Colors.purpleAccent,
  isSmallScreen: isSmallScreen,
  ),

  if (_parsedCompatibility.containsKey('pontos_fortes'))
  CompatibilityWidgets.buildCompatibilitySection(
  context: context,
  title: _parsedCompatibility['pontos_fortes']['title'] ?? 'Pontos Fortes',
  content: _parsedCompatibility['pontos_fortes']['body'] ?? '',
  icon: Icons.thumb_up,
  color: Colors.greenAccent.shade700,
  isSmallScreen: isSmallScreen,
  ),

  if (_parsedCompatibility.containsKey('desafios'))
  CompatibilityWidgets.buildCompatibilitySection(
  context: context,
  title: _parsedCompatibility['desafios']['title'] ?? 'Desafios',
  content: _parsedCompatibility['desafios']['body'] ?? '',
  icon: Icons.warning_amber,
  color: Colors.orangeAccent,
  isSmallScreen: isSmallScreen,
  ),

  if (_parsedCompatibility.containsKey('conselhos'))
  CompatibilityWidgets.buildCompatibilitySection(
  context: context,
  title: _parsedCompatibility['conselhos']['title'] ?? 'Conselhos',
  content: _parsedCompatibility['conselhos']['body'] ?? '',
  icon: Icons.lightbulb,
  color: Colors.amberAccent,
  isSmallScreen: isSmallScreen,
  ),

  // Caso não seja JSON, mostrar texto completo
  if (_parsedCompatibility.isEmpty || (_parsedCompatibility.containsKey('geral') && _parsedCompatibility.length == 1))
  Padding(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Text(
  _compatibilityResult.value,
  style: TextStyle(
  fontSize: isSmallScreen ? 14 : 16,
  height: 1.6,
  ),
  ),
  ),

  const SizedBox(height: 24),

  // Botões de ação
  CompatibilityWidgets.buildActionButtons(
  context: context,
  isSmallScreen: isSmallScreen,
  color1: color1,
  color2: color2,
  ),
  ],
  ),
  ),
  ],
  ),
  ).animate().fadeIn(
  duration: const Duration(milliseconds: 800),
  ).slideY(
  begin: 0.1,
  end: 0,
  curve: Curves.easeOutQuad,
  duration: const Duration(milliseconds: 500),
  );
  }

  Future<void> _analyzeCompatibility() async {
  if (_sign1 == _sign2) {
  Get.snackbar(
  'Aviso',
  'Selecione signos diferentes para uma análise de compatibilidade mais precisa',
  backgroundColor: Colors.amber,
  colorText: Colors.black,
  snackPosition: SnackPosition.BOTTOM,
  );
  return;
  }

  _isLoading.value = true;
  _compatibilityResult.value = '';
  _parsedCompatibility.clear();

  try {
  // Obter a análise de compatibilidade
  final result = await _controller.getCompatibilityAnalysis(_sign1, _sign2);
  _compatibilityResult.value = result;

  // Tentar analisar como JSON
  _parseCompatibilityData(result);

  // Iniciar animação da barra de compatibilidade
  _animationController.forward(from: 0.0);

  } catch (e) {
  Get.snackbar(
  'Erro',
  'Não foi possível realizar a análise de compatibilidade',
  backgroundColor: Colors.red,
  colorText: Colors.white,
  snackPosition: SnackPosition.BOTTOM,
  );
  } finally {
  _isLoading.value = false;
  }
  }
  }