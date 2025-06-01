import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 365 * 18)); // 18 anos por padrão

  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

    try {
      await _authController.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedDate,
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
                                labelText: 'Nome Completo',
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
                                labelText: 'Email',
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

                            // Campo de data de nascimento
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: AbsorbPointer(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Data de Nascimento',
                                    prefixIcon: Icon(Icons.calendar_today),
                                  ),
                                  controller: TextEditingController(
                                    text: DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, selecione sua data de nascimento';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Campo de senha
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              decoration: InputDecoration(
                                labelText: 'Senha',
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
                                labelText: 'Confirmar Senha',
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