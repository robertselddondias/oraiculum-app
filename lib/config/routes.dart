import 'package:get/get.dart';
import 'package:oraculum/controllers/horoscope_controller.dart';
import 'package:oraculum/controllers/mystic_circles_controller.dart';
import 'package:oraculum/screens/astrology/birth_chart_details_screen.dart';
import 'package:oraculum/screens/astrology/birth_chart_history_screen.dart';
import 'package:oraculum/screens/astrology/birth_chart_screen.dart';
import 'package:oraculum/screens/astrology/compatibility_screen.dart';
import 'package:oraculum/screens/astrology/horoscope_screen.dart';
import 'package:oraculum/screens/auth/forgot_password_screen.dart';
import 'package:oraculum/screens/auth/google_register_complete_screen.dart';
import 'package:oraculum/screens/auth/login_screen.dart';
import 'package:oraculum/screens/auth/register_screen.dart';
import 'package:oraculum/screens/home/home_screen.dart';
import 'package:oraculum/screens/home/navigation_screen.dart';
import 'package:oraculum/screens/mediums/booking_screen.dart';
import 'package:oraculum/screens/mediums/medium_profile_screen.dart';
import 'package:oraculum/screens/mediums/mediums_list_screen.dart';
import 'package:oraculum/screens/mystic_circle/circle_details_screen.dart';
import 'package:oraculum/screens/mystic_circle/mystic_circles_screen.dart';
import 'package:oraculum/screens/onboarding_screen.dart';
import 'package:oraculum/screens/payment/payment_history_screen.dart';
import 'package:oraculum/screens/payment/payment_methods_screen.dart';
import 'package:oraculum/screens/profile/notification_settings_screen.dart';
import 'package:oraculum/screens/profile/notifications_list_screen.dart';
import 'package:oraculum/screens/profile/profile_screen.dart';
import 'package:oraculum/screens/profile/settings_screen.dart';
import 'package:oraculum/screens/splash_screen.dart';
import 'package:oraculum/screens/tarot/card_details_screen.dart';
import 'package:oraculum/screens/tarot/saved_reading_detail_screen.dart';
import 'package:oraculum/screens/tarot/saved_readings_list_screen.dart';
import 'package:oraculum/screens/tarot/tarot_reading_screen.dart';
import 'package:oraculum/services/mystic_circles_service.dart';

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
  static const String birthChartHistory = '/birth-chart-history';
  static const String birthChartDetails = '/birth-chart-details';
  static const String tarotReading = '/tarot-reading';
  static const String tarotCardDetails = '/tarot-card-details';
  static const String savedReadingsList = '/saved-readings-list';
  static const String cardDetails = '/card-details';
  static const String mediumsList = '/mediums-list';
  static const String mediumProfile = '/medium-profile';
  static const String booking = '/booking';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String paymentMethods = '/payment-methods';
  static const String paymentHistory = '/payment-history';
  static const String savedReading = '/saved-reading-detail';
  static const String creditcardList = '/creditcard-list';
  static const String addCreditCard = '/add-credit-card';
  static const String googleRegisterComplete = '/google-register-complete';
  static const String notificationSettings = '/notificationSettings';
  static const String notificationList = '/notificationList';

  static const String mysticCircles = '/mystic-circles';
  static const String circleDetails = '/circle-details';




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
    GetPage(name: savedReadingsList, page: () => const SavedReadingsListScreen()),
    GetPage(name: cardDetails, page: () => const CardDetailsScreen()),
    GetPage(name: mediumsList, page: () => const MediumsListScreen()),
    GetPage(name: mediumProfile, page: () => const MediumProfileScreen()),
    GetPage(name: booking, page: () => const BookingScreen()),
    GetPage(name: profile, page: () => const ProfileScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    GetPage(name: paymentMethods, page: () => const PaymentMethodsScreen()),
    GetPage(name: paymentHistory, page: () => const PaymentHistoryScreen()),
    GetPage(
      name: savedReading,
      page: () => const SavedReadingDetailScreen(),
      transition: Transition.rightToLeft,  // Adicionando transição suave
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: AppRoutes.birthChartHistory,
      page: () => const BirthChartHistoryScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HoroscopeController>(() => HoroscopeController());
      }),
    ),

    GetPage(
      name: AppRoutes.birthChartDetails,
      page: () => const BirthChartDetailsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HoroscopeController>(() => HoroscopeController());
      }),
    ),
    GetPage(
      name: googleRegisterComplete,
      page: () => const GoogleRegisterCompleteScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: notificationSettings,
      page: () => const NotificationSettingsScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),
    GetPage(
      name: notificationList,
      page: () => const NotificationsListScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
    ),

    GetPage(
      name: mysticCircles,
      page: () => const MysticCirclesScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MysticCirclesService());
        Get.lazyPut(() => MysticCirclesController());
      }),
    ),

    GetPage(
      name: circleDetails,
      page: () => const CircleDetailsScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(() => MysticCirclesService());
        Get.lazyPut(() => MysticCirclesController());
      }),
    ),
  ];
}