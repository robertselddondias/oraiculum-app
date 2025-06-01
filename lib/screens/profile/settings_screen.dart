import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/settings_controller.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();

  // Criar e registrar o SettingsController
  late final SettingsController _settingsController;

  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializar SettingsController
    _settingsController = Get.put(SettingsController());
    _setupAnimations();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _topAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  // Função responsiva para obter dimensões
  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    return {
      'padding': isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0,
      'avatarSize': isTablet ? 70.0 : isSmallScreen ? 50.0 : 60.0,
      'titleSize': isTablet ? 28.0 : isSmallScreen ? 20.0 : 24.0,
      'subtitleSize': isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0,
      'bodySize': isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0,
      'captionSize': isTablet ? 14.0 : isSmallScreen ? 11.0 : 12.0,
      'cardPadding': isTablet ? 24.0 : isSmallScreen ? 16.0 : 20.0,
      'iconSize': isTablet ? 28.0 : isSmallScreen ? 20.0 : 24.0,
      'spacing': isTablet ? 24.0 : isSmallScreen ? 16.0 : 20.0,
      'sectionSpacing': isTablet ? 32.0 : isSmallScreen ? 20.0 : 24.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: const [
                  Color(0xFF392F5A),
                  Color(0xFF483D8B),
                  Color(0xFF8C6BAE),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Partículas/estrelas para o fundo
              ...ZodiacUtils.buildStarParticles(context, isTablet ? 35 : 25),

              Column(
                children: [
                  _buildAppBar(dimensions),
                  Expanded(
                    child: Obx(() {
                      if (_settingsController.isLoading.value) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.all(dimensions['padding']!),
                        child: Column(
                          children: [
                            _buildAccountSection(dimensions),
                            SizedBox(height: dimensions['sectionSpacing']!),
                            _buildPreferencesSection(dimensions),
                            SizedBox(height: dimensions['sectionSpacing']!),
                            _buildNotificationsSection(dimensions),
                            SizedBox(height: dimensions['sectionSpacing']!),
                            _buildAboutSection(dimensions),
                            SizedBox(height: dimensions['sectionSpacing']!),
                            _buildLogoutButton(dimensions),
                            SizedBox(height: dimensions['spacing']!),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(Map<String, double> dimensions) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions['padding']!,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: dimensions['iconSize']!,
            ),
            splashRadius: 24,
          ),
          Expanded(
            child: Text(
              'Configurações',
              style: TextStyle(
                color: Colors.white,
                fontSize: dimensions['titleSize']! - 4,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: dimensions['iconSize']! + 16), // Espaço para balancear
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildAccountSection(Map<String, double> dimensions) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Conta',
              icon: Icons.account_circle,
              color: const Color(0xFF6C63FF),
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']!),
            Obx(() => _buildProfileInfo(dimensions)),
            Divider(
              height: dimensions['spacing']! * 2,
              color: Colors.white24,
            ),
            _buildSettingItem(
              icon: Icons.lock_outline,
              title: 'Alterar Senha',
              subtitle: 'Mude sua senha de acesso',
              color: Colors.orange,
              onTap: _showChangePasswordDialog,
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']! / 2),
            _buildSettingItem(
              icon: Icons.receipt_long,
              title: 'Histórico de Pagamentos',
              subtitle: 'Veja suas transações',
              color: Colors.green,
              onTap: () => Get.toNamed(AppRoutes.paymentHistory),
              dimensions: dimensions,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: const Duration(milliseconds: 500),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required Map<String, double> dimensions,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(dimensions['spacing']! / 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: dimensions['iconSize']!,
          ),
        ),
        SizedBox(width: dimensions['spacing']! / 2),
        Text(
          title,
          style: TextStyle(
            fontSize: dimensions['subtitleSize']!,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfo(Map<String, double> dimensions) {
    final user = _authController.userModel.value;

    if (user == null) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    final userSign = ZodiacUtils.getZodiacSignFromDate(user.birthDate);
    final signColor = ZodiacUtils.getSignColor(userSign);

    return Container(
      padding: EdgeInsets.all(dimensions['spacing']!),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: signColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de fundo com cor do signo
                Container(
                  width: dimensions['avatarSize']! + 10,
                  height: dimensions['avatarSize']! + 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        signColor.withOpacity(0.3),
                        signColor.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                // Avatar principal
                CircleAvatar(
                  radius: dimensions['avatarSize']! / 2,
                  backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  backgroundColor: signColor.withOpacity(0.2),
                  child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                      ? Icon(
                    Icons.person,
                    size: dimensions['avatarSize']! / 2,
                    color: signColor,
                  )
                      : null,
                ),
                // Botão de editar foto
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(dimensions['spacing']! / 3),
                    decoration: BoxDecoration(
                      color: signColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      size: dimensions['captionSize']! + 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: dimensions['spacing']!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: dimensions['subtitleSize']!,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: dimensions['spacing']! / 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: dimensions['bodySize']!,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: dimensions['spacing']! / 2),
                Row(
                  children: [
                    ZodiacUtils.buildZodiacImage(
                      userSign,
                      size: dimensions['bodySize']!,
                    ),
                    SizedBox(width: dimensions['spacing']! / 3),
                    Text(
                      userSign,
                      style: TextStyle(
                        color: signColor,
                        fontSize: dimensions['captionSize']! + 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Colors.white.withOpacity(0.7),
              size: dimensions['bodySize']! + 2,
            ),
            onPressed: () {
              // TODO: Implementar edição de perfil
            },
            tooltip: 'Editar Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(Map<String, double> dimensions) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Preferências',
              icon: Icons.tune,
              color: Colors.purple,
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']!),
            Obx(() => _buildCustomSwitchTile(
              icon: _settingsController.isDarkMode.value ? Icons.dark_mode : Icons.light_mode,
              title: 'Modo Escuro',
              subtitle: 'Alternar entre tema claro e escuro',
              value: _settingsController.isDarkMode.value,
              color: _settingsController.isDarkMode.value ? Colors.indigo : Colors.amber,
              onChanged: (value) => _settingsController.toggleDarkMode(value),
              dimensions: dimensions,
            )),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 500),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildNotificationsSection(Map<String, double> dimensions) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Notificações',
              icon: Icons.notifications,
              color: Colors.orange,
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']!),
            Obx(() => _buildCustomSwitchTile(
              icon: Icons.notifications,
              title: 'Notificações Push',
              subtitle: 'Receber notificações no dispositivo',
              value: _settingsController.notificationsEnabled.value,
              color: Colors.blue,
              onChanged: (value) => _settingsController.toggleNotifications(value),
              dimensions: dimensions,
            )),
            SizedBox(height: dimensions['spacing']! / 2),
            Obx(() => _buildCustomSwitchTile(
              icon: Icons.email,
              title: 'Notificações por Email',
              subtitle: 'Receber notificações por email',
              value: _settingsController.emailNotifications.value,
              color: Colors.teal,
              onChanged: (value) => _settingsController.toggleEmailNotifications(value),
              dimensions: dimensions,
            )),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 500),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildAboutSection(Map<String, double> dimensions) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Sobre',
              icon: Icons.info,
              color: Colors.cyan,
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']!),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'Sobre o App',
              subtitle: 'Informações sobre o Oraculum',
              color: Colors.blue,
              onTap: _showAboutDialog,
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']! / 2),
            _buildSettingItem(
              icon: Icons.description_outlined,
              title: 'Termos de Uso',
              subtitle: 'Leia nossos termos',
              color: Colors.green,
              onTap: () {
                // TODO: Implementar visualização dos termos de uso
                Get.snackbar(
                  'Em breve',
                  'Funcionalidade será implementada em breve',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']! / 2),
            _buildSettingItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Política de Privacidade',
              subtitle: 'Como protegemos seus dados',
              color: Colors.orange,
              onTap: () {
                // TODO: Implementar visualização da política de privacidade
                Get.snackbar(
                  'Em breve',
                  'Funcionalidade será implementada em breve',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              dimensions: dimensions,
            ),
            SizedBox(height: dimensions['spacing']! / 2),
            _buildSettingItem(
              icon: Icons.star_outline,
              title: 'Avaliar o App',
              subtitle: 'Nos ajude com sua avaliação',
              color: Colors.amber,
              onTap: () {
                // TODO: Implementar avaliação do app
                Get.snackbar(
                  'Obrigado!',
                  'Em breve você poderá avaliar o app',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              dimensions: dimensions,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 600),
      duration: const Duration(milliseconds: 500),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildCustomSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
    required Map<String, double> dimensions,
  }) {
    return Container(
      padding: EdgeInsets.all(dimensions['spacing']! / 1.5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(dimensions['spacing']! / 2.5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: dimensions['bodySize']! + 2,
            ),
          ),
          SizedBox(width: dimensions['spacing']!),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dimensions['bodySize']!,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: dimensions['spacing']! / 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: dimensions['captionSize']! + 1,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required Map<String, double> dimensions,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(dimensions['spacing']! / 1.5),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(dimensions['spacing']! / 2.5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: dimensions['bodySize']! + 2,
              ),
            ),
            SizedBox(width: dimensions['spacing']!),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: dimensions['bodySize']!,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: dimensions['spacing']! / 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: dimensions['captionSize']! + 1,
                    ),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: dimensions['bodySize']!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(Map<String, double> dimensions) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _showLogoutDialog,
        icon: Icon(
          Icons.logout,
          size: dimensions['bodySize']! + 2,
        ),
        label: Text(
          'Sair da Conta',
          style: TextStyle(
            fontSize: dimensions['bodySize']!,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: dimensions['spacing']!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 800),
      duration: const Duration(milliseconds: 500),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 400),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Alterar Senha',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField(
                controller: currentPasswordController,
                label: 'Senha Atual',
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: newPasswordController,
                label: 'Nova Senha',
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(
                controller: confirmPasswordController,
                label: 'Confirmar Nova Senha',
                icon: Icons.lock_outline,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                Get.snackbar(
                  'Erro',
                  'As senhas não coincidem',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
                return;
              }

              try {
                // Reautenticar o usuário
                await _authController.reauthenticate(
                  _authController.currentUser.value!.email!,
                  currentPasswordController.text,
                );

                // Atualizar a senha
                await _authController.updatePassword(newPasswordController.text);

                Get.back();
                Get.snackbar(
                  'Sucesso',
                  'Senha alterada com sucesso',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              } catch (e) {
                Get.snackbar(
                  'Erro',
                  e.toString(),
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(
          icon,
          color: Colors.orange,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.orange,
            width: 2,
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFF6C63FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Oraculum',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6C63FF).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Color(0xFF6C63FF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Versão 1.0.0',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Oraculum é um aplicativo de astrologia, tarô e consultas com médiuns para ajudar você a se conectar com o universo.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '© 2025 Oraculum. Todos os direitos reservados.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sair da Conta',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja sair da sua conta? Você precisará fazer login novamente para acessar o app.',
          style: TextStyle(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _authController.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      try {
        _authController.isLoading.value = true;

        // Upload da imagem para o Firebase Storage
        final firebaseService = Get.find<FirebaseService>();
        final downloadUrl = await firebaseService.uploadProfileImage(
          _authController.currentUser.value!.uid,
          imageFile.path,
        );

        // Atualizar o perfil do usuário
        await _authController.updateUserProfile(photoURL: downloadUrl);

        Get.snackbar(
          'Sucesso',
          'Foto de perfil atualizada com sucesso',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Não foi possível atualizar a foto de perfil: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      } finally {
        _authController.isLoading.value = false;
      }
    }
  }
}