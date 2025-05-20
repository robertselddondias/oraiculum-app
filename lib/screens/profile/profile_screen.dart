import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:oraculum/services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthController _authController = Get.find<AuthController>();
  final PaymentController _paymentController = Get.find<PaymentController>();

  @override
  void initState() {
    super.initState();
    _paymentController.loadUserCredits();
  }

  @override
  Widget build(BuildContext context) {
    // Obter dimensões da tela para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final padding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed(AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Obx(() {
          if (_authController.isLoading.value) {
            return SizedBox(
              height: MediaQuery.of(context).size.height - 100,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final user = _authController.userModel.value;
          if (user == null) {
            return SizedBox(
              height: MediaQuery.of(context).size.height - 100,
              child: const Center(
                child: Text('Não foi possível carregar os dados do usuário'),
              ),
            );
          }

          return Column(
            children: [
              _buildProfileHeader(user, isSmallScreen),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: _buildCreditsCard(isSmallScreen),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _buildMenuOptions(isSmallScreen, padding),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfileHeader(user, bool isSmallScreen) {
    final avatarSize = isSmallScreen ? 40.0 : 50.0;
    final titleSize = isSmallScreen ? 20.0 : 24.0;
    final subtitleSize = isSmallScreen ? 14.0 : 16.0;
    final captionSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen ? 16.0 : 24.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: avatarSize,
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                    ? Icon(
                  Icons.person,
                  size: avatarSize,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
              ),
              CircleAvatar(
                radius: isSmallScreen ? 14 : 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: Icon(
                    Icons.camera_alt,
                    size: isSmallScreen ? 12 : 16,
                    color: Colors.white,
                  ),
                  onPressed: _pickImage,
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: subtitleSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Membro desde ${DateFormat.yMMMd().format(user.createdAt)}',
            style: TextStyle(
              fontSize: captionSize,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
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
        );
      } catch (e) {
        Get.snackbar(
          'Erro',
          'Não foi possível atualizar a foto de perfil: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } finally {
        _authController.isLoading.value = false;
      }
    }
  }

  Widget _buildCreditsCard(bool isSmallScreen) {
    final titleSize = isSmallScreen ? 14.0 : 16.0;
    final amountSize = isSmallScreen ? 24.0 : 28.0;
    final buttonSize = isSmallScreen ? 14.0 : 16.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seus Créditos',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: titleSize,
                  ),
                ),
                const Icon(
                  Icons.credit_card,
                  color: Colors.white,
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 16 : 20),
            Obx(() => Text(
              'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
              style: TextStyle(
                color: Colors.white,
                fontSize: amountSize,
                fontWeight: FontWeight.bold,
              ),
            )),
            SizedBox(height: isSmallScreen ? 16 : 20),
            ElevatedButton(
              onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF392F5A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 10 : 12,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 8),
                  Text(
                    'Adicionar Créditos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: buttonSize,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOptions(bool isSmallScreen, double padding) {
    final iconSize = isSmallScreen ? 20.0 : 24.0;
    final textSize = isSmallScreen ? 14.0 : 16.0;

    final menuItems = [
      {
        'title': 'Meus Agendamentos',
        'icon': Icons.calendar_today,
        'onTap': () {
          // Implementar navegação para agendamentos
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navegando para agendamentos...')),
          );
        },
      },
      {
        'title': 'Leituras Favoritas',
        'icon': Icons.favorite,
        'onTap': () {
          // Implementar navegação para favoritos
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navegando para favoritos...')),
          );
        },
      },
      {
        'title': 'Histórico de Pagamentos',
        'icon': Icons.receipt_long,
        'onTap': () => Get.toNamed(AppRoutes.paymentHistory),
      },
      {
        'title': 'Métodos de Pagamento',
        'icon': Icons.payment,
        'onTap': () => Get.toNamed(AppRoutes.creditcardList),
      },
      {
        'title': 'Configurações',
        'icon': Icons.settings,
        'onTap': () => Get.toNamed(AppRoutes.settings),
      },
      {
        'title': 'Sair',
        'icon': Icons.exit_to_app,
        'onTap': _logout,
        'color': Theme.of(context).colorScheme.error,
      },
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: padding),
      itemCount: menuItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: padding,
            vertical: isSmallScreen ? 2 : 4,
          ),
          leading: Icon(
            item['icon'] as IconData,
            color: item['color'] as Color? ?? Theme.of(context).colorScheme.primary,
            size: iconSize,
          ),
          title: Text(
            item['title'] as String,
            style: TextStyle(
              color: item['color'] as Color? ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: textSize,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: item['onTap'] as VoidCallback,
        );
      },
    );
  }

  void _logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Sair'),
        content: const Text('Você realmente deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authController.signOut();
    }
  }
}