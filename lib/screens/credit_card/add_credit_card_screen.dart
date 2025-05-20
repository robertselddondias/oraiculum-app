import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:math' as math;

import 'package:oraculum/controllers/creditcard_controller.dart';

class AddCreditCardScreen extends StatefulWidget {
  const AddCreditCardScreen({Key? key}) : super(key: key);

  @override
  State<AddCreditCardScreen> createState() => _NewCreditCardScreenState();
}

class _NewCreditCardScreenState extends State<AddCreditCardScreen> {
  // Controladores para os campos do formulário
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _documentController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final CreditCardController controller = Get.find<CreditCardController>();

  // Formatadores para os campos
  final cardNumberFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final expiryDateFormatter = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final cvvFormatter = MaskTextInputFormatter(
    mask: '###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final documentFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  final phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  // Focus nodes para controlar o foco dos campos
  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _cardHolderFocus = FocusNode();
  final FocusNode _expiryDateFocus = FocusNode();
  final FocusNode _cvvFocus = FocusNode();
  final FocusNode _documentFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  // Variáveis para controlar a animação do cartão
  bool _showBackView = false;
  String _cardBrand = '';

  // Chave para o formulário (validação)
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Estado de carregamento
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Adicionar listeners para os focus nodes
    _cvvFocus.addListener(_updateCardView);

    // Adicionar listener para detectar a bandeira do cartão
    _cardNumberController.addListener(_updateCardBrand);
  }

  @override
  void dispose() {
    // Liberar os controladores
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _documentController.dispose();
    _phoneController.dispose();

    // Liberar os focus nodes
    _cardNumberFocus.dispose();
    _cardHolderFocus.dispose();
    _expiryDateFocus.dispose();
    _cvvFocus.dispose();
    _documentFocus.dispose();
    _phoneFocus.dispose();

    super.dispose();
  }

  // Atualizar a visualização do cartão com base no foco
  void _updateCardView() {
    setState(() {
      _showBackView = _cvvFocus.hasFocus;
    });
  }

