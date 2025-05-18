import 'package:oraculum/screens/astrology/birth_chart_screen.dart';
import 'package:oraculum/screens/onboarding_screen.dart';
import 'package:oraculum/screens/payment/payment_history_screen.dart';
import 'package:oraculum/screens/splash_screen.dart';
import 'package:oraculum/screens/tarot/card_details_screen.dart';
import 'package:get/get.dart';
import 'package:oraculum/screens/auth/login_screen.dart';
import 'package:oraculum/screens/auth/register_screen.dart';
import 'package:oraculum/screens/auth/forgot_password_screen.dart';
import 'package:oraculum/screens/home/home_screen.dart';
import 'package:oraculum/screens/home/navigation_screen.dart';
import 'package:oraculum/screens/astrology/horoscope_screen.dart';
import 'package:oraculum/screens/astrology/compatibility_screen.dart';
import 'package:oraculum/screens/tarot/saved_readings_list_screen.dart';
import 'package:oraculum/screens/tarot/tarot_reading_screen.dart';
import 'package:oraculum/screens/mediums/mediums_list_screen.dart';
import 'package:oraculum/screens/mediums/medium_profile_screen.dart';
import 'package:oraculum/screens/mediums/booking_screen.dart';
import 'package:oraculum/screens/profile/profile_screen.dart';
import 'package:oraculum/screens/profile/settings_screen.dart';
import 'package:oraculum/screens/payment/payment_methods_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String navigation = '/navigation';
  static const String horoscope = '/horoscope';
  static const String compatibility = '/compatibility';
  static const String birthChart = '/birth-chart';
  static const String tarotReading = '/tarot-reading';
  static const String tarotCardDetails = '/tarot-card-details';
  static const String tarotReadingsList = '/tarot-readings-list';
  static const String savedReading = '/saved-reading';
  static const String cardDetails = '/card-details';
  static const String mediumsList = '/mediums-list';
  static const String mediumProfile = '/medium-profile';
  static const String booking = '/booking';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String paymentMethods = '/payment-methods';
  static const String paymentHistory = '/payment-history';

  static final routes = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: home, page: () => const HomeScreen()),
    GetPage(name: navigation, page: () => const NavigationScreen()),
    GetPage(name: horoscope, page: () => const HoroscopeScreen()),
    GetPage(name: compatibility, page: () => const CompatibilityScreen()),
    GetPage(name: birthChart, page: () => const BirthChartScreen()),
    GetPage(name: tarotReading, page: () => const TarotReadingScreen()),
    GetPage(name: savedReading, page: () => const SavedReadingsListScreen()),
    GetPage(name: cardDetails, page: () => const CardDetailsScreen()),
    GetPage(name: mediumsList, page: () => const MediumsListScreen()),
    GetPage(name: mediumProfile, page: () => const MediumProfileScreen()),
    GetPage(name: booking, page: () => const BookingScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(name: paymentMethods, page: () => const PaymentMethodsScreen()),
    GetPage(name: paymentHistory, page: () => const PaymentHistoryScreen()),
  ];
}