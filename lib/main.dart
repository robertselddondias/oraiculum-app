import 'package:firebase_auth/firebase_auth.dart';
import 'package:oraculum/bindings/initial_bindings.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/models/load_cards.dart';
import 'package:oraculum/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:oraculum/config/theme.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/utils/keyboard_dismiss.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Inicializa os controladores principais
  InitialBinding().dependencies();

  runApp(const AstralConnectApp());
}



class AstralConnectApp extends StatelessWidget {
  const AstralConnectApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardDismiss(
      child: GetMaterialApp(
        title: 'Oraculum',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pt', 'BR'),
          Locale('en', 'US'),
        ],
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          ...AppRoutes.routes,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}