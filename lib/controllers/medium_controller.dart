import 'package:get/get.dart';
import 'package:oraculum/services/firebase_service.dart';
import 'package:oraculum/models/medium_model.dart';
import 'package:oraculum/models/appointment_model.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/controllers/payment_controller.dart';

class MediumController extends GetxController {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  final AuthController _authController = Get.find<AuthController>();

  RxBool isLoading = false.obs;
  RxList<MediumModel> allMediums = <MediumModel>[].obs;
  RxList<MediumModel> filteredMediums = <MediumModel>[].obs;
  Rx<MediumModel?> selectedMedium = Rx<MediumModel?>(null);
  RxList<AppointmentModel> userAppointments = <AppointmentModel>[].obs;

  RxString selectedSpecialty = ''.obs;
  RxList<String> specialties = <String>[
    'Tarot', 'Astrologia', 'Vidência', 'Mediunidade',
    'Leitura de Aura', 'Numerologia', 'Psicografia'
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadMediums();
  }

  Future<void> loadMediums() async {
    try {
      isLoading.value = true;
      final mediumsSnapshot = await _firebaseService.getMediums();

      if (mediumsSnapshot.docs.isNotEmpty) {
        allMediums.value = mediumsSnapshot.docs
            .map((doc) => MediumModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        filteredMediums.value = List.from(allMediums);
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar os médiuns: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void selectMedium(String mediumId) {
    final medium = allMediums.firstWhere((medium) => medium.id == mediumId);
    selectedMedium.value = medium;
    update();
  }

  void filterBySpecialty(String specialty) {
    selectedSpecialty.value = specialty;

    if (specialty.isEmpty) {
      filteredMediums.value = List.from(allMediums);
    } else {
      filteredMediums.value = allMediums
          .where((medium) => medium.specialties.contains(specialty))
          .toList();
    }

    update();
  }

  Future<void> loadUserAppointments() async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para ver seus agendamentos.');
        return;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;
      final appointmentsSnapshot = await _firebaseService.getUserAppointments(userId);

      if (appointmentsSnapshot.docs.isNotEmpty) {
        userAppointments.value = appointmentsSnapshot.docs
            .map((doc) => AppointmentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      }
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível carregar os agendamentos: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> bookAppointment(String mediumId, DateTime dateTime, int durationMinutes) async {
    try {
      if (_authController.currentUser.value == null) {
        Get.snackbar('Erro', 'Você precisa estar logado para fazer um agendamento.');
        return false;
      }

      isLoading.value = true;
      final userId = _authController.currentUser.value!.uid;

      // Calcular valor
      final medium = allMediums.firstWhere((m) => m.id == mediumId);
      final amount = medium.pricePerMinute * durationMinutes;

      // Verificar se o usuário tem créditos suficientes
      final paymentController = Get.find<PaymentController>();
      final hasCredits = await paymentController.checkUserCredits(userId, amount);

      if (!hasCredits) {
        Get.snackbar('Créditos insuficientes', 'Você não possui créditos suficientes para este agendamento.');
        return false;
      }

      // Processar pagamento com créditos
      final paymentResult = await paymentController.processPaymentWithCredits(
          userId,
          amount,
          'Agendamento com ${medium.name} por $durationMinutes minutos',
          mediumId,
          'appointment'
      );

      if (paymentResult.isEmpty) {
        Get.snackbar('Erro', 'Falha ao processar o pagamento.');
        return false;
      }

      // Criar agendamento
      final appointmentData = {
        'userId': userId,
        'mediumId': mediumId,
        'dateTime': dateTime,
        'durationMinutes': durationMinutes,
        'status': 'pending',
        'paymentId': paymentResult,
        'amount': amount,
        'createdAt': DateTime.now(),
      };

      await _firebaseService.createAppointment(appointmentData);
      Get.snackbar('Sucesso', 'Agendamento realizado com sucesso!');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível realizar o agendamento: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> cancelAppointment(String appointmentId) async {
    try {
      isLoading.value = true;

      // Atualizar status no Firebase
      await _firebaseService.updateAppointmentStatus(appointmentId, 'canceled');

      // Recarregar agendamentos
      await loadUserAppointments();

      Get.snackbar('Sucesso', 'Agendamento cancelado com sucesso!');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível cancelar o agendamento: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> addReview(String appointmentId, double rating, String feedback) async {
    try {
      isLoading.value = true;

      // Atualizar avaliação no Firebase
      await _firebaseService.updateAppointment(appointmentId, {
        'rating': rating,
        'feedback': feedback,
      });

      // Recarregar agendamentos
      await loadUserAppointments();

      Get.snackbar('Sucesso', 'Avaliação enviada com sucesso!');
      return true;
    } catch (e) {
      Get.snackbar('Erro', 'Não foi possível enviar a avaliação: $e');
      return false;
    } finally {
      isLoading.value = false;
      update();
    }
  }
}