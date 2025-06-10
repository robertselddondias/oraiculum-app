import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  DateTime? _selectedDate;
  String _selectedGender = '';

  final AuthController _authController = Get.find<AuthController>();

  // Lista de opções de gênero
  final List<Map<String, dynamic>> _genderOptions = [
    {
      'value': 'masculino',
      'label': 'Masculino',
      'icon': Icons.male,
    },
    {
      'value': 'feminino',
      'label': 'Feminino',
      'icon': Icons.female,
    },
    {
      'value': 'outros',
      'label': 'Outros',
      'icon': Icons.more_horiz,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  /// Valida e converte a data digitada
  DateTime? _parseDate(String dateString) {
    try {
      // Remove espaços e caracteres inválidos
      final cleanDate = dateString.replaceAll(RegExp(r'[^\d/]'), '');

      if (cleanDate.length != 10) return null; // DD/MM/AAAA deve ter 10 caracteres

      final parts = cleanDate.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;
      if (day < 1 || day > 31) return null;
      if (month < 1 || month > 12) return null;
      if (year < 1900 || year > DateTime.now().year) return null;

      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// Calcula a idade baseada na data
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      Get.snackbar(
        'Erro',
        'As senhas não coincidem',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Validar a data digitada
    final parsedDate = _parseDate(_birthDateController.text);
    if (parsedDate == null) {
      Get.snackbar(
        'Data inválida',
        'Por favor, digite uma data válida no formato DD/MM/AAAA',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        icon: const Icon(Icons.error, color: Colors.white),
      );
      return;
    }

    try {
      await _authController.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        parsedDate,
        _selectedGender, // Adicionar gênero
      );
    } catch (e) {
      Get.snackbar(
        'Erro no Registro',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gênero',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _genderOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedGender == option['value'];

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = option['value'];
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < _genderOptions.length - 1 ? 8 : 0,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          option['icon'],
                          size: 24,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(
                  delay: Duration(milliseconds: 100 * index),
                  duration: const Duration(milliseconds: 300),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF392F5A), Color(0xFF8C6BAE)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo e Título
                  const Icon(
                    Icons.nights_stay_rounded,
                    size: 70,
                    color: Colors.white,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(delay: 300.ms),

                  const SizedBox(height: 16),

                  Text(
                    'Criar Conta',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

                  const SizedBox(height: 8),

                  Text(
                    'Entre para a comunidade Oraculum',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms),

                  const SizedBox(height: 32),

                  // Formulário de Registro
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Campo de nome
                            TextFormField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              decoration: const InputDecoration(
                                labelText: 'Nome Completo *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite seu nome';
                                }
                                if (value.split(' ').length < 2) {
                                  return 'Por favor, digite seu nome completo';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Campo de email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite seu email';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Por favor, digite um email válido';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Campo de data de nascimento com máscara
                            TextFormField(
                              controller: _birthDateController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _DateInputFormatter(),
                              ],
                              decoration: const InputDecoration(
                                labelText: 'Data de Nascimento *',
                                prefixIcon: Icon(Icons.calendar_today),
                                hintText: 'DD/MM/AAAA',
                                helperText: 'Digite no formato DD/MM/AAAA',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Por favor, digite sua data de nascimento';
                                }

                                final parsedDate = _parseDate(value);
                                if (parsedDate == null) {
                                  return 'Data inválida. Use o formato DD/MM/AAAA';
                                }

                                // Verificar se a pessoa tem pelo menos 13 anos
                                final age = _calculateAge(parsedDate);
                                if (age < 13) {
                                  return 'Você deve ter pelo menos 13 anos';
                                }

                                if (age > 120) {
                                  return 'Data de nascimento parece incorreta';
                                }

                                // Atualizar a data selecionada se válida
                                _selectedDate = parsedDate;

                                return null;
                              },
                              onChanged: (value) {
                                // Atualizar _selectedDate em tempo real se a data for válida
                                final parsedDate = _parseDate(value);
                                if (parsedDate != null) {
                                  setState(() {
                                    _selectedDate = parsedDate;
                                  });
                                }
                              },
                            ),

                            const SizedBox(height: 24),

                            // Seletor de gênero
                            _buildGenderSelector(),

                            const SizedBox(height: 24),

                            // Campo de senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Senha *',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite sua senha';
                                }
                                if (value.length < 6) {
                                  return 'A senha deve ter pelo menos 6 caracteres';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Campo de confirmação de senha
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Confirmar Senha *',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: _toggleConfirmPasswordVisibility,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, confirme sua senha';
                                }
                                if (value != _passwordController.text) {
                                  return 'As senhas não coincidem';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Botão de registro
                            Obx(() => ElevatedButton(
                              onPressed: _authController.isLoading.value ? null : _register,
                              child: _authController.isLoading.value
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : const Text('Criar Conta'),
                            )),

                            const SizedBox(height: 16),

                            // Link para login
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Já tem uma conta?'),
                                TextButton(
                                  onPressed: () {
                                    Get.offNamed(AppRoutes.login);
                                  },
                                  child: const Text('Entrar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Formatador personalizado para entrada de data DD/MM/AAAA
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text;

    // Limitar a 8 dígitos (DDMMAAAA)
    if (text.length > 8) {
      return oldValue;
    }

    // Aplicar formatação conforme o usuário digita
    String formattedText = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) {
        formattedText += '/';
      }
      formattedText += text[i];
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}