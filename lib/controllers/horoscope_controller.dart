import 'package:get/get.dart';
import 'package:oraculum/services/gemini_service.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/models/horoscope_model.dart';
import 'package:intl/intl.dart';

class HoroscopeController extends GetxController {
  final GeminiService _geminiService = Get.find<GeminiService>();
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  RxBool isLoading = false.obs;
  RxString currentSign = ''.obs;
  Rx<HoroscopeModel?> dailyHoroscope = Rx<HoroscopeModel?>(null);
  RxList<String> zodiacSigns = <String>[
    'Áries', 'Touro', 'Gêmeos', 'Câncer',
    'Leão', 'Virgem', 'Libra', 'Escorpião',
    'Sagitário', 'Capricórnio', 'Aquário', 'Peixes'
  ].obs;

  Future<void> getDailyHoroscope(String sign) async {
    try {
      isLoading.value = true;
      currentSign.value = sign;

      // Formatar data atual
      final today = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd').format(today);

      // Verificar se já existe no Firestore
      final horoscopeDoc = await _firebaseService.getDailyHoroscope(sign, formattedDate);

      if (horoscopeDoc.exists) {
        // Usar horóscopo existente
        final data = horoscopeDoc.data() as Map<String, dynamic>;
        dailyHoroscope.value = HoroscopeModel.fromMap(data, horoscopeDoc.id);
      } else {
        // Gerar novo horóscopo com Gemini
        final horoscopeText = await _geminiService.getDailyHoroscope(sign);

        // Salvar no Firestore
        final horoscopeData = {
          'sign': sign,
          'date': today,
          'content': horoscopeText,
          'createdAt': today,
        };

        await _firebaseService.saveHoroscope('$sign-$formattedDate', horoscopeData);

        // Atualizar o estado
        dailyHoroscope.value = HoroscopeModel(
          id: '$sign-$formattedDate',
          sign: sign,
          date: today,
          content: horoscopeText,
          createdAt: today,
        );
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar o horóscopo: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<String> getCompatibilityAnalysis(String sign1, String sign2) async {
    try {
      isLoading.value = true;
      final compatibilityText = await _geminiService.getCompatibilityAnalysis(sign1, sign2);
      return compatibilityText;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível gerar a análise de compatibilidade: $e');
      return 'Erro ao gerar análise de compatibilidade.';
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<String> getBirthChartInterpretation(
      DateTime birthDate,
      String birthTime,
      String birthPlace,
      ) async {
    try {
      isLoading.value = true;
      final chartInterpretation = await _geminiService.getBirthChartInterpretation(
        birthDate,
        birthTime,
        birthPlace,
      );
      return chartInterpretation;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível interpretar o mapa astral: $e');
      return 'Erro ao interpretar o mapa astral.';
    } finally {
      isLoading.value = false;
      update();
    }
  }
}