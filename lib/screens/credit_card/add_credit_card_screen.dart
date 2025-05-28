import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/controllers/new_credit_card_controller.dart';

class AddCreditCardScreen extends GetView<NewCreditCardController> {
  const AddCreditCardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Obter dimensões da tela para cálculos responsivos
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Cartão'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SafeArea(
        // Use GetX para apenas mostrar o loader quando necessário
        child: GetX<NewCreditCardController>(
          builder: (_) {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            return _buildBody(context, isSmallScreen);
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isSmallScreen) {
    return GestureDetector(
      // Quando o usuário tocar fora de um campo, remove o foco
      onTap: () => FocusScope.of(context).unfocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Determinar se estamos em um layout de tablet/desktop
          final isTablet = constraints.maxWidth > 600;

          // Calcular o padding horizontal baseado no tamanho da tela
          final horizontalPadding = isTablet ? 32.0 : 16.0;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Visualização do cartão
                  SizedBox(
                    height: isSmallScreen ? 170 : 200,
                    child: _buildCreditCardView(constraints),
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Formulário do cartão
                  _buildCardForm(context, isTablet, isSmallScreen),

                  SizedBox(height: isSmallScreen ? 16 : 24),

                  // Botão de salvar
                  _buildSaveButton(),

                  SizedBox(height: isSmallScreen ? 12 : 16),

                  // Texto de segurança
                  _buildSecurityText(),

                  // Espaço extra para evitar que o conteúdo fique coberto pelo teclado
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreditCardView(BoxConstraints constraints) {
    // Ajustar tamanho do cartão com base na largura da tela
    final cardWidth = constraints.maxWidth;
    final cardHeight = constraints.maxWidth > 600 ? 220.0 : 200.0;

    return GestureDetector(
      onTap: controller.flipCard,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: cardWidth,
          height: cardHeight,
          child: GetX<NewCreditCardController>(
            builder: (_) {
              return controller.showBackView.value
                  ? _buildCardBack()
                  : _buildCardFront();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCardFront() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Logo e bandeira
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Oraculum',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Use GetBuilder para atualizar somente quando a marca do cartão mudar
                GetBuilder<NewCreditCardController>(
                  id: 'cardBrand',
                  builder: (_) {
                    return _getBrandIcon(controller.cardBrand.value);
                  },
                ),
              ],
            ),

            // Número do cartão
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller.cardNumberController,
              builder: (context, value, child) {
                return Text(
                  value.text.isEmpty
                      ? '•••• •••• •••• ••••'
                      : value.text.padRight(19, '•'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),

            // Dados do titular e validade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TITULAR',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller.cardHolderController,
                        builder: (context, value, child) {
                          return Text(
                            value.text.isEmpty
                                ? 'NOME DO TITULAR'
                                : value.text.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VALIDADE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller.expiryDateController,
                        builder: (context, value, child) {
                          return Text(
                            value.text.isEmpty ? 'MM/AA' : value.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBack() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Faixa preta
            Container(
              height: 40,
              color: Colors.black87,
            ),
            const SizedBox(height: 20),

            // Área de assinatura e CVV
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    height: 40,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 40,
                    color: Colors.white,
                    alignment: Alignment.center,
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.cvvController,
                      builder: (context, value, child) {
                        return Text(
                          value.text.isEmpty ? '***' : value.text,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),
            // Bandeira
            Align(
              alignment: Alignment.centerRight,
              child: GetBuilder<NewCreditCardController>(
                id: 'cardBrand',
                builder: (_) {
                  return _getBrandIcon(controller.cardBrand.value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm(BuildContext context, bool isTablet, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Text(
          'Informações do Cartão',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Número do cartão
        _buildTextField(
          controller: controller.cardNumberController,
          label: 'Número do Cartão',
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          focusNode: controller.cardNumberFocus,
          nextFocusNode: controller.cardHolderFocus,
          inputFormatters: [controller.cardNumberFormatter],
          onChanged: (_) {
            // Forçar atualização da UI para mostrar a bandeira do cartão
            controller.update(['cardBrand']);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o número do cartão';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Número do cartão inválido';
            }
            return null;
          },
          suffixIcon: GetBuilder<NewCreditCardController>(
            id: 'cardBrand',
            builder: (_) {
              return controller.cardBrand.value.isNotEmpty
                  ? _getSuffixBrandIcon(controller.cardBrand.value)
                  : const SizedBox.shrink();
            },
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Nome do titular
        _buildTextField(
          controller: controller.cardHolderController,
          label: 'Nome do Titular',
          hint: 'Nome como está no cartão',
          icon: Icons.person,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          focusNode: controller.cardHolderFocus,
          nextFocusNode: controller.expiryDateFocus,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o nome do titular';
            }
            return null;
          },
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Layout adaptativo para validade e CVV
        if (isTablet)
        // Layout para tablets (lado a lado)
          Row(
            children: [
              // Validade
              Expanded(
                child: _buildExpiryField(isSmallScreen),
              ),
              const SizedBox(width: 16),
              // CVV
              Expanded(
                child: _buildCvvField(isSmallScreen),
              ),
            ],
          )
        else
        // Layout para celulares (empilhados)
          Column(
            children: [
              _buildExpiryField(isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildCvvField(isSmallScreen),
            ],
          ),

        SizedBox(height: isSmallScreen ? 20 : 24),

        // Título da seção de dados pessoais
        Text(
          'Dados do Titular',
          style: TextStyle(
            fontSize: isSmallScreen ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(height: isSmallScreen ? 12 : 16),

        // Layout adaptativo para CPF e telefone
        if (isTablet)
        // Layout para tablets (lado a lado)
          Row(
            children: [
              // CPF
              Expanded(
                child: _buildDocumentField(isSmallScreen),
              ),
              const SizedBox(width: 16),
              // Telefone
              Expanded(
                child: _buildPhoneField(isSmallScreen),
              ),
            ],
          )
        else
        // Layout para celulares (empilhados)
          Column(
            children: [
              _buildDocumentField(isSmallScreen),
              SizedBox(height: isSmallScreen ? 12 : 16),
              _buildPhoneField(isSmallScreen),
            ],
          ),
      ],
    );
  }

  Widget _buildExpiryField(bool isSmallScreen) {
    return _buildTextField(
      controller: controller.expiryDateController,
      label: 'Validade',
      hint: 'MM/AA',
      icon: Icons.calendar_today,
      keyboardType: TextInputType.number,
      focusNode: controller.expiryDateFocus,
      nextFocusNode: controller.cvvFocus,
      inputFormatters: [controller.expiryDateFormatter],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite a validade';
        }
        if (value.length < 5) {
          return 'Formato inválido';
        }

        // Verificar se a data é válida
        final parts = value.split('/');
        if (parts.length != 2) {
          return 'Formato inválido';
        }

        final month = int.tryParse(parts[0]);
        final year = int.tryParse('20${parts[1]}');

        if (month == null || year == null || month < 1 || month > 12) {
          return 'Data inválida';
        }

        // Verificar se o cartão já expirou
        final now = DateTime.now();
        final cardDate = DateTime(year, month);
        if (cardDate.isBefore(DateTime(now.year, now.month))) {
          return 'Cartão expirado';
        }

        return null;
      },
    );
  }

  Widget _buildCvvField(bool isSmallScreen) {
    return _buildTextField(
      controller: controller.cvvController,
      label: 'CVV',
      hint: '000',
      icon: Icons.security,
      keyboardType: TextInputType.number,
      focusNode: controller.cvvFocus,
      nextFocusNode: controller.documentFocus,
      inputFormatters: [controller.cvvFormatter],
      obscureText: true,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite o CVV';
        }
        if (value.length < 3) {
          return 'CVV inválido';
        }
        return null;
      },
    );
  }

  Widget _buildDocumentField(bool isSmallScreen) {
    return _buildTextField(
      controller: controller.documentController,
      label: 'CPF',
      hint: '000.000.000-00',
      icon: Icons.badge,
      keyboardType: TextInputType.number,
      focusNode: controller.documentFocus,
      nextFocusNode: controller.phoneFocus,
      inputFormatters: [controller.documentFormatter],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite o CPF';
        }
        if (value.replaceAll(RegExp(r'[.-]'), '').length < 11) {
          return 'CPF inválido';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField(bool isSmallScreen) {
    return _buildTextField(
      controller: controller.phoneController,
      label: 'Celular',
      hint: '(00) 00000-0000',
      icon: Icons.phone,
      keyboardType: TextInputType.number,
      focusNode: controller.phoneFocus,
      inputFormatters: [controller.phoneFormatter],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Digite o número de celular';
        }
        if (value.replaceAll(RegExp(r'[() -]'), '').length < 11) {
          return 'Número de celular inválido';
        }
        return null;
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        // Adiciona mensagem de erro de forma mais compacta
        errorStyle: const TextStyle(
          fontSize: 12,
          height: 0.8,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      focusNode: focusNode,
      onChanged: onChanged,
      onEditingComplete: () {
        if (nextFocusNode != null) {
          FocusScope.of(Get.context!).requestFocus(nextFocusNode);
        } else {
          FocusScope.of(Get.context!).unfocus();
        }
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _onSavePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Salvar Cartão',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _onSavePressed() {
    // Esconder o teclado ao pressionar o botão
    FocusScope.of(Get.context!).unfocus();

    // Tentar adicionar o cartão
    controller.addNewCard().then((success) {
      if (success) {
        // Cartão adicionado com sucesso, voltar para a tela anterior
        Get.back();
      }
    });
  }

  Widget _buildSecurityText() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            children: [
              WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Icon(
                    Icons.lock,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const TextSpan(
                text: 'Seus dados estão protegidos. Usamos criptografia de ponta a ponta e não armazenamos seus dados de cartão.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getBrandIcon(String cardBrand) {
    Widget icon;

    switch (cardBrand) {
      case 'visa':
        icon = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'VISA',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
        break;
      case 'mastercard':
        icon = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.amber,
              ),
              margin: const EdgeInsets.only(left: -5),
            ),
          ],
        );
        break;
      case 'amex':
        icon = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'AMEX',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        );
        break;
      case 'elo':
        icon = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'ELO',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
        break;
      default:
        icon = Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.credit_card,
            color: Colors.white,
            size: 24,
          ),
        );
        break;
    }

    return icon;
  }

  Widget _getSuffixBrandIcon(String cardBrand) {
    Widget icon;

    switch (cardBrand) {
      case 'visa':
        icon = Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            'VISA',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        break;
      case 'mastercard':
        icon = Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red,
                ),
              ),
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber,
                ),
                margin: const EdgeInsets.only(left: -3),
              ),
            ],
          ),
        );
        break;
      case 'amex':
        icon = Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            'AMEX',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        break;
      case 'elo':
        icon = Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            'ELO',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        break;
      default:
        icon = const SizedBox.shrink();
        break;
    }

    return icon;
  }
}