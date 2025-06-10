import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/app_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlService {
  // URLs dos documentos legais (substitua pelas URLs reais)
  static const String termsOfServiceUrl = AppConstants.termsOfServiceUrl;
  static const String privacyPolicyUrl = AppConstants.privacyPolicyUrl;
  static const String supportUrl = 'https://oraculum-app.com/suporte';
  static const String websiteUrl = 'https://oraculum-app.com';

  /// Abrir URL externa
  static Future<void> openUrl(String url, {String? errorMessage}) async {
    try {
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Não foi possível abrir a URL: $url');
      }
    } catch (e) {
      debugPrint('Erro ao abrir URL: $e');
      Get.snackbar(
        'Erro',
        errorMessage ?? 'Não foi possível abrir o link. Verifique sua conexão.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Abrir termos de uso
  static Future<void> openTermsOfService() async {
    await openUrl(
      termsOfServiceUrl,
      errorMessage: 'Não foi possível abrir os Termos de Uso',
    );
  }

  /// Abrir política de privacidade
  static Future<void> openPrivacyPolicy() async {
    await openUrl(
      privacyPolicyUrl,
      errorMessage: 'Não foi possível abrir a Política de Privacidade',
    );
  }

  /// Abrir suporte
  static Future<void> openSupport() async {
    await openUrl(
      supportUrl,
      errorMessage: 'Não foi possível abrir o suporte',
    );
  }

  /// Abrir website
  static Future<void> openWebsite() async {
    await openUrl(
      websiteUrl,
      errorMessage: 'Não foi possível abrir o website',
    );
  }

  /// Mostrar diálogo com informações legais
  static void showLegalInfoDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Informações Legais',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegalItem(
              icon: Icons.description,
              title: 'Termos de Uso',
              subtitle: 'Condições de uso do aplicativo',
              onTap: openTermsOfService,
            ),
            const SizedBox(height: 12),
            _buildLegalItem(
              icon: Icons.privacy_tip,
              title: 'Política de Privacidade',
              subtitle: 'Como protegemos seus dados',
              onTap: openPrivacyPolicy,
            ),
            const SizedBox(height: 12),
            _buildLegalItem(
              icon: Icons.support_agent,
              title: 'Suporte',
              subtitle: 'Central de ajuda e contato',
              onTap: openSupport,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  static Widget _buildLegalItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}