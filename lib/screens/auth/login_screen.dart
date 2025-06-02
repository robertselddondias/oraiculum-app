import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String? _errorMessage;

  final AuthController _authController = Get.find<AuthController>();

  // Controladores de animação
  late AnimationController _starAnimationController;
  late AnimationController _mainAnimationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _starAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
    ));

    // Iniciar animações
    _mainAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _starAnimationController.dispose();
    _mainAnimationController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      await _authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      await _authController.signInWithGoogle();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360 || screenHeight < 600;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF392F5A),
              const Color(0xFF8C6BAE),
              const Color(0xFF6C63FF).withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Partículas de estrelas animadas
              AnimatedBuilder(
                animation: _starAnimationController,
                builder: (context, child) {
                  return Stack(
                    children: ZodiacUtils.buildStarParticles(
                        context,
                        40,
                        maxHeight: screenHeight
                    ),
                  );
                },
              ),

              // Elementos decorativos flutuantes
              Positioned(
                top: screenHeight * 0.1,
                right: -50,
                child: AnimatedBuilder(
                  animation: _starAnimationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _starAnimationController.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Positioned(
                bottom: screenHeight * 0.1,
                left: -30,
                child: AnimatedBuilder(
                  animation: _starAnimationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -_starAnimationController.value * 1.5 * 3.14159,
                      child: Icon(
                        Icons.auto_awesome,
                        size: 80,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    );
                  },
                ),
              ),

              // Conteúdo principal
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 20.0 : 32.0,
                    vertical: 24.0,
                  ),
                  child: AnimatedBuilder(
                    animation: _fadeInAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeInAnimation.value,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo e Título com efeito glassmorphism
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.nights_stay_rounded,
                                  size: isSmallScreen ? 40 : 48,
                                  color: Colors.white,
                                ),
                              ).animate()
                                  .scale(
                                duration: 800.ms,
                                curve: Curves.elasticOut,
                              )
                                  .then()
                                  .shimmer(
                                duration: 2000.ms,
                                color: Colors.white.withOpacity(0.5),
                              ),

                              const SizedBox(height: 16),

                              Text(
                                'Oraculum',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 28 : 32,
                                  letterSpacing: 1.2,
                                ),
                              ).animate().fadeIn(delay: 200.ms),

                              const SizedBox(height: 8),

                              Text(
                                'Conecte-se com o universo',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w300,
                                ),
                              ).animate().fadeIn(delay: 400.ms),
                            ],
                          ),
                        ).animate().fadeIn(duration: 600.ms).scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.0, 1.0),
                          duration: 800.ms,
                          curve: Curves.elasticOut,
                        ),

                        SizedBox(height: isSmallScreen ? 32 : 48),

                        // Formulário de Login com glassmorphism
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 28.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Título do formulário
                                Text(
                                  'Bem-vindo de volta',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallScreen ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ).animate().fadeIn(delay: 600.ms),

                                SizedBox(height: isSmallScreen ? 24 : 32),

                                // Botão de Login com Google
                                Obx(() => Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _authController.isLoading.value ? null : _loginWithGoogle,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_authController.isLoading.value)
                                              const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              )
                                            else
                                              Icon(
                                                Icons.login,
                                                size: 20,
                                                color: Colors.grey.shade700,
                                              ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Continuar com Google',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )).animate().fadeIn(delay: 800.ms).slideX(
                                  begin: -0.1,
                                  end: 0,
                                  duration: 500.ms,
                                  curve: Curves.easeOutQuart,
                                ),

                                SizedBox(height: isSmallScreen ? 20 : 24),

                                // Divisor "OU"
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OU',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(delay: 1000.ms),

                                SizedBox(height: isSmallScreen ? 20 : 24),

                                // Formulário de Email/Senha
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // Campo de email
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            labelStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            hintText: 'Digite seu email',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
                                            ),
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
                                      ).animate().fadeIn(delay: 1200.ms).slideX(
                                        begin: -0.1,
                                        end: 0,
                                        duration: 500.ms,
                                      ),

                                      const SizedBox(height: 16),

                                      // Campo de senha
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: TextFormField(
                                          controller: _passwordController,
                                          obscureText: !_isPasswordVisible,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            labelText: 'Senha',
                                            labelStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            prefixIcon: Icon(
                                              Icons.lock_outline,
                                              color: Colors.white.withOpacity(0.8),
                                            ),
                                            suffixIcon: IconButton(
                                              icon: Icon(
                                                _isPasswordVisible
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.white.withOpacity(0.8),
                                              ),
                                              onPressed: _togglePasswordVisibility,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                            hintText: 'Digite sua senha',
                                            hintStyle: TextStyle(
                                              color: Colors.white.withOpacity(0.6),
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
                                      ).animate().fadeIn(delay: 1400.ms).slideX(
                                        begin: -0.1,
                                        end: 0,
                                        duration: 500.ms,
                                      ),

                                      const SizedBox(height: 12),

                                      // Link "Esqueceu a senha?"
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            Get.toNamed(AppRoutes.forgotPassword);
                                          },
                                          child: Text(
                                            'Esqueceu a senha?',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ).animate().fadeIn(delay: 1500.ms),

                                      const SizedBox(height: 24),

                                      // Botão de login
                                      Obx(() => Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color(0xFF6C63FF),
                                              const Color(0xFF8E78FF),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF6C63FF).withOpacity(0.4),
                                              blurRadius: 12,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _authController.isLoading.value ? null : _login,
                                            borderRadius: BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              child: Center(
                                                child: _authController.isLoading.value
                                                    ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                )
                                                    : const Text(
                                                  'Entrar',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )).animate().fadeIn(delay: 1600.ms).slideY(
                                        begin: 0.1,
                                        end: 0,
                                        duration: 500.ms,
                                        curve: Curves.easeOutQuart,
                                      ),
                                    ],
                                  ),
                                ),

                                // Mensagem de erro
                                if (_errorMessage != null)
                                  Container(
                                    margin: const EdgeInsets.only(top: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.red.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red.shade300,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Colors.red.shade200,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ).animate().fadeIn().shake(),

                                SizedBox(height: isSmallScreen ? 24 : 32),

                                // Link para registro
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Não tem uma conta?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Get.toNamed(AppRoutes.register);
                                      },
                                      child: const Text(
                                        'Criar conta',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ).animate().fadeIn(delay: 1800.ms),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          duration: 800.ms,
                          curve: Curves.easeOutQuart,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}