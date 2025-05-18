import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import 'dart:convert';

class TarotReadingScreen extends StatefulWidget {
  const TarotReadingScreen({Key? key}) : super(key: key);

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> with TickerProviderStateMixin {
  final TarotController _controller = Get.find<TarotController>();

  // Controladores para animações de virar cartas
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;

  // Estados das cartas
  final RxList<bool> _cardRevealed = [false, false, false].obs;
  final RxBool _allCardsRevealed = false.obs;
  final RxBool _readingPerformed = false.obs;
  final RxMap<String, dynamic> _parsedInterpretation = <String, dynamic>{}.obs;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores de animação
    _flipControllers = List.generate(
      3,
          (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _flipAnimations = _flipControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOutBack),
      );
    }).toList();

    // Carregar cartas aleatórias
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRandomCards();
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
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    super.dispose();
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
  }

  void _flipCard(int index) {
    if (!_cardRevealed[index]) {
      _flipControllers[index].forward();
      _cardRevealed[index] = true;
    }
  }

  void _performReading() async {
    if (_allCardsRevealed.value && !_readingPerformed.value) {
      await _controller.performReading();
      _readingPerformed.value = true;
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

  @override
  Widget build(BuildContext context) {
    // Obter dimensões para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de Tarô'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRandomCards,
            tooltip: 'Novas cartas',
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.selectedCards.isEmpty) {
          return const Center(
            child: Text('Carregando cartas de tarô...'),
          );
        }

        return Column(
          children: [
            Expanded(
              child: _readingPerformed.value
                  ? _buildReadingResult(isSmallScreen, padding)
                  : _buildCardsDeck(isSmallScreen),
            ),
            if (_allCardsRevealed.value && !_readingPerformed.value)
              _buildPerformReadingButton(isSmallScreen),
          ],
        );
      }),
    );
  }

  Widget _buildCardsDeck(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _allCardsRevealed.value
                ? 'Todas as cartas foram reveladas'
                : 'Toque nas cartas para revelá-las',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) {
              return _buildTarotCard(index, isSmallScreen);
            }),
          ),
          const SizedBox(height: 24),
          Text(
            _allCardsRevealed.value
                ? 'Pressione "Interpretar" para receber sua leitura'
                : 'Revele todas as cartas para prosseguir',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarotCard(int index, bool isSmallScreen) {
    final cardWidth = isSmallScreen ? 80.0 : 100.0;
    final cardHeight = cardWidth * 1.5;

    return GestureDetector(
      onTap: () => _flipCard(index),
      child: AnimatedBuilder(
        animation: _flipAnimations[index],
        builder: (context, child) {
          final value = _flipAnimations[index].value;
          final isRevealed = value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(pi * value),
            child: Container(
              width: cardWidth,
              height: cardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: isRevealed
                  ? _buildCardFront(index, cardWidth, cardHeight)
                  : _buildCardBack(cardWidth, cardHeight),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardFront(int index, double width, double height) {
    final card = _controller.selectedCards[index];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(card.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
            ],
            stops: const [0.7, 1.0],
          ),
        ),
        alignment: Alignment.bottomCenter,
        padding: const EdgeInsets.all(8),
        child: Text(
          card.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCardBack(double width, double height) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Padrão decorativo
            CustomPaint(
              painter: TarotBackPatternPainter(),
            ),
            // Ícone central
            Center(
              child: Icon(
                Icons.auto_awesome,
                color: Colors.white.withOpacity(0.8),
                size: width * 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformReadingButton(bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _performReading,
          icon: const Icon(Icons.psychology),
          label: const Text('Interpretar Cartas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildReadingResult(bool isSmallScreen, double padding) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mostrar as cartas selecionadas em miniatura
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _controller.selectedCards.length,
              itemBuilder: (context, index) {
                final card = _controller.selectedCards[index];
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          card.imageUrl,
                          width: 60,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        card.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Título da interpretação
          const Text(
            'Sua Interpretação',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Interpretação - seções com base no JSON
          if (_parsedInterpretation.containsKey('geral'))
            _buildInterpretationSection(
              title: _parsedInterpretation['geral']['title'] ?? 'Interpretação Geral',
              content: _parsedInterpretation['geral']['body'] ?? '',
              icon: Icons.auto_awesome,
              color: const Color(0xFF6C63FF),
              isSmallScreen: isSmallScreen,
            ),

          if (_parsedInterpretation.containsKey('amor'))
            _buildInterpretationSection(
              title: _parsedInterpretation['amor']['title'] ?? 'Amor',
              content: _parsedInterpretation['amor']['body'] ?? '',
              icon: Icons.favorite,
              color: Colors.redAccent,
              isSmallScreen: isSmallScreen,
            ),

          if (_parsedInterpretation.containsKey('trabalho'))
            _buildInterpretationSection(
              title: _parsedInterpretation['trabalho']['title'] ?? 'Trabalho',
              content: _parsedInterpretation['trabalho']['body'] ?? '',
              icon: Icons.work,
              color: Colors.blueAccent,
              isSmallScreen: isSmallScreen,
            ),

          if (_parsedInterpretation.containsKey('saude'))
            _buildInterpretationSection(
              title: _parsedInterpretation['saude']['title'] ?? 'Saúde',
              content: _parsedInterpretation['saude']['body'] ?? '',
              icon: Icons.favorite_border,
              color: Colors.greenAccent,
              isSmallScreen: isSmallScreen,
            ),

          if (_parsedInterpretation.containsKey('conselho'))
            _buildInterpretationSection(
              title: _parsedInterpretation['conselho']['title'] ?? 'Conselho',
              content: _parsedInterpretation['conselho']['body'] ?? '',
              icon: Icons.lightbulb_outline,
              color: Colors.amberAccent,
              isSmallScreen: isSmallScreen,
            ),

          // Se não houver nenhuma seção ou apenas a geral, mostrar todo o texto
          if (_parsedInterpretation.isEmpty || (_parsedInterpretation.length == 1 && _parsedInterpretation.containsKey('geral')))
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _controller.interpretation.value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Botões de ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadRandomCards,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Nova Leitura'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _controller.saveReading(),
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Implementar compartilhamento
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compartilhando leitura...'))
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Compartilhar'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationSection({
    required String title,
    required String content,
    required IconData icon,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withOpacity(0.2),
                ),
              ),
              child: Text(
                content,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 500),
    );
  }
}

// Classe para pintar o fundo das cartas
class TarotBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Desenhar padrão geométrico
    final spacing = size.width / 6;

    // Linhas horizontais
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(0, i * spacing),
        Offset(size.width, i * spacing),
        paint,
      );
    }

    // Linhas verticais
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(
        Offset(i * spacing, 0),
        Offset(i * spacing, size.height),
        paint,
      );
    }

    // Desenhar bordas decorativas
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final borderRect = Rect.fromLTWH(
      size.width * 0.1,
      size.height * 0.1,
      size.width * 0.8,
      size.height * 0.8,
    );

    canvas.drawRect(borderRect, borderPaint);

    // Desenhar símbolos esotéricos nos cantos
    final symbolPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    const symbolSize = 10.0;

    // Círculos nos cantos
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.1), symbolSize, symbolPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), symbolSize, symbolPaint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), symbolSize, symbolPaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.9), symbolSize, symbolPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}