import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:oraculum/bindings/initial_bindings.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/firebase_options.dart';
import 'package:oraculum/screens/splash_screen.dart';

void main() async {
  // Garantir inicialização dos widgets
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar orientação da tela
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await initializeDateFormatting('pt_BR', null);

  // Configurar status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    // Inicializar Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase inicializado com sucesso');

    // Configurar Crashlytics para capturar erros do Flutter
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    // Configurar Stripe
    await _initializeStripe();

    runApp(const OraculumApp());
  } catch (e) {
    debugPrint('❌ Erro na inicialização: $e');
    // Em caso de erro crítico, ainda assim iniciar o app
    runApp(const OraculumApp());
  }
}

/// Inicializar Stripe SDK
Future<void> _initializeStripe() async {
  try {
    debugPrint('🔄 Inicializando Stripe...');

    // Configurar Stripe
    Stripe.publishableKey = 'pk_test_51RTpqm4TyzboYffk5IRBTmwEqPvKtBftyepU82rkCK5j0Bh6TYJ7Ld6e9lqvxoJoNe1xefeE58iFS2Igwvsfnc5q00R2Aztn0o';
    Stripe.merchantIdentifier = 'merchant.com.oraculum.app';
    Stripe.urlScheme = 'oraculum';

    // Aplicar configurações
    await Stripe.instance.applySettings();

    debugPrint('✅ Stripe inicializado com sucesso');
  } catch (e) {
    debugPrint('❌ Erro ao inicializar Stripe: $e');
    // Não bloquear o app se o Stripe falhar
  }
}

class OraculumApp extends StatelessWidget {
  const OraculumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Oraculum',
      debugShowCheckedModeBanner: false,

      // Tema
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // Configurações de localização
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),

      // Bindings iniciais
      initialBinding: InitialBinding(),

      // Rota inicial
      home: const SplashScreen(),

      // Todas as rotas
      getPages: AppRoutes.routes,

      // Configurações gerais
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      // Configurações de navegação
      enableLog: false,
      logWriterCallback: _logWriter,

      // Configurar tratamento de erros
      unknownRoute: GetPage(
        name: '/unknown',
        page: () => const NotFoundScreen(),
      ),

      // Configurações de conectividade
      routingCallback: (routing) {
        // Log de navegação para debug
        debugPrint('🧭 Navegando para: ${routing?.current}');
      },
    );
  }

  /// Logger personalizado para GetX
  void _logWriter(String text, {bool isError = false}) {
    if (isError) {
      debugPrint('❌ GetX Error: $text');
      FirebaseCrashlytics.instance.log('GetX Error: $text');
    } else {
      debugPrint('ℹ️ GetX: $text');
    }
  }
}

/// Tela para rotas não encontradas
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página não encontrada'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Página não encontrada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'A página que você está procurando não existe.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.offAllNamed('/navigation'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.home),
      ),
    );
  }
}