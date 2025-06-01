import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/card_list_controller.dart';

class CreditCardListScreen extends GetView<CardListController> {
  const CreditCardListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dimensões da tela para responsividade
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Cartões'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Botão de atualizar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshCards(),
            tooltip: 'Atualizar cartões',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: controller.refreshCards,
          color: AppTheme.primaryColor,
          child: Obx(() {
            // Estado de carregamento inicial
            if (controller.isInitialLoading.value) {
              return _buildSkeletonLoading(isTablet);
            }

            // Estado de erro
            if (controller.errorMessage.value.isNotEmpty) {
              return _buildErrorState(controller.errorMessage.value);
            }

            // Lista vazia
            if (controller.savedCards.isEmpty) {
              return _buildEmptyState();
            }

            // Lista de cartões
            return _buildCardsList(isTablet);
          }),
        ),
      ),
      // Botão flutuante para adicionar novo cartão
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: controller.goToAddCard,
        child: const Icon(Icons.add),
      ),
      // Diálogo de confirmação de exclusão
      bottomSheet: Obx(() => controller.showDeleteConfirmation.value
          ? _buildDeleteConfirmation()
          : const SizedBox.shrink()),
    );
  }

  // Widget para exibir estado de carregamento com skeleton loading
  Widget _buildSkeletonLoading(bool isTablet) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
          vertical: 16,
          horizontal: isTablet ? 32 : 16
      ),
      itemCount: 3, // Exibir 3 skeletons
      itemBuilder: (_, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo e número
                Row(
                  children: [
                    // Logo do cartão (skeleton)
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Número do cartão (skeleton)
                    Container(
                      width: 150,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const Spacer(),
                    // Ícone de menu (skeleton)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Nome do titular (skeleton)
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(height: 8),
                // Validade (skeleton)
                Container(
                  width: 100,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para exibir estado de erro
  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Ops! Algo deu errado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: controller.refreshCards,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para exibir estado vazio (sem cartões)
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhum cartão cadastrado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Adicione um cartão para realizar pagamentos de forma rápida e segura.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: controller.goToAddCard,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Cartão'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para exibir a lista de cartões
  Widget _buildCardsList(bool isTablet) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          isTablet ? 32 : 16,
          16,
          isTablet ? 32 : 16,
          80 // Espaço para o botão flutuante
      ),
      itemCount: controller.savedCards.length,
      itemBuilder: (context, index) {
        final card = controller.savedCards[index];
        final brandName = card['brand'] ?? 'unknown';
        final isDefault = card['isDefault'] == true;
        final isExpired = controller.isCardExpired(card);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildCardItem(
            card: card,
            brandName: brandName,
            isDefault: isDefault,
            isExpired: isExpired,
            isTablet: isTablet,
          ),
        );
      },
    );
  }

  // Widget para item individual de cartão
  Widget _buildCardItem({
    required Map<String, dynamic> card,
    required String brandName,
    required bool isDefault,
    required bool isExpired,
    required bool isTablet,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isDefault
            ? const BorderSide(color: AppTheme.primaryColor, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showCardOptions(card),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha superior: Bandeira, número e ícone de opções
              Row(
                children: [
                  // Ícone da bandeira do cartão
                  Container(
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
                  const SizedBox(width: 12),

                  // Número do cartão e bandeira
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '•••• ${card['lastFourDigits']}',
                              style: TextStyle(
                                fontSize: isTablet ? 18 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Nome da bandeira
                            Text(
                              brandName.toUpperCase(),
                              style: TextStyle(
                                fontSize: isTablet ? 13 : 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        // Tags (padrão, expirado)
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: [
                            if (isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Padrão',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Expirado',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Ícone de menu
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showCardOptions(card),
                    splashRadius: 24,
                  ),
                ],
              ),

              // Linha inferior: Nome do titular e validade
              if (isTablet)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TITULAR',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card['cardHolder'] ?? 'Nome do Titular',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VALIDADE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${card['expiryMonth']}/${card['expiryYear']?.substring(2) ?? '**'}',
                            style: TextStyle(
                              fontSize: 15,
                              color: isExpired
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else
              // Versão mais compacta para celulares
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 2),
                  child: Text(
                    '${card['cardHolder']} • ${card['expiryMonth']}/${card['expiryYear']?.substring(2) ?? '**'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Diálogo de confirmação de exclusão
  Widget _buildDeleteConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Excluir cartão?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tem certeza de que deseja excluir este cartão? Esta ação não pode ser desfeita.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Botão Cancelar
              TextButton(
                onPressed: controller.cancelDelete,
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              // Botão Excluir
              ElevatedButton(
                onPressed: controller.confirmDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Excluir'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mostrar opções do cartão
  void _showCardOptions(Map<String, dynamic> card) {
    final isDefault = card['isDefault'] == true;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho do cartão
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Ícone e número
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getBrandColor(card['brand'] ?? 'unknown').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.credit_card,
                      color: _getBrandColor(card['brand'] ?? 'unknown'),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '•••• ${card['lastFourDigits']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        card['cardHolder'] ?? 'Nome do Titular',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 32),

            // Opções do cartão
            if (!isDefault)
              ListTile(
                leading: const Icon(
                  Icons.star_outline,
                  color: AppTheme.primaryColor,
                ),
                title: const Text('Definir como padrão'),
                onTap: () {
                  Get.back();
                  controller.setDefaultCard(card['id']);
                },
              ),

            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
              title: const Text('Remover cartão'),
              onTap: () {
                Get.back();
                controller.confirmDeleteCard(card['id']);
              },
            ),

            const SizedBox(height: 8),

            // Botão para fechar o menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Fechar'),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // Obter cor com base na bandeira do cartão
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