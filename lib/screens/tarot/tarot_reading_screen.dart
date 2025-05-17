import 'package:oraculum/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/tarot_controller.dart';
import 'package:oraculum/models/tarot_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TarotReadingScreen extends StatefulWidget {
  const TarotReadingScreen({Key? key}) : super(key: key);

  @override
  State<TarotReadingScreen> createState() => _TarotReadingScreenState();
}

class _TarotReadingScreenState extends State<TarotReadingScreen> with SingleTickerProviderStateMixin {
  final TarotController _controller = Get.find<TarotController>();
  late TabController _tabController;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller.resetReading();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarô'),
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

      return Column(
        children: [
          Padding(
            padding: EdgeInsets.all(padding),
            child: Text(
              'Selecione até 3 cartas para sua leitura',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: titleSize,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Obx(() => Text(
            '${_controller.selectedCards.length}/3 cartas selecionadas',
            style: TextStyle(
              color: _controller.selectedCards.length == 3
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: _controller.selectedCards.length == 3
                  ? FontWeight.bold
                  : FontWeight.normal,
              fontSize: subtitleSize,
            ),
          )),
          const SizedBox(height: 12),
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
          Padding(
            padding: EdgeInsets.all(padding),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _controller.selectedCards.isNotEmpty
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
                    _controller.resetReading();
                    final randomCards = _controller.getRandomCards(3);
                    for (var card in randomCards) {
                      _controller.toggleCardSelection(card);
                    }
                    _controller.performReading();
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
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

  Widget _buildTarotCard(TarotCard card, bool isSmallScreen) {
    final textSize = isSmallScreen ? 10.0 : 12.0;
    final cardPadding = isSmallScreen ? 4.0 : 8.0;
    final checkIconSize = isSmallScreen ? 14.0 : 16.0;
    final checkCircleSize = isSmallScreen ? 20.0 : 24.0;

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
                      padding: EdgeInsets.symmetric(
                        vertical: cardPadding,
                        horizontal: cardPadding / 2,
                      ),
                      child: Text(
                        card.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: textSize,
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
                  width: checkCircleSize,
                  height: checkCircleSize,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: checkIconSize,
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
    final titleSize = isSmallScreen ? 18.0 : 20.0;
    final contentSize = isSmallScreen ? 14.0 : 16.0;
    final cardWidth = isSmallScreen ? 100.0 : 120.0;
    final cardTextSize = isSmallScreen ? 12.0 : 14.0;
    final buttonSize = isSmallScreen ? 14.0 : 16.0;

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
                    width: cardWidth,
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
                            fontSize: cardTextSize,
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
            Text(
              'Interpretação',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Text(
                  _controller.interpretation.value,
                  style: TextStyle(
                    fontSize: contentSize,
                    height: 1.5,
                  ),
                ),
              ),
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 500),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _controller.saveReading(),
                    icon: const Icon(Icons.save),
                    label: Text(
                      'Salvar Leitura',
                      style: TextStyle(fontSize: buttonSize),
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
                      style: TextStyle(fontSize: buttonSize),
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
                _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                'Nova Leitura',
                style: TextStyle(fontSize: buttonSize),
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

  Widget _buildHistoryPage(bool isSmallScreen) {
    // Implementação responsiva para o histórico de leituras
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