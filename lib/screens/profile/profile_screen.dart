import 'package:oraculum/config/routes.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
            return const Center(child: CircularProgressIndicator());
          }

          final user = _authController.userModel.value;
          if (user == null) {
            return const Center(
              child: Text('Não foi possível carregar os dados do usuário'),
            );
          }

          return Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24),
              _buildCreditsCard(),
              const SizedBox(height: 24),
              _buildMenuOptions(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    return Container(
      padding: const EdgeInsets.all(24),
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
                radius: 50,
                backgroundImage: user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: user.profileImageUrl == null || user.profileImageUrl!.isEmpty
                    ? Icon(
                  Icons.person,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Membro desde ${DateFormat.yMMMd().format(user.createdAt)}',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

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

  Widget _buildCreditsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seus Créditos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.credit_card,
                    color: Colors.white,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Obx(() => Text(
                'R\$ ${_paymentController.userCredits.value.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Get.toNamed(AppRoutes.paymentMethods),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF392F5A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text(
                      'Adicionar Créditos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOptions() {
    final menuItems = [
      {
        'title': 'Meus Agendamentos',
        'icon': Icons.calendar_today,
        'onTap': () {
          // Implementar navegação para agendamentos
        },
      },
      {
        'title': 'Leituras Favoritas',
        'icon': Icons.favorite,
        'onTap': () {
          // Implementar navegação para favoritos
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
        'onTap': () => Get.toNamed(AppRoutes.paymentMethods),
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
      itemCount: menuItems.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return ListTile(
          leading: Icon(
            item['icon'] as IconData,
            color: item['color'] as Color? ?? Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            item['title'] as String,
            style: TextStyle(
              color: item['color'] as Color? ?? Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
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