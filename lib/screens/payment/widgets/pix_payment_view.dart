import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:oraculum/config/theme.dart';

class PixPaymentView extends StatelessWidget {
  final String pixQrCode;
  final String? pixTransactionId;
  final VoidCallback onBack;
  final VoidCallback onCheckStatus;
  final bool isLoading;
  final bool isSmallScreen;
  final bool isTablet;

  const PixPaymentView({
    Key? key,
    required this.pixQrCode,
    required this.pixTransactionId,
    required this.onBack,
    required this.onCheckStatus,
    required this.isLoading,
    required this.isSmallScreen,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isTablet ? 32 : 20),
      child: Column(
        children: [
          const SizedBox(height: 20),

          Icon(
            Icons.qr_code_2,
            size: isTablet ? 80 : 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: isTablet ? 20 : 16),

          Text(
            'Pagamento via PIX',
            style: TextStyle(
              fontSize: isTablet ? 28 : isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Escaneie o QR Code abaixo para completar o pagamento',
            style: TextStyle(
              fontSize: isTablet ? 18 : 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isTablet ? 40 : 32),

          Container(
            padding: EdgeInsets.all(isTablet ? 32 : 20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: pixQrCode,
              version: QrVersions.auto,
              size: isTablet ? 300 : isSmallScreen ? 200 : 250,
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),

          SizedBox(height: isTablet ? 40 : 32),

          Container(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: isTablet ? 28 : 24,
                ),
                const SizedBox(height: 8),
                Text(
                  'Como pagar com PIX',
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Abra o app do seu banco\n'
                      '2. Escolha a opção PIX\n'
                      '3. Escaneie o QR Code acima\n'
                      '4. Confirme o pagamento\n'
                      '5. Seus créditos serão adicionados automaticamente',
                  style: TextStyle(
                    fontSize: isTablet ? 16 : 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),

          SizedBox(height: isTablet ? 32 : 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Voltar',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : onCheckStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'Verificar Pagamento',
                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}