  // Detectar a bandeira do cartão
  void _updateCardBrand() {
    final cardNumber = _cardNumberController.text.replaceAll(' ', '');

    if (cardNumber.isEmpty) {
      setState(() {
        _cardBrand = '';
      });
      return;
    }

    if (cardNumber.startsWith('4')) {
      setState(() {
        _cardBrand = 'visa';
      });
    } else if ((cardNumber.startsWith('5') &&
        int.parse(cardNumber.substring(1, 2)) >= 1 &&
        int.parse(cardNumber.substring(1, 2)) <= 5) ||
        (cardNumber.length >= 4 &&
            int.parse(cardNumber.substring(0, 4)) >= 2221 &&
            int.parse(cardNumber.substring(0, 4)) <= 2720)) {
      setState(() {
        _cardBrand = 'mastercard';
      });
    } else if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
      setState(() {
        _cardBrand = 'amex';
      });
    } else if (cardNumber.startsWith('6')) {
      setState(() {
        _cardBrand = 'elo';
      });
    } else {
      setState(() {
        _cardBrand = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Cartão'),
        backgroundColor: Colors.deepPurple.shade800,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visualização do cartão
                _buildCreditCardView(),
                const SizedBox(height: 24),

                // Formulário
                _buildCardForm(),

                const SizedBox(height: 24),

                // Botão de salvar
                _buildSaveButton(),

                const SizedBox(height: 16),

                // Texto de segurança
                _buildSecurityText(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardView() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showBackView = !_showBackView;
        });
      },
      child: Container(
        height: 200,
        width: double.infinity,
        child: _showBackView ? _buildCardBack() : _buildCardFront(),
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade500,
            ],
          ),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _getBrandIcon(),
              ],
            ),

            // Número do cartão
            Text(
              _cardNumberController.text.isEmpty
                  ? '•••• •••• •••• ••••'
                  : _cardNumberController.text.padRight(19, '•'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),

            // Dados do titular e validade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                    Text(
                      _cardHolderController.text.isEmpty
                          ? 'NOME DO TITULAR'
                          : _cardHolderController.text.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
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
                    Text(
                      _expiryDateController.text.isEmpty
                          ? 'MM/AA'
                          : _expiryDateController.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade800,
              Colors.deepPurple.shade500,
            ],
          ),
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
                    child: Text(
                      _cvvController.text.isEmpty
                          ? '***'
                          : _cvvController.text,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),
            // Bandeira
            Align(
              alignment: Alignment.centerRight,
              child: _getBrandIcon(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção
        Text(
          'Informações do Cartão',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // Número do cartão
        _buildTextField(
          controller: _cardNumberController,
          label: 'Número do Cartão',
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          focusNode: _cardNumberFocus,
          nextFocusNode: _cardHolderFocus,
          inputFormatters: [cardNumberFormatter],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o número do cartão';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Número do cartão inválido';
            }
            return null;
          },
          suffixIcon: _cardBrand.isNotEmpty
              ? _getSuffixBrandIcon()
              : null,
        ),
        const SizedBox(height: 16),

        // Nome do titular
        _buildTextField(
          controller: _cardHolderController,
          label: 'Nome do Titular',
          hint: 'Nome como está no cartão',
          icon: Icons.person,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.words,
          focusNode: _cardHolderFocus,
          nextFocusNode: _expiryDateFocus,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o nome do titular';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Linha com validade e CVV
        Row(
          children: [
            // Validade
            Expanded(
              child: _buildTextField(
                controller: _expiryDateController,
                label: 'Validade',
                hint: 'MM/AA',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                focusNode: _expiryDateFocus,
                nextFocusNode: _cvvFocus,
                inputFormatters: [expiryDateFormatter],
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
              ),
            ),
            const SizedBox(width: 16),

            // CVV
            Expanded(
              child: _buildTextField(
                controller: _cvvController,
                label: 'CVV',
                hint: '000',
                icon: Icons.security,
                keyboardType: TextInputType.number,
                focusNode: _cvvFocus,
                nextFocusNode: _documentFocus,
                inputFormatters: [cvvFormatter],
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Título da seção de dados pessoais
        Text(
          'Dados do Titular',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade800,
          ),
        ),
        const SizedBox(height: 16),

        // CPF
        _buildTextField(
          controller: _documentController,
          label: 'CPF',
          hint: '000.000.000-00',
          icon: Icons.badge,
          keyboardType: TextInputType.number,
          focusNode: _documentFocus,
          nextFocusNode: _phoneFocus,
          inputFormatters: [documentFormatter],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o CPF';
            }
            if (value.replaceAll(RegExp(r'[.-]'), '').length < 11) {
              return 'CPF inválido';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),

        // Celular
        _buildTextField(
          controller: _phoneController,
          label: 'Celular',
          hint: '(00) 00000-0000',
          icon: Icons.phone,
          keyboardType: TextInputType.number,
          focusNode: _phoneFocus,
          inputFormatters: [phoneFormatter],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Digite o número de celular';
            }
            if (value.replaceAll(RegExp(r'[() -]'), '').length < 11) {
              return 'Número de celular inválido';
            }
            return null;
          },
        ),
      ],
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
          borderSide: BorderSide(color: Colors.deepPurple.shade800, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      validator: validator,
      focusNode: focusNode,
      onEditingComplete: () {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple.shade800,
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

  Widget _getBrandIcon() {
    Widget icon;

    switch (_cardBrand) {
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

  Widget _getSuffixBrandIcon() {
    Widget icon;

    switch (_cardBrand) {
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

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Mostrar diálogo de sucesso
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cartão Salvo'),
            content: const Text('Seu cartão foi adicionado com sucesso!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Fecha o diálogo
                  Get.back(); // Volta para a tela anterior
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }
}