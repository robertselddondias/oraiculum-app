// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:store_redirect/store_redirect.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// class RatingService {
//   static const String _ratingShownKey = 'rating_dialog_shown';
//   static const String _lastRatingRequestKey = 'last_rating_request';
//   static const String _appUsageCountKey = 'app_usage_count';
//
//   // URLs das lojas (substitua pelos IDs reais quando publicar)
//   static const String androidPackageName = 'com.selddon.oraculum';
//   static const String iosAppId = '123456789'; // Substitua pelo ID real da App Store
//
//   /// Verificar se o in-app review está disponível
//   static Future<bool> isInAppReviewAvailable() async {
//     try {
//       final InAppReview inAppReview = InAppReview.instance;
//       return await inAppReview.isAvailable();
//     } catch (e) {
//       debugPrint('Erro ao verificar disponibilidade do in-app review: $e');
//       return false;
//     }
//   }
//
//   /// Solicitar avaliação in-app (método nativo)
//   static Future<void> requestInAppReview() async {
//     try {
//       final InAppReview inAppReview = InAppReview.instance;
//       final bool isAvailable = await inAppReview.isAvailable();
//
//       if (isAvailable) {
//         debugPrint('Solicitando avaliação in-app...');
//         await inAppReview.requestReview();
//         await _markRatingShown();
//       } else {
//         debugPrint('In-app review não disponível, abrindo loja...');
//         await openAppInStore();
//       }
//     } catch (e) {
//       debugPrint('Erro ao solicitar avaliação in-app: $e');
//       await openAppInStore();
//     }
//   }
//
//   /// Abrir app na loja (Google Play / App Store)
//   static Future<void> openAppInStore() async {
//     try {
//       if (Platform.isAndroid) {
//         await StoreRedirect.redirect(
//           androidAppId: androidPackageName,
//         );
//       } else if (Platform.isIOS) {
//         await StoreRedirect.redirect(
//           iOSAppId: iosAppId,
//         );
//       }
//     } catch (e) {
//       debugPrint('Erro ao abrir loja: $e');
//       // Fallback para URLs diretas
//       await _openStoreWithUrl();
//     }
//   }
//
//   /// Fallback - abrir loja com URL direta
//   static Future<void> _openStoreWithUrl() async {
//     try {
//       String url;
//       if (Platform.isAndroid) {
//         url = 'https://play.google.com/store/apps/details?id=$androidPackageName';
//       } else if (Platform.isIOS) {
//         url = 'https://apps.apple.com/app/id$iosAppId';
//       } else {
//         return;
//       }
//
//       final Uri uri = Uri.parse(url);
//       if (await canLaunchUrl(uri)) {
//         await launchUrl(uri, mode: LaunchMode.externalApplication);
//       }
//     } catch (e) {
//       debugPrint('Erro ao abrir URL da loja: $e');
//     }
//   }
//
//   /// Mostrar diálogo customizado de avaliação (CORRIGIDO - sem overflow)
//   static Future<void> showCustomRatingDialog() async {
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: const Color(0xFF2A2A40),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.amber.withOpacity(0.2),
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(Icons.star, color: Colors.amber, size: 20),
//             ),
//             const SizedBox(width: 12),
//             const Expanded(
//               child: Text(
//                 'Avaliar o Oraculum',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.amber.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.amber.withOpacity(0.3)),
//                 ),
//                 child: Column(
//                   children: [
//                     // Estrelas com espaçamento adequado
//                     SizedBox(
//                       width: double.infinity,
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: List.generate(5, (index) =>
//                             const Padding(
//                               padding: EdgeInsets.symmetric(horizontal: 2),
//                               child: Icon(
//                                 Icons.star,
//                                 color: Colors.amber,
//                                 size: 24, // Reduzido para evitar overflow
//                               ),
//                             ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text(
//                       'Está gostando do Oraculum?',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Sua avaliação nos ajuda a melhorar e alcançar mais pessoas que buscam orientação espiritual.',
//                       style: TextStyle(
//                         color: Colors.white70,
//                         fontSize: 13,
//                         height: 1.4,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Get.back();
//               _markRatingShown();
//             },
//             child: const Text(
//               'Mais tarde',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ),
//           ElevatedButton.icon(
//             onPressed: () async {
//               Get.back();
//               await requestInAppReview();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.amber,
//               foregroundColor: Colors.black,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             ),
//             icon: const Icon(Icons.star, size: 16),
//             label: const Text(
//               'Avaliar',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Mostrar diálogo simples de avaliação (alternativa menor)
//   static Future<void> showSimpleRatingDialog() async {
//     Get.dialog(
//       AlertDialog(
//         backgroundColor: const Color(0xFF2A2A40),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Row(
//           children: [
//             Icon(Icons.star, color: Colors.amber, size: 24),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Avaliar App',
//                 style: TextStyle(color: Colors.white, fontSize: 18),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         ),
//         content: const Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Está gostando do Oraculum?',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 8),
//             Text(
//               'Sua avaliação nos ajuda muito!',
//               style: TextStyle(
//                 color: Colors.white70,
//                 fontSize: 14,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Get.back();
//               _markRatingShown();
//             },
//             child: const Text(
//               'Depois',
//               style: TextStyle(color: Colors.white70),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () async {
//               Get.back();
//               await requestInAppReview();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.amber,
//               foregroundColor: Colors.black,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             ),
//             child: const Text(
//               'Avaliar',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Verificar se deve mostrar solicitação de avaliação
//   static Future<bool> shouldShowRatingRequest() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//
//       // Verificar se já foi mostrado
//       final bool alreadyShown = prefs.getBool(_ratingShownKey) ?? false;
//       if (alreadyShown) return false;
//
//       // Verificar última solicitação (evitar spam)
//       final int lastRequest = prefs.getInt(_lastRatingRequestKey) ?? 0;
//       final int daysSinceLastRequest =
//           (DateTime.now().millisecondsSinceEpoch - lastRequest) ~/ (1000 * 60 * 60 * 24);
//
//       if (daysSinceLastRequest < 7) return false; // Esperar 7 dias
//
//       // Verificar número de usos do app
//       final int usageCount = prefs.getInt(_appUsageCountKey) ?? 0;
//       if (usageCount < 5) return false; // Mostrar após 5 usos
//
//       return true;
//     } catch (e) {
//       debugPrint('Erro ao verificar se deve mostrar avaliação: $e');
//       return false;
//     }
//   }
//
//   /// Incrementar contador de uso do app
//   static Future<void> incrementAppUsage() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final int currentCount = prefs.getInt(_appUsageCountKey) ?? 0;
//       await prefs.setInt(_appUsageCountKey, currentCount + 1);
//       debugPrint('Uso do app incrementado para: ${currentCount + 1}');
//     } catch (e) {
//       debugPrint('Erro ao incrementar uso do app: $e');
//     }
//   }
//
//   /// Marcar que a avaliação foi mostrada
//   static Future<void> _markRatingShown() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool(_ratingShownKey, true);
//       await prefs.setInt(_lastRatingRequestKey, DateTime.now().millisecondsSinceEpoch);
//       debugPrint('Avaliação marcada como mostrada');
//     } catch (e) {
//       debugPrint('Erro ao marcar avaliação como mostrada: $e');
//     }
//   }
//
//   /// Resetar flags de avaliação (para testes)
//   static Future<void> resetRatingFlags() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.remove(_ratingShownKey);
//       await prefs.remove(_lastRatingRequestKey);
//       await prefs.remove(_appUsageCountKey);
//       debugPrint('Flags de avaliação resetadas');
//     } catch (e) {
//       debugPrint('Erro ao resetar flags: $e');
//     }
//   }
//
//   /// Forçar mostrar avaliação (para testes)
//   static Future<void> forceShowRating() async {
//     await showSimpleRatingDialog();
//   }
// }