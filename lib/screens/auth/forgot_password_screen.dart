import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  final AuthController _authController = Get.find<AuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await _authController.sendPasswordResetEmail(_emailController.text.trim());
      setState(() {
        _emailSent = true;
      });
    } catch (e) {
      Get.snackbar(
        'Erro',
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
      appBar: AppBar(
        title: const Text('Recuperar Senha'),
      ),
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
                  // Ícone
                  Icon(
                    _emailSent ? Icons.check_circle : Icons.lock_reset,
                    size: 80,
                    color: Colors.white,
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .scale(delay: 300.ms),

                  const SizedBox(height: 24),

                  // Título
                  Text(
                    _emailSent ? 'Email Enviado!' : 'Recuperar Senha',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

                  const SizedBox(height: 16),

                  // Subtítulo
                  Text(
                    _emailSent
                        ? 'Verifique seu email para redefinir sua senha. Se não encontrar o email, verifique sua pasta de spam.'
                        : 'Informe seu email para receber um link de recuperação de senha.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms),

                  const SizedBox(height: 32),

                  if (!_emailSent)
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

                              const SizedBox(height: 24),

                              // Botão de enviar
                              Obx(() => ElevatedButton(
                                onPressed: _authController.isLoading.value ? null : _resetPassword,
                                child: _authController.isLoading.value
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                    : const Text('Enviar Email'),
                              )),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Link para voltar ao login
                  TextButton.icon(
                    onPressed: () {
                      Get.offNamed(AppRoutes.login);
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    label: const Text(
                      'Voltar para o Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}