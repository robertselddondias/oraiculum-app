import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/widgets/apple_signIn_button.dart';

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
  bool _rememberMe = false;

  final AuthController _authController = Get.find<AuthController>();

  late AnimationController _backgroundController;
  late AnimationController _cardController;
  late Animation<double> _backgroundAnimation;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.linear,
    ));

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    // Iniciar animações
    _backgroundController.repeat();
    _cardController.forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _cardController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    await _authController.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  Future<void> _loginWithGoogle() async {
    await _authController.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLargeScreen = size.width > 600;
    final isTablet = size.width > 800;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E).withOpacity(0.9),
                  const Color(0xFF16213E).withOpacity(0.9),
                  const Color(0xFF0F3460).withOpacity(0.9),
                  const Color(0xFF533483).withOpacity(0.9),
                ],
                stops: [
                  (_backgroundAnimation.value * 0.3) % 1.0,
                  (_backgroundAnimation.value * 0.5 + 0.2) % 1.0,
                  (_backgroundAnimation.value * 0.7 + 0.4) % 1.0,
                  (_backgroundAnimation.value * 0.9 + 0.6) % 1.0,
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 80 : (isLargeScreen ? 40 : 24),
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 500 : (isLargeScreen ? 400 : double.infinity),
                ),
                child: SlideTransition(
                  position: _cardSlideAnimation,
                  child: FadeTransition(
                    opacity: _cardFadeAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo e Header
                        _buildHeader(context, isLargeScreen),

                        SizedBox(height: isLargeScreen ? 48 : 32),

                        // Card principal
                        _buildMainCard(context, isLargeScreen),

                        SizedBox(height: isLargeScreen ? 32 : 24),

                        // Link para registro
                        _buildRegisterLink(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isLargeScreen) {
    return Column(
      children: [
        // Logo com efeito de brilho
        Container(
          width: isLargeScreen ? 120 : 100,
          height: isLargeScreen ? 120 : 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
              colors: [
                Color(0xFF8C6BAE),
                Color(0xFF533483),
                Color(0xFF392F5A),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8C6BAE).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: isLargeScreen ? 60 : 50,
            color: Colors.white,
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms)
            .scale(delay: 200.ms, duration: 600.ms)
            .shimmer(delay: 1000.ms, duration: 2000.ms),

        SizedBox(height: isLargeScreen ? 24 : 20),

        // Título principal
        Text(
          'Oraculum',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isLargeScreen ? 36 : 32,
            letterSpacing: 1.2,
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.3, end: 0, curve: Curves.easeOutQuad),

        SizedBox(height: isLargeScreen ? 12 : 8),

        // Subtítulo
        Text(
          'Descubra os mistérios do universo',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
            fontSize: isLargeScreen ? 18 : 16,
            letterSpacing: 0.5,
          ),
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildMainCard(BuildContext context, bool isLargeScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isLargeScreen ? 32 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título do formulário
                  Text(
                    'Entrar na sua conta',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isLargeScreen ? 24 : 20,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 500.ms),

                  SizedBox(height: isLargeScreen ? 32 : 24),

                  // Campo de email
                  _buildEmailField(isLargeScreen),

                  SizedBox(height: isLargeScreen ? 20 : 16),

                  // Campo de senha
                  _buildPasswordField(isLargeScreen),

                  SizedBox(height: isLargeScreen ? 20 : 16),

                  // Remember me e Forgot password
                  _buildOptionsRow(context),

                  SizedBox(height: isLargeScreen ? 32 : 24),

                  // Botão de login
                  _buildLoginButton(isLargeScreen),

                  SizedBox(height: isLargeScreen ? 24 : 20),

                  // Divider
                  _buildDivider(),

                  SizedBox(height: isLargeScreen ? 24 : 20),

                  // Botões de login social
                  _buildSocialButtons(isLargeScreen),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 600.ms, duration: 800.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildEmailField(bool isLargeScreen) {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(
          color: Colors.white70,
          fontSize: isLargeScreen ? 16 : 14,
        ),
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: Colors.white70,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF8C6BAE),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isLargeScreen ? 20 : 16,
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
    )
        .animate()
        .fadeIn(delay: 1000.ms, duration: 500.ms)
        .slideX(begin: -0.2, end: 0);
  }

  Widget _buildPasswordField(bool isLargeScreen) {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Senha',
        labelStyle: TextStyle(
          color: Colors.white70,
          fontSize: isLargeScreen ? 16 : 14,
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Colors.white70,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: Colors.white70,
          ),
          onPressed: _togglePasswordVisibility,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF8C6BAE),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Colors.red,
            width: 1,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: isLargeScreen ? 20 : 16,
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
    )
        .animate()
        .fadeIn(delay: 1100.ms, duration: 500.ms)
        .slideX(begin: 0.2, end: 0);
  }

  Widget _buildOptionsRow(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 350;

    if (isSmallScreen) {
      // Layout em coluna para telas muito pequenas
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Remember me
          Row(
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF8C6BAE),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'Lembrar-me',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Forgot password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Get.toNamed(AppRoutes.forgotPassword);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Esqueceu a senha?',
                style: TextStyle(
                  color: Color(0xFF8C6BAE),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Layout normal em linha
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me
        Flexible(
          flex: 1,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.9,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF8C6BAE),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
              const Flexible(
                child: Text(
                  'Lembrar-me',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Forgot password
        Flexible(
          flex: 1,
          child: TextButton(
            onPressed: () {
              Get.toNamed(AppRoutes.forgotPassword);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Esqueceu a senha?',
              style: TextStyle(
                color: Color(0xFF8C6BAE),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 1200.ms, duration: 500.ms);
  }

  Widget _buildLoginButton(bool isLargeScreen) {
    return Obx(() => Container(
      height: isLargeScreen ? 56 : 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF8C6BAE),
            Color(0xFF533483),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C6BAE).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _authController.isLoading.value ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _authController.isLoading.value
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          'Entrar',
          style: TextStyle(
            fontSize: isLargeScreen ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ))
        .animate()
        .fadeIn(delay: 1300.ms, duration: 500.ms)
        .scale(delay: 1300.ms, duration: 500.ms);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 1400.ms, duration: 500.ms);
  }

  Widget _buildSocialButtons(bool isLargeScreen) {
    return Column(
      children: [
        // Google Sign In
        _buildSocialButton(
          onPressed: _loginWithGoogle,
          icon: Icons.g_mobiledata_rounded,
          label: 'Continuar com Google',
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          isLargeScreen: isLargeScreen,
        )
            .animate()
            .fadeIn(delay: 1500.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0),

        SizedBox(height: isLargeScreen ? 16 : 12),

        // Apple Sign In (apenas iOS)
        CustomAppleSignInButton(
          text: 'Continuar com Apple',
          height: isLargeScreen ? 56 : 50,
          borderRadius: 16,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        )
            .animate()
            .fadeIn(delay: 1600.ms, duration: 500.ms)
            .slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required bool isLargeScreen,
  }) {
    return Obx(() => SizedBox(
      height: isLargeScreen ? 56 : 50,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _authController.isLoading.value ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _authController.isLoading.value
                ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
                : Image.asset(
              'assets/icons/ic_google.png',
              height: 24,
              width: 24,
              color: textColor,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _authController.isLoading.value ? 'Entrando...' : label,
                style: TextStyle(
                  fontSize: isLargeScreen ? 16 : 14,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildRegisterLink(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Não tem uma conta? ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Get.toNamed(AppRoutes.register);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Criar conta',
            style: TextStyle(
              color: Color(0xFF8C6BAE),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 1700.ms, duration: 500.ms);
  }
}