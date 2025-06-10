import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/tarot_controller.dart';

class TarotReadingStatsWidget extends StatelessWidget {
  const TarotReadingStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final TarotController controller = Get.find<TarotController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return FutureBuilder<Map<String, dynamic>>(
      future: controller.getReadingStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16.0 : 20.0,
              vertical: 8.0,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return _buildStatsCard(context, stats, isSmallScreen);
      },
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats, bool isSmallScreen) {
    final totalReadings = stats['totalReadings'] ?? 0;
    final freeReadings = stats['freeReadings'] ?? 0;
    final paidReadings = stats['paidReadings'] ?? 0;
    final totalSpent = stats['totalSpent'] ?? 0.0;
    final canReadFreeToday = stats['canReadFreeToday'] ?? false;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.0 : 20.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.analytics,
          color: Colors.white,
          size: isSmallScreen ? 20 : 24,
        ),
        title: Text(
          'Estatísticas de Leituras',
          style: TextStyle(
            color: Colors.white,
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Total: $totalReadings leituras',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: isSmallScreen ? 12 : 14,
          ),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.free_breakfast,
                        label: 'Gratuitas',
                        value: freeReadings.toString(),
                        color: Colors.green,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.account_balance_wallet,
                        label: 'Pagas',
                        value: paidReadings.toString(),
                        color: Colors.orange,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.monetization_on,
                        label: 'Total Gasto',
                        value: 'R\$ ${totalSpent.toStringAsFixed(0)}',
                        color: Colors.blue,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        icon: canReadFreeToday ? Icons.check_circle : Icons.cancel,
                        label: 'Hoje',
                        value: canReadFreeToday ? 'Disponível' : 'Usada',
                        color: canReadFreeToday ? Colors.green : Colors.red,
                        isSmallScreen: isSmallScreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isSmallScreen,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isSmallScreen ? 20 : 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: isSmallScreen ? 10 : 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Dialog para mostrar detalhes das estatísticas
class TarotStatsDetailDialog extends StatelessWidget {
  final Map<String, dynamic> stats;

  const TarotStatsDetailDialog({
    super.key,
    required this.stats,
  });

  static Future<void> show(BuildContext context, Map<String, dynamic> stats) {
    return showDialog(
      context: context,
      builder: (context) => TarotStatsDetailDialog(stats: stats),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalReadings = stats['totalReadings'] ?? 0;
    final freeReadings = stats['freeReadings'] ?? 0;
    final paidReadings = stats['paidReadings'] ?? 0;
    final totalDaysUsed = stats['totalDaysUsed'] ?? 0;
    final totalSpent = stats['totalSpent'] ?? 0.0;
    final todayUsed = stats['todayUsed'] ?? 0;
    final canReadFreeToday = stats['canReadFreeToday'] ?? false;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: const Color(0xFF2A2A40),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF6C63FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Estatísticas Detalhadas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Estatísticas gerais
            _buildDetailSection(
              title: 'Resumo Geral',
              items: [
                _buildDetailItem('Total de Leituras', totalReadings.toString(), Icons.book),
                _buildDetailItem('Dias Ativos', totalDaysUsed.toString(), Icons.calendar_today),
                _buildDetailItem('Média por Dia', totalDaysUsed > 0 ? (totalReadings / totalDaysUsed).toStringAsFixed(1) : '0', Icons.trending_up),
              ],
            ),

            const SizedBox(height: 20),

            // Estatísticas de pagamento
            _buildDetailSection(
              title: 'Financeiro',
              items: [
                _buildDetailItem('Leituras Gratuitas', freeReadings.toString(), Icons.free_breakfast, Colors.green),
                _buildDetailItem('Leituras Pagas', paidReadings.toString(), Icons.account_balance_wallet, Colors.orange),
                _buildDetailItem('Total Investido', 'R\$ ${totalSpent.toStringAsFixed(2)}', Icons.monetization_on, Colors.blue),
                _buildDetailItem('Economia', 'R\$ ${(freeReadings * 10.0).toStringAsFixed(2)}', Icons.savings, Colors.purple),
              ],
            ),

            const SizedBox(height: 20),

            // Status atual
            _buildDetailSection(
              title: 'Status Hoje',
              items: [
                _buildDetailItem('Leituras Hoje', todayUsed.toString(), Icons.today),
                _buildDetailItem(
                  'Status Gratuita',
                  canReadFreeToday ? 'Disponível' : 'Usada',
                  canReadFreeToday ? Icons.check_circle : Icons.cancel,
                  canReadFreeToday ? Colors.green : Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Botões de ação
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.toNamed('/payment-methods');
                    },
                    icon: const Icon(Icons.add_card),
                    label: const Text('Adicionar Créditos'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Get.toNamed('/tarot-reading');
                    },
                    icon: const Icon(Icons.psychology),
                    label: const Text('Nova Leitura'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
      String label,
      String value,
      IconData icon, [
        Color? color,
      ]) {
    final itemColor = color ?? Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: itemColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: itemColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}