import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/creditcard_controller.dart';

class CreditCardListScreen extends StatelessWidget {
  final CreditCardController controller = Get.find<CreditCardController>();

  CreditCardListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Cartões'),
        backgroundColor: Colors.deepPurple.shade800,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // Lista de cartões
            if (controller.savedCards.isEmpty)
              _buildEmptyState()
            else
              _buildCardsList(),

            // Botão de adicionar novo cartão
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/add-credit-card'),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar Novo Cartão'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade800,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum cartão cadastrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Adicione um cartão para realizar pagamentos de forma rápida e segura',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 100), // Espaço para o botão de adicionar
        ],
      ),
    );
  }

  Widget _buildCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Espaço para o botão de adicionar
      itemCount: controller.savedCards.length,
      itemBuilder: (context, index) {
        final card = controller.savedCards[index];
        final isDefault = card['isDefault'] == true;
        final brandName = card['brand'] ?? 'unknown';

        return Dismissible(
          key: Key(card['id']),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Confirmar exclusão'),
                  content: const Text('Tem certeza que deseja remover este cartão?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
          onDismissed: (direction) {
            controller.removeCard(card['id']);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: isDefault
                  ? BorderSide(color: Colors.deepPurple.shade200, width: 1.5)
                  : BorderSide.none,
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: _getBrandColor(brandName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.credit_card,
                  color: _getBrandColor(brandName),
                  size: 28,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    '•••• ${card['lastFourDigits']}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    brandName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (isDefault)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Padrão',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    card['cardHolder'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    'Validade: ${card['expiryMonth']}/${card['expiryYear']?.substring(2) ?? 'XX'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              trailing: !isDefault
                  ? IconButton(
                icon: Icon(Icons.star_outline, color: Colors.deepPurple.shade300),
                onPressed: () => controller.setDefaultCard(card['id']),
                tooltip: 'Definir como padrão',
              )
                  : Icon(Icons.star, color: Colors.deepPurple.shade300),
              onTap: () {
                // Mostrar opções do cartão
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => _buildCardOptionsSheet(context, card),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardOptionsSheet(BuildContext context, Map<String, dynamic> card) {
    final isDefault = card['isDefault'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cartão **** ${card['lastFourDigits']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (!isDefault)
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Definir como padrão'),
              onTap: () {
                Navigator.pop(context);
                controller.setDefaultCard(card['id']);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Remover cartão', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              Get.dialog(
                AlertDialog(
                  title: const Text('Confirmar exclusão'),
                  content: const Text('Tem certeza que deseja remover este cartão?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        controller.removeCard(card['id']);
                      },
                      child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                foregroundColor: Colors.black,
              ),
              child: const Text('Fechar'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Colors.blue;
      case 'mastercard':
        return Colors.red;
      case 'amex':
        return Colors.indigo;
      case 'elo':
        return Colors.green;
      case 'hipercard':
        return Colors.redAccent;
      case 'diners':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }
}