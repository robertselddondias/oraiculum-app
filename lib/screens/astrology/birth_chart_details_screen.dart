import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:share_plus/share_plus.dart';

class BirthChartDetailsScreen extends StatefulWidget {
  const BirthChartDetailsScreen({super.key});

  @override
  State<BirthChartDetailsScreen> createState() => _BirthChartDetailsScreenState();
}

class _BirthChartDetailsScreenState extends State<BirthChartDetailsScreen> {
  final HoroscopeController _controller = Get.find<HoroscopeController>();

  late Map<String, dynamic> chart;
  final RxMap<String, dynamic> _parsedInterpretation = <String, dynamic>{}.obs;
  final RxBool _isLoading = false.obs;

  @override
  void initState() {
    super.initState();

    // Obter dados do mapa astral passados como argumentos
    chart = Get.arguments as Map<String, dynamic>;
    _parseInterpretation();
  }

  void _parseInterpretation() {
    try {
      if (chart['interpretation'] != null && chart['interpretation'].isNotEmpty) {
        final interpretation = json.decode(chart['interpretation']);
        if (interpretation is Map<String, dynamic>) {
          _parsedInterpretation.value = interpretation;
        } else {
          _parsedInterpretation.value = {
            'geral': {
              'title': 'Interpretação do Mapa Astral',
              'body': chart['interpretation']
            }
          };
        }
      }
    } catch (e) {
      _parsedInterpretation.value = {
        'geral': {
          'title': 'Interpretação do Mapa Astral',
          'body': chart['interpretation'] ?? 'Interpretação não disponível'
        }
      };
    }
  }

  Future<void> _toggleFavorite() async {
    final currentFavorite = chart['isFavorite'] as bool;
    await _controller.toggleBirthChartFavorite(chart['id'], !currentFavorite);

    // Atualizar estado local
    setState(() {
      chart['isFavorite'] = !currentFavorite;
    });
  }

  void _shareChart() {
    final exportedText = _controller.exportBirthChartAsText(chart);
    SharePlus.instance.share(ShareParams(text: exportedText));
  }

  void _showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o mapa astral de "${chart['name']}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // Fechar dialog
              Get.back(); // Voltar para tela anterior
              await _controller.deleteBirthChart(chart['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF392F5A),
              Color(0xFF483D8B),
              Color(0xFF8C6BAE),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isSmallScreen, isTablet),
              Expanded(
                child: _buildContent(isSmallScreen, isTablet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isSmallScreen, bool isTablet) {
    final isFavorite = chart['isFavorite'] as bool;

    return Padding(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
            tooltip: 'Voltar',
          ),
          Expanded(
            child: Text(
              chart['name'] ?? 'Mapa Astral',
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: _toggleFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            tooltip: isFavorite ? 'Remover dos favoritos' : 'Adicionar aos favoritos',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'share':
                  _shareChart();
                  break;
                case 'delete':
                  _showDeleteConfirmation();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Compartilhar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildContent(bool isSmallScreen, bool isTablet) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPersonalInfo(isSmallScreen, isTablet),
            const SizedBox(height: 32),
            _buildInterpretationSections(isSmallScreen, isTablet),
            const SizedBox(height: 32),
            _buildActionButtons(isSmallScreen, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(bool isSmallScreen, bool isTablet) {
    final createdAt = chart['createdAt'] as DateTime;
    final summary = _controller.generateBirthChartSummary(chart);

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF392F5A).withOpacity(0.1),
            const Color(0xFF483D8B).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF392F5A).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF392F5A), Color(0xFF483D8B)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_circle,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informações Pessoais',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF392F5A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dados do mapa astral',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoGrid(summary, isSmallScreen),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: Color(0xFF483D8B),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gerado em ${DateFormat('dd/MM/yyyy \'às\' HH:mm').format(createdAt)}',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildInfoGrid(Map<String, dynamic> summary, bool isSmallScreen) {
    final items = [
      {
        'icon': Icons.person,
        'label': 'Nome',
        'value': summary['name'] ?? 'Não informado',
      },
      {
        'icon': Icons.cake,
        'label': 'Idade',
        'value': summary['age'] != null ? '${summary['age']} anos' : 'Não calculada',
      },
      {
        'icon': Icons.star,
        'label': 'Signo',
        'value': summary['zodiacSign'] ?? 'Não identificado',
      },
      {
        'icon': Icons.location_on,
        'label': 'Local',
        'value': summary['birthPlace'] ?? 'Não informado',
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Data',
        'value': chart['birthDate'] ?? 'Não informada',
      },
      {
        'icon': Icons.access_time,
        'label': 'Horário',
        'value': chart['birthTime'] ?? 'Não informado',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 1 : 2,
        childAspectRatio: isSmallScreen ? 6 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                item['icon'] as IconData,
                size: 18,
                color: const Color(0xFF483D8B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      item['value'] as String,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInterpretationSections(bool isSmallScreen, bool isTablet) {
    return Obx(() {
      if (_parsedInterpretation.isEmpty) {
        return const Center(
          child: Text('Interpretação não disponível'),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interpretação do Mapa Astral',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF392F5A),
            ),
          ),
          const SizedBox(height: 20),
          ..._buildInterpretationCards(isSmallScreen),
        ],
      );
    });
  }

  List<Widget> _buildInterpretationCards(bool isSmallScreen) {
    final cards = <Widget>[];
    int index = 0;

    _parsedInterpretation.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        cards.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getSectionColor(key).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getSectionIcon(key),
                            color: _getSectionColor(key),
                            size: isSmallScreen ? 20 : 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            value['title'] ?? key,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: _getSectionColor(key),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      value['body'] ?? '',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        height: 1.6,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate(delay: Duration(milliseconds: 200 * index))
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.1, end: 0),
        );
        index++;
      }
    });

    return cards;
  }

  IconData _getSectionIcon(String key) {
    switch (key.toLowerCase()) {
      case 'geral':
      case 'visao_geral':
        return Icons.auto_awesome;
      case 'sol':
        return Icons.wb_sunny;
      case 'lua':
        return Icons.nightlight_round;
      case 'ascendente':
        return Icons.trending_up;
      case 'planetas':
        return Icons.public;
      case 'casas':
        return Icons.home;
      case 'aspectos':
        return Icons.timeline;
      case 'conclusao':
        return Icons.check_circle;
      default:
        return Icons.star;
    }
  }

  Color _getSectionColor(String key) {
    switch (key.toLowerCase()) {
      case 'geral':
      case 'visao_geral':
        return const Color(0xFF392F5A);
      case 'sol':
        return Colors.orange;
      case 'lua':
        return Colors.indigo;
      case 'ascendente':
        return Colors.green;
      case 'planetas':
        return Colors.purple;
      case 'casas':
        return Colors.blue;
      case 'aspectos':
        return Colors.teal;
      case 'conclusao':
        return Colors.deepPurple;
      default:
        return const Color(0xFF483D8B);
    }
  }

  Widget _buildActionButtons(bool isSmallScreen, bool isTablet) {
    final isFavorite = chart['isFavorite'] as bool;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareChart,
                icon: const Icon(Icons.share),
                label: const Text('Compartilhar'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  side: const BorderSide(color: Color(0xFF392F5A)),
                  foregroundColor: const Color(0xFF392F5A),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _toggleFavorite,
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                label: Text(isFavorite ? 'Favorito' : 'Favoritar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFavorite ? Colors.red : const Color(0xFF392F5A),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _showDeleteConfirmation,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Excluir Mapa Astral',
              style: TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                vertical: isSmallScreen ? 12 : 16,
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 600),
      duration: const Duration(milliseconds: 400),
    );
  }
}