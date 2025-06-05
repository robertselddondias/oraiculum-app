import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/utils/responsive_helper.dart';
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
    // AQUI É A MAGIA! Uma linha para obter todas as dimensões responsivas
    final responsive = context.responsive;

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
                        responsive.isTablet ? 50 : 40,
                        maxHeight: responsive.screenHeight
                    ),
                  );
                },
              ),

              // Elementos decorativos responsivos
              Positioned(
                top: responsive.screenHeight * 0.1,
                right: -50,
                child: AnimatedBuilder(
                  animation: _starAnimationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _starAnimationController.value * 2 * 3.14159,
                      child: Container(
                        width: responsive.isTablet ? 150 : 120,
                        height: responsive.isTablet ? 150 : 120,
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

              // Conteúdo principal
              Center(
                child: SingleChildScrollView(
                  padding: ResponsiveSpacing.screen(context),
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
                        // Logo e Título com responsividade automática
                        ResponsiveComponents.card(
                          context,
                          color: Colors.white.withOpacity(0.1),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(responsive.cardPadding * 0.8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.nights_stay_rounded,
                                  size: responsive.iconSize * 2,
                                  color: Colors.white,
                                ),
                              ).animate()
                                  .scale(
                                duration: 800.ms,
                                curve: Curves.elasticOut,
                              ),

                              ResponsiveSpacing.vertical(context, multiplier: 0.8),

                              Text(
                                'Oraculum',
                                style: ResponsiveText.title(
                                  context,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ).animate().fadeIn(delay: 200.ms),

                              ResponsiveSpacing.vertical(context, multiplier: 0.4),

                              Text(
                                'Conecte-se com o universo',
                                style: ResponsiveText.body(
                                  context,
                                  color: Colors.white.withOpacity(0.8),
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

                        ResponsiveSpacing.vertical(context, multiplier: 2),

                        // Formulário responsivo
                        ResponsiveComponents.card(
                          context,
                          color: Colors.white.withOpacity(0.1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Título do formulário
                              Text(
                                'Bem-vindo de volta',
                                style: ResponsiveText.subtitle(
                                  context,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ).animate().fadeIn(delay: 600.ms),

                              ResponsiveSpacing.vertical(context, multiplier: 1.5),

                              // Botão Google responsivo
                              Obx(() => _buildGoogleButton()),

                              ResponsiveSpacing.vertical(context),

                              // Divisor "OU"
                              _buildDivider(),

                              ResponsiveSpacing.vertical(context),

                              // Formulário de Email/Senha
                              Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Campo de email responsivo
                                    _buildEmailField(),

                                    ResponsiveSpacing.vertical(context, multiplier: 0.8),

                                    // Campo de senha responsivo
                                    _buildPasswordField(),

                                    ResponsiveSpacing.vertical(context, multiplier: 0.6),

                                    // Link "Esqueceu a senha?" responsivo
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: () {
                                          Get.toNamed(AppRoutes.forgotPassword);
                                        },
                                        child: Text(
                                          'Esqueceu a senha?',
                                          style: ResponsiveText.body(
                                            context,
                                            color: Colors.white.withOpacity(0.9),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ).animate().fadeIn(delay: 1500.ms),

                                    ResponsiveSpacing.vertical(context),

                                    // Botão de login responsivo
                                    Obx(() => ResponsiveComponents.button(
                                      context,
                                      text: 'Entrar',
                                      onPressed: _authController.isLoading.value ? null : _login,
                                      isLoading: _authController.isLoading.value,
                                      backgroundColor: const Color(0xFF6C63FF),
                                      textColor: Colors.white,
                                    )).animate().fadeIn(delay: 1600.ms).slideY(
                                      begin: 0.1,
                                      end: 0,
                                      duration: 500.ms,
                                      curve: Curves.easeOutQuart,
                                    ),
                                  ],
                                ),
                              ),

                              // Mensagem de erro responsiva
                              if (_errorMessage != null)
                                Container(
                                  margin: EdgeInsets.only(top: responsive.sectionSpacing),
                                  padding: ResponsiveSpacing.card(context),
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
                                        size: responsive.iconSize,
                                      ),
                                      SizedBox(width: responsive.itemSpacing),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: ResponsiveText.body(
                                            context,
                                            color: Colors.red.shade200,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().shake(),

                              ResponsiveSpacing.vertical(context, multiplier: 1.5),

                              // Link para registro responsivo
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Não tem uma conta?',
                                    style: ResponsiveText.body(
                                      context,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Get.toNamed(AppRoutes.register);
                                    },
                                    child: Text(
                                      'Criar conta',
                                      style: ResponsiveText.body(
                                        context,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 1800.ms),
                            ],
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

  Widget _buildGoogleButton() {
    final responsive = context.responsive;

    return Container(
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
          child: Container(
            height: responsive.buttonHeight,
            padding: EdgeInsets.symmetric(horizontal: responsive.cardPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_authController.isLoading.value)
                  SizedBox(
                    width: responsive.iconSize,
                    height: responsive.iconSize,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.login,
                    size: responsive.iconSize,
                    color: Colors.grey.shade700,
                  ),
                SizedBox(width: responsive.itemSpacing),
                Text(
                  'Continuar com Google',
                  style: ResponsiveText.button(
                    context,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 800.ms).slideX(
      begin: -0.1,
      end: 0,
      duration: 500.ms,
      curve: Curves.easeOutQuart,
    );
  }

  Widget _buildDivider() {
    final responsive = context.responsive;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.cardPadding),
          child: Text(
            'OU',
            style: ResponsiveText.body(
              context,
              color: Colors.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
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
    ).animate().fadeIn(delay: 1000.ms);
  }

  Widget _buildEmailField() {
    final responsive = context.responsive;

    return Container(
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
        style: ResponsiveText.body(context, color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Email',
          labelStyle: ResponsiveText.body(
            context,
            color: Colors.white.withOpacity(0.8),
          ),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.white.withOpacity(0.8),
            size: responsive.iconSize,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.cardPadding,
            vertical: responsive.cardPadding * 0.8,
          ),
          hintText: 'Digite seu email',
          hintStyle: ResponsiveText.body(
            context,
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
    );
  }

  Widget _buildPasswordField() {
    final responsive = context.responsive;

    return Container(
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
        style: ResponsiveText.body(context, color: Colors.white),
        decoration: InputDecoration(
          labelText: 'Senha',
          labelStyle: ResponsiveText.body(
            context,
            color: Colors.white.withOpacity(0.8),
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.white.withOpacity(0.8),
            size: responsive.iconSize,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.white.withOpacity(0.8),
              size: responsive.iconSize,
            ),
            onPressed: _togglePasswordVisibility,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.cardPadding,
            vertical: responsive.cardPadding * 0.8,
          ),
          hintText: 'Digite sua senha',
          hintStyle: ResponsiveText.body(
            context,
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
    );
  }
}