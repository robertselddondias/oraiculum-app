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
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          _tabController.animateTo(index);
        },
        children: [
          _buildCardSelectionPage(),
          _buildReadingPage(),
          _buildHistoryPage(),
        ],
      ),
    );
  }

  Widget _buildCardSelectionPage() {
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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Selecione até 3 cartas para sua leitura',
              style: Theme.of(context).textTheme.titleMedium,
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
            ),
          )),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _controller.allCards.length,
              itemBuilder: (context, index) {
                final card = _controller.allCards[index];
                return _buildTarotCard(card);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                    child: const Text('Realizar Leitura'),
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

  Widget _buildTarotCard(TarotCard card) {
    return Obx(() {
      final isSelected = _controller.selectedCards.contains(card);
      return GestureDetector(
        onTap: () => _controller.toggleCardSelection(card),
        child: Stack(
          children: [
            Card(
              elevation: isSelected ? 8 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                          top: Radius.circular(10),
                        ),
                        child: Image.network(
                          card.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 32,
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
                        style: const TextStyle(
                          fontSize: 12,
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
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildReadingPage() {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar as cartas selecionadas em row
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _controller.selectedCards.length,
                itemBuilder: (context, index) {
                  final card = _controller.selectedCards[index];
                  return Container(
                    width: 120,
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
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
            const Text(
              'Interpretação',
              style: TextStyle(
                fontSize: 20,
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
                padding: const EdgeInsets.all(16),
                child: Text(
                  _controller.interpretation.value,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ).animate().fadeIn(
              delay: const Duration(milliseconds: 600),
              duration: const Duration(milliseconds: 500),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _controller.saveReading(),
                    icon: const Icon(Icons.save),
                    label: const Text('Salvar Leitura'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Implementar compartilhamento
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Compartilhar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
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
              label: const Text('Nova Leitura'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHistoryPage() {
    // Esta é uma implementação básica. Idealmente, carregaria o histórico de leituras do usuário.
    return const Center(
      child: Text('Histórico de leituras em implementação'),
    );
  }
}