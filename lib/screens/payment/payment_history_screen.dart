import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentController _controller = Get.find<PaymentController>();
  final DateFormat dateFormatter = DateFormat('dd/MM/yyyy HH:mm');
  final NumberFormat currencyFormatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _controller.loadPaymentHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Pagamentos'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_controller.paymentHistory.isEmpty) {
          return _buildEmptyState();
        }

        return _buildPaymentList();
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nenhum pagamento encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Suas transações aparecerão aqui',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _controller.loadPaymentHistory(),
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildPaymentList() {
    final payments = _controller.paymentHistory;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length + 1, // +1 para o cabeçalho
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryCard();
        }

        final payment = payments[index - 1];
        return _buildPaymentCard(payment, index - 1);
      },
    );
  }

  Widget _buildSummaryCard() {
    // Calcular totais
    double totalSpent = 0;
    Map<String, double> spentByCategory = {};

    for (final payment in _controller.paymentHistory) {
      final amount = payment['amount'] as double? ?? 0.0;
      final type = payment['serviceType'] as String? ?? 'outros';

      totalSpent += amount;

      if (spentByCategory.containsKey(type)) {
        spentByCategory[type] = (spentByCategory[type] ?? 0) + amount;
      } else {
        spentByCategory[type] = amount;
      }
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumo de Gastos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Gasto',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(totalSpent),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total de Transações',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${_controller.paymentHistory.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Gastos por Categoria',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...spentByCategory.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCategoryName(entry.key),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    currencyFormatter.format(entry.value),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )),

            if (_hasBirthChartPayments())
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.public,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mapas Astrais: ${_countBirthCharts()}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    );
  }

  bool _hasBirthChartPayments() {
    return _controller.paymentHistory.any((payment) =>
    (payment['serviceType'] as String? ?? '') == 'birthchart');
  }

  int _countBirthCharts() {
    return _controller.paymentHistory
        .where((payment) => (payment['serviceType'] as String? ?? '') == 'birthchart')
        .length;
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, int index) {
    final amount = payment['amount'] as double? ?? 0.0;
    final timestamp = payment['timestamp'] as DateTime? ?? DateTime.now();
    final method = payment['paymentMethod'] as String? ?? 'Desconhecido';
    final status = payment['status'] as String? ?? 'pending';
    final type = payment['serviceType'] as String? ?? 'outros';
    final description = payment['description'] as String? ?? 'Sem descrição';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.only(top: 16),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(type),
                      color: _getCategoryColor(type),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dateFormatter.format(timestamp),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusChip(status),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Método: $method',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Text(
                    'Ver detalhes >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        text = 'Aprovado';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Pendente';
        break;
      case 'canceled':
        color = Colors.red;
        text = 'Cancelado';
        break;
      case 'refunded':
        color = Colors.blue;
        text = 'Reembolsado';
        break;
      default:
        color = Colors.grey;
        text = 'Desconhecido';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final amount = payment['amount'] as double? ?? 0.0;
    final timestamp = payment['timestamp'] as DateTime? ?? DateTime.now();
    final method = payment['paymentMethod'] as String? ?? 'Desconhecido';
    final status = payment['status'] as String? ?? 'pending';
    final type = payment['serviceType'] as String? ?? 'outros';
    final description = payment['description'] as String? ?? 'Sem descrição';
    final paymentId = payment['paymentId'] as String? ?? '';

    // Verificar se é um pagamento PIX
    final isPix = method.toLowerCase() == 'pix';
    final pixQrCode = payment['pixQrCode'] as String?;  // Campo que armazenaria o QR code
    final hasQrCode = pixQrCode != null && pixQrCode.isNotEmpty;

    // Para mapas astrais, adicionar um botão para ver o mapa
    final isBirthChart = type == 'birthchart';

    // Verificar se tem ID de transação EFI
    final efiTxid = payment['efiTxid'] as String?;
    final efiChargeId = payment['efiChargeId'] as String?;
    final transactionId = efiTxid ?? efiChargeId ?? paymentId;

    Get.dialog(
      AlertDialog(
        title: const Text('Detalhes do Pagamento'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Descrição', description),
              _buildDetailRow('Valor', currencyFormatter.format(amount)),
              _buildDetailRow('Data', dateFormatter.format(timestamp)),
              _buildDetailRow('Método', method),
              _buildDetailRow('Tipo de Serviço', _formatCategoryName(type)),
              _buildDetailRow('Status', _getStatusText(status)),
              _buildDetailRow('ID da Transação', transactionId),

              // Para cartão de crédito, mostrar últimos dígitos
              if (method.toLowerCase().contains('cartão') &&
                  payment.containsKey('cardLastFourDigits'))
                _buildDetailRow('Cartão',
                    '**** **** **** ${payment['cardLastFourDigits']}'),

              if (isBirthChart) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Mapa Astral',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Este pagamento foi para a geração de um mapa astral completo.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],

              if (isPix) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Pagamento via PIX',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (status.toLowerCase() == 'pending')
                  const Text(
                    'Este pagamento está pendente de confirmação. Verifique se você completou a transação PIX.',
                    style: TextStyle(
                      color: Colors.orange,
                    ),
                  )
                else
                  const Text(
                    'Pagamento realizado via PIX.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar'),
          ),
          if (hasQrCode)
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.dialog(_buildQrCodePopup(pixQrCode));
              },
              icon: const Icon(Icons.qr_code),
              label: const Text('Ver QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          if (isBirthChart)
            ElevatedButton(
              onPressed: () {
                Get.back();
                // Navegar para a tela de mapas astrais
                Get.toNamed(AppRoutes.birthChart);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Ver Mapas Astrais'),
            ),
          if (status.toLowerCase() == 'approved')
            ElevatedButton(
              onPressed: () {
                // Implementar solicitação de reembolso ou suporte
                Get.back();
                Get.snackbar(
                  'Contato',
                  'Seu pedido de suporte foi enviado.',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Solicitar Suporte'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar QR code do PIX
  Widget _buildQrCodePopup(String qrCode) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'QR Code PIX',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // QR Code (simples representação visual)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(
                  Icons.qr_code_2,
                  size: 150,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Código PIX copia e cola
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      qrCode.length > 30 ? '${qrCode.substring(0, 30)}...' : qrCode,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Get.snackbar(
                        'Copiado',
                        'Código PIX copiado para a área de transferência',
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    switch (category.toLowerCase()) {
      case 'credits':
      case 'credit_purchase':
        return 'Compra de Créditos';
      case 'tarot':
        return 'Leitura de Tarô';
      case 'horoscope':
        return 'Horóscopo Personalizado';
      case 'birthchart':
        return 'Mapa Astral';
      case 'appointment':
        return 'Consulta com Médium';
      case 'pix':
        return 'Pagamento via PIX';
      default:
      // Capitalize a primeira letra
        if (category.isNotEmpty) {
          return category[0].toUpperCase() + category.substring(1);
        }
        return 'Outros';
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Aprovado';
      case 'pending':
        return 'Pendente';
      case 'canceled':
        return 'Cancelado';
      case 'refunded':
        return 'Reembolsado';
      default:
        return 'Desconhecido';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'credits':
      case 'credit_purchase':
        return Icons.credit_card;
      case 'tarot':
        return Icons.grid_view;
      case 'horoscope':
        return Icons.auto_graph;
      case 'birthchart':
        return Icons.public;
      case 'appointment':
        return Icons.people;
      case 'pix':
        return Icons.qr_code;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'credits':
      case 'credit_purchase':
        return Colors.green;
      case 'tarot':
        return Colors.purple;
      case 'horoscope':
        return Colors.blue;
      case 'birthchart':
        return Colors.orange;
      case 'appointment':
        return Colors.red;
      case 'pix':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }
}