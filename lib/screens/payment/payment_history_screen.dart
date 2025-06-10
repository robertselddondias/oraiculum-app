import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new),
          tooltip: 'Voltar',
        ),
        title: Text(
          'Histórico de Pagamentos',
          style: TextStyle(
            fontSize: isTablet ? 22 : isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: !isTablet,
        elevation: isTablet ? 2 : 0,
        actions: [
          IconButton(
            onPressed: () => _controller.loadPaymentHistory(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                  strokeWidth: isTablet ? 4 : 2,
                ),
                SizedBox(height: isTablet ? 24 : 16),
                Text(
                  'Carregando histórico...',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        if (_controller.paymentHistory.isEmpty) {
          return _buildEmptyState(isSmallScreen, isTablet);
        }

        return _buildPaymentList(isSmallScreen, isTablet);
      }),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen, bool isTablet) {
    final iconSize = isTablet ? 100.0 : isSmallScreen ? 60.0 : 80.0;
    final titleSize = isTablet ? 22.0 : isSmallScreen ? 16.0 : 18.0;
    final subtitleSize = isTablet ? 16.0 : isSmallScreen ? 12.0 : 14.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: iconSize,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Text(
              'Nenhum pagamento encontrado',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Suas transações aparecerão aqui após realizarem pagamentos no app',
              style: TextStyle(
                color: Colors.grey,
                fontSize: subtitleSize,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 32 : 24),
            ElevatedButton.icon(
              onPressed: () => _controller.loadPaymentHistory(),
              icon: Icon(
                Icons.refresh,
                size: isTablet ? 24 : 20,
              ),
              label: Text(
                'Atualizar',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 32 : 24,
                  vertical: isTablet ? 16 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildPaymentList(bool isSmallScreen, bool isTablet) {
    final payments = _controller.paymentHistory;
    final padding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;

    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: payments.length + 1, // +1 para o cabeçalho
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryCard(isSmallScreen, isTablet);
        }

        final payment = payments[index - 1];
        return _buildPaymentCard(payment, index - 1, isSmallScreen, isTablet);
      },
    );
  }

  Widget _buildSummaryCard(bool isSmallScreen, bool isTablet) {
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

    final cardPadding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;
    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;
    final amountSize = isTablet ? 28.0 : isSmallScreen ? 20.0 : 24.0;
    final labelSize = isTablet ? 14.0 : isSmallScreen ? 11.0 : 12.0;
    final categorySize = isTablet ? 15.0 : isSmallScreen ? 12.0 : 14.0;

    return Card(
      elevation: isTablet ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo de Gastos',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            isTablet
                ? Row(
              children: [
                Expanded(child: _buildTotalColumn(totalSpent, amountSize, labelSize)),
                const SizedBox(width: 24),
                Expanded(child: _buildTransactionCountColumn(amountSize, labelSize)),
              ],
            )
                : Column(
              children: [
                _buildTotalColumn(totalSpent, amountSize, labelSize),
                const SizedBox(height: 16),
                _buildTransactionCountColumn(amountSize, labelSize),
              ],
            ),
            SizedBox(height: isTablet ? 20 : 16),
            const Divider(),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Gastos por Categoria',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: categorySize,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            ...spentByCategory.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _formatCategoryName(entry.key),
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: labelSize,
                      ),
                    ),
                  ),
                  Text(
                    currencyFormatter.format(entry.value),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: categorySize,
                    ),
                  ),
                ],
              ),
            )),

            if (_hasBirthChartPayments())
              Padding(
                padding: EdgeInsets.only(top: isTablet ? 20 : 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.public,
                      size: isTablet ? 20 : 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: isTablet ? 12 : 8),
                    Text(
                      'Mapas Astrais: ${_countBirthCharts()}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: categorySize,
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

  Widget _buildTotalColumn(double totalSpent, double amountSize, double labelSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Gasto',
          style: TextStyle(
            color: Colors.grey,
            fontSize: labelSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          currencyFormatter.format(totalSpent),
          style: TextStyle(
            fontSize: amountSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCountColumn(double amountSize, double labelSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total de Transações',
          style: TextStyle(
            color: Colors.grey,
            fontSize: labelSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_controller.paymentHistory.length}',
          style: TextStyle(
            fontSize: amountSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.secondaryColor,
          ),
        ),
      ],
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

  Widget _buildPaymentCard(Map<String, dynamic> payment, int index, bool isSmallScreen, bool isTablet) {
    final amount = payment['amount'] as double? ?? 0.0;
    final timestamp = payment['timestamp'] as DateTime? ?? DateTime.now();
    final method = payment['paymentMethod'] as String? ?? 'Desconhecido';
    final status = payment['status'] as String? ?? 'pending';
    final type = payment['serviceType'] as String? ?? 'outros';
    final description = payment['description'] as String? ?? 'Sem descrição';

    final cardPadding = isTablet ? 20.0 : isSmallScreen ? 12.0 : 16.0;
    final iconSize = isTablet ? 60.0 : isSmallScreen ? 40.0 : 50.0;
    final titleSize = isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0;
    final subtitleSize = isTablet ? 13.0 : isSmallScreen ? 10.0 : 12.0;
    final amountTextSize = isTablet ? 16.0 : isSmallScreen ? 14.0 : 15.0;

    return Card(
      elevation: isTablet ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      ),
      margin: EdgeInsets.only(top: isTablet ? 20 : 16),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment, isSmallScreen, isTablet),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIcon(type),
                      color: _getCategoryColor(type),
                      size: iconSize * 0.6,
                    ),
                  ),
                  SizedBox(width: isTablet ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          description,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: titleSize,
                          ),
                          maxLines: isTablet ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormatter.format(timestamp),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: subtitleSize,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: amountTextSize,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusChip(status, isSmallScreen, isTablet),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isTablet ? 16 : 12),
              const Divider(height: 1),
              SizedBox(height: isTablet ? 16 : 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Método: $method',
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                  Text(
                    'Ver detalhes ${isTablet ? '→' : '>'}',
                    style: TextStyle(
                      fontSize: subtitleSize,
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

  Widget _buildStatusChip(String status, bool isSmallScreen, bool isTablet) {
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

    final fontSize = isTablet ? 11.0 : isSmallScreen ? 9.0 : 10.0;
    final padding = isTablet
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment, bool isSmallScreen, bool isTablet) {
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

    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;
    final buttonPadding = isTablet
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 10);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        ),
        title: Text(
          'Detalhes do Pagamento',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: isTablet ? 500 : double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Descrição', description, isSmallScreen, isTablet),
                _buildDetailRow('Valor', currencyFormatter.format(amount), isSmallScreen, isTablet),
                _buildDetailRow('Data', dateFormatter.format(timestamp), isSmallScreen, isTablet),
                _buildDetailRow('Método', method, isSmallScreen, isTablet),
                _buildDetailRow('Tipo de Serviço', _formatCategoryName(type), isSmallScreen, isTablet),
                _buildDetailRow('Status', _getStatusText(status), isSmallScreen, isTablet),
                _buildDetailRow('ID da Transação', transactionId, isSmallScreen, isTablet),

                // Para cartão de crédito, mostrar últimos dígitos
                if (method.toLowerCase().contains('cartão') &&
                    payment.containsKey('cardLastFourDigits'))
                  _buildDetailRow('Cartão',
                      '**** **** **** ${payment['cardLastFourDigits']}', isSmallScreen, isTablet),

                if (isBirthChart) ...[
                  SizedBox(height: isTablet ? 20 : 16),
                  const Divider(),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'Mapa Astral',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'Este pagamento foi para a geração de um mapa astral completo.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ],

                if (isPix) ...[
                  SizedBox(height: isTablet ? 20 : 16),
                  const Divider(),
                  SizedBox(height: isTablet ? 12 : 8),
                  Text(
                    'Pagamento via PIX',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isTablet ? 12 : 8),
                  if (status.toLowerCase() == 'pending')
                    Text(
                      'Este pagamento está pendente de confirmação. Verifique se você completou a transação PIX.',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    )
                  else
                    Text(
                      'Pagamento realizado via PIX.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Fechar',
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ),
          if (hasQrCode)
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                Get.dialog(_buildQrCodePopup(pixQrCode, isSmallScreen, isTablet));
              },
              icon: Icon(
                Icons.qr_code,
                size: isTablet ? 20 : 16,
              ),
              label: Text(
                'Ver QR Code',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Ver Mapas Astrais',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
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
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Solicitar Suporte',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
        ],
        actionsPadding: EdgeInsets.all(isTablet ? 20 : 16),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isSmallScreen, bool isTablet) {
    final labelSize = isTablet ? 13.0 : isSmallScreen ? 11.0 : 12.0;
    final valueSize = isTablet ? 17.0 : isSmallScreen ? 14.0 : 16.0;

    return Padding(
      padding: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: labelSize,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueSize,
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar QR code do PIX
  Widget _buildQrCodePopup(String qrCode, bool isSmallScreen, bool isTablet) {
    final qrSize = isTablet ? 250.0 : isSmallScreen ? 180.0 : 200.0;
    final iconSize = qrSize * 0.75;
    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 24.0 : 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'QR Code PIX',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            // QR Code (simples representação visual)
            Container(
              width: qrSize,
              height: qrSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.qr_code_2,
                  size: iconSize,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            // Código PIX copia e cola
            Container(
              padding: EdgeInsets.all(isTablet ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      qrCode.length > 30 ? '${qrCode.substring(0, 30)}...' : qrCode,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isTablet ? 14 : 12,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.copy,
                      size: isTablet ? 24 : 20,
                    ),
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
            SizedBox(height: isTablet ? 20 : 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 16 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                  ),
                ),
              ),
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