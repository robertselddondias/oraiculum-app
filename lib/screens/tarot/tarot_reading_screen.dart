import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/utils/zodiac_utils.dart';
import 'dart:convert';
import 'dart:math' as math;

class TarotReadingScreen extends StatefulWidget {
  const TarotReadingScreen({Key? key}) : super(key: key);

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> with TickerProviderStateMixin {
  final TarotController _controller = Get.find<TarotController>();

  // Controladores para várias animações
  late TabController _tabController;
  final PageController _pageController = PageController();

  // Estado para a visualização das cartas viradas
  final RxList<bool> _cardRevealed = [false, false, false].obs;
  final RxBool _allCardsRevealed = false.obs;
  final RxBool _readingPerformed = false.obs;
  final RxMap<String, dynamic> _parsedInterpretation = <String, dynamic>{}.obs;

  // Controladores de animação
  late List<AnimationController> _flipControllers;
  late List<Animation<double>> _flipAnimations;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Inicializar controladores de animação para as cartas
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

    // Observar mudanças no estado das cartas
    ever(_cardRevealed, (_) {
      _allCardsRevealed.value = !_cardRevealed.contains(false);
    });

    // Observar a interpretação
    ever(_controller.interpretation, (interpretation) {
      if (interpretation.isNotEmpty) {
        _parseInterpretationData(interpretation);
      }
    });

    // Resetar a leitura ao iniciar
    _controller.resetReading();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    for (var controller in _flipControllers) {
      controller.dispose();
    }
    super.dispose();
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

      // Navegar para a aba de leitura
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _randomSelectCards() {
    // Limpar seleção anterior
    _controller.resetReading();

    // Resetar estado das cartas
    _cardRevealed.value = [false, false, false];
    _readingPerformed.value = false;
    _allCardsRevealed.value = false;

    // Resetar animações
    for (var controller in _flipControllers) {
      controller.reset();
    }

    // Selecionar três cartas aleatórias
    final randomCards = _controller.getRandomCards(3);

    // Adicionar às cartas selecionadas
    for (var card in randomCards) {
      _controller.toggleCardSelection(card);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              floating: false,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Consulta de Tarô',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black54,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                background: _buildTarotHeader(),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Escolher Cartas'),
                  Tab(text: 'Leitura'),
                  Tab(text: 'Histórico'),
                ],
                onTap: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                labelStyle: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: isSmallScreen ? 12 : 14,
                ),
              ),
            ),
          ];
        },
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            _tabController.animateTo(index);
          },
          children: [
            _buildCardSelectionPage(isSmallScreen),
            _buildReadingPage(isSmallScreen),
            _buildHistoryPage(isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildTarotHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Efeito de partículas
          ...ZodiacUtils.buildStarParticles(context, 30),

          // Imagem de tarô com baixa opacidade
          Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.15,
              child: Transform.rotate(
                angle: -math.pi / 12,
                child: Icon(
                  Icons.auto_awesome,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Gradiente de sobreposição para legibilidade
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSelectionPage(bool isSmallScreen) {
    final padding = isSmallScreen ? 12.0 : 16.0;
    final titleSize = isSmallScreen ? 14.0 : 16.0;
    final subtitleSize = isSmallScreen ? 12.0 : 14.0;
    final cardAspectRatio = isSmallScreen ? 0.65 : 0.7;
    final crossAxisSpacing = isSmallScreen ? 8.0 : 12.0;
    final mainAxisSpacing = isSmallScreen ? 8.0 : 12.0;

    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.allCards.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Nenhuma carta disponível'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _controller.loadTarotCards(),
                child: const Text('Recarregar'),
              ),
            ],
          ),
        );
      }

      // Verificar se temos cartas aleatórias selecionadas
      final showRandomCards = _controller.selectedCards.isNotEmpty && !_readingPerformed.value;

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                Text(
                  showRandomCards
                      ? 'Toque nas cartas para revelá-las'
                      : 'Selecione até 3 cartas para sua leitura',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: titleSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  showRandomCards
                      ? 'Ou escolha cartas específicas abaixo'
                      : '${_controller.selectedCards.length}/3 cartas selecionadas',
                  style: TextStyle(
                    color: _controller.selectedCards.length == 3
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: _controller.selectedCards.length == 3
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: subtitleSize,
                  ),
                ),
              ],
            ),
          ),

          // Mostrar cartas viradas se temos seleção random
          if (showRandomCards) ...[
            Container(
              height: 200,
              padding: EdgeInsets.all(padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) {
                  return _buildFlippableCard(index, isSmallScreen);
                }),
              ),
            ),

            if (_allCardsRevealed.value)
              Padding(
                padding: EdgeInsets.all(padding),
                child: ElevatedButton.icon(
                  onPressed: _performReading,
                  icon: const Icon(Icons.psychology),
                  label: const Text('Interpretar Cartas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: const Duration(milliseconds: 500)),

            const Divider(height: 32),
          ],

          // Grid de seleção de cartas
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(padding),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 3 : 3,
                childAspectRatio: cardAspectRatio,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
              ),
              itemCount: _controller.allCards.length,
              itemBuilder: (context, index) {
                final card = _controller.allCards[index];
                return _buildTarotCard(card, isSmallScreen);
              },
            ),
          ),

          // Botões de ação
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller.selectedCards.isNotEmpty && !showRandomCards
                        ? () {
                      _controller.performReading();
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 15),
                    ),
                    child: Text(
                      'Realizar Leitura',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Escolher 3 cartas aleatórias
                    _randomSelectCards();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 12 : 15,
                      horizontal: isSmallScreen ? 12 : 16,
                    ),
                  ),
                  child: const Icon(Icons.shuffle),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFlippableCard(int index, bool isSmallScreen) {
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
              ..rotateY(math.pi * value),
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
      transform: Matrix4.rotationY(math.pi),
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
            Opacity(
              opacity: 0.2,
              child: CustomPaint(
                painter: TarotBackPatternPainter(),
              ),
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

  Widget _buildTarotCard(TarotCard card, bool isSmallScreen) {
    return Obx(() {
      final isSelected = _controller.selectedCards.contains(card);
      return GestureDetector(
        onTap: () => _controller.toggleCardSelection(card),
        child: Stack(
          children: [
            Card(
              elevation: isSelected ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: InkWell(
                onTap: () => Get.toNamed(
                  AppRoutes.cardDetails,
                  arguments: card.id,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: Image.network(
                          card.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 24,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: Text(
                        card.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: isSmallScreen ? 20 : 24,
                  height: isSmallScreen ? 20 : 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildReadingPage(bool isSmallScreen) {
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.selectedCards.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Selecione cartas para realizar uma leitura'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Selecionar Cartas'),
              ),
            ],
          ),
        );
      }

      if (_controller.interpretation.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Aguarde enquanto interpretamos suas cartas...'),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar as cartas selecionadas em row
            SizedBox(
              height: isSmallScreen ? 160 : 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _controller.selectedCards.length,
                itemBuilder: (context, index) {
                  final card = _controller.selectedCards[index];
                  return Container(
                    width: isSmallScreen ? 100 : 120,
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              card.imageUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.name,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                    delay: Duration(milliseconds: 200 * index),
                    duration: const Duration(milliseconds: 500),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Título da interpretação
            const Text(
              'Interpretação',
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
                  borderRadius: BorderRadius.circular(16),
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
                  child: ElevatedButton.icon(
                    onPressed: () => _controller.saveReading(),
                    icon: const Icon(Icons.save),
                    label: Text(
                      'Salvar Leitura',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Implementar compartilhamento
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Compartilhando leitura...'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: Text(
                      'Compartilhar',
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 12 : 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                _controller.resetReading();
                _randomSelectCards();
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Nova Leitura',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 16,
                ),
              ),
            ),
          ],
        ),
      );
    });
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: isSmallScreen ? 20 : 24,
      ),
    ),
    const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
      ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  content,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildHistoryPage(bool isSmallScreen) {
    // Widget para exibir o histórico de leituras de tarô
    final emptyIconSize = isSmallScreen ? 48.0 : 64.0;
    final titleSize = isSmallScreen ? 16.0 : 18.0;
    final subtitleSize = isSmallScreen ? 14.0 : 16.0;
    final buttonSize = isSmallScreen ? 14.0 : 16.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: emptyIconSize,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Histórico de leituras',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suas leituras salvas aparecerão aqui',
            style: TextStyle(
              fontSize: subtitleSize,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            icon: const Icon(Icons.add),
            label: Text(
              'Nova Leitura',
              style: TextStyle(fontSize: buttonSize),
            ),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 24,
                vertical: isSmallScreen ? 12 : 16,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 500));
  }
}

// Classe para pintar o fundo das cartas com um padrão esotérico elegante
class TarotBackPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.4;

    // Desenhar círculo central
    canvas.drawCircle(center, radius, paint);

    // Desenhar estrela dentro do círculo
    const points = 8;
    final path = Path();

    for (var i = 0; i < points; i++) {
      final angle = math.pi * 2 * i / points - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // Desenhar losango externo
    final diamondPath = Path();
    final diamondSize = math.min(size.width, size.height) * 0.8;

    diamondPath.moveTo(center.dx, center.dy - diamondSize / 2); // Topo
    diamondPath.lineTo(center.dx + diamondSize / 2, center.dy); // Direita
    diamondPath.lineTo(center.dx, center.dy + diamondSize / 2); // Baixo
    diamondPath.lineTo(center.dx - diamondSize / 2, center.dy); // Esquerda
    diamondPath.close();

    canvas.drawPath(diamondPath, paint);

    // Desenhar símbolos esotéricos nos cantos
    _drawCosmicSymbol(canvas, Offset(size.width * 0.2, size.height * 0.2), size.width * 0.06, paint);
    _drawCosmicSymbol(canvas, Offset(size.width * 0.8, size.height * 0.2), size.width * 0.06, paint);
    _drawCosmicSymbol(canvas, Offset(size.width * 0.2, size.height * 0.8), size.width * 0.06, paint);
    _drawCosmicSymbol(canvas, Offset(size.width * 0.8, size.height * 0.8), size.width * 0.06, paint);

    // Desenhar detalhes nas bordas
    final borderInset = size.width * 0.05;
    final borderRect = Rect.fromLTWH(
      borderInset,
      borderInset,
      size.width - (borderInset * 2),
      size.height - (borderInset * 2),
    );

    canvas.drawRect(borderRect, paint);
  }

  // Desenha um pequeno símbolo cósmico (estrela ou lua)
  void _drawCosmicSymbol(Canvas canvas, Offset center, double size, Paint paint) {
    // Estrela de cinco pontas
    const points = 5;
    final outerRadius = size;
    final innerRadius = size * 0.4;
    final path = Path();

    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = math.pi * i / points - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}