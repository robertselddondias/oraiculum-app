// lib/controllers/consultation_schedule_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/models/consultation_request_model.dart';
import 'package:oraculum/services/consultation_service.dart';

class ConsultationScheduleController extends GetxController {
  final ConsultationService _consultationService = Get.find<ConsultationService>();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ConsultationRequest> _consultationRequests = <ConsultationRequest>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isRefreshing = false.obs;
  final RxString _selectedFilter = 'all'.obs;
  final Rx<DateTime> _selectedDate = DateTime.now().obs;

  List<ConsultationRequest> get consultationRequests => _consultationRequests;
  bool get isLoading => _isLoading.value;
  bool get isRefreshing => _isRefreshing.value;
  String get selectedFilter => _selectedFilter.value;
  DateTime get selectedDate => _selectedDate.value;

  List<ConsultationRequest> get filteredRequests {
    final now = DateTime.now();

    switch (_selectedFilter.value) {
      case 'pending':
        return _consultationRequests.where((r) => r.status == ConsultationStatus.pending).toList();
      case 'scheduled':
        return _consultationRequests.where((r) => r.status == ConsultationStatus.scheduled).toList();
      case 'completed':
        return _consultationRequests.where((r) => r.status == ConsultationStatus.completed).toList();
      case 'today':
        return _consultationRequests.where((r) {
          if (r.scheduledDate == null) return false;
          return DateUtils.isSameDay(r.scheduledDate!, now);
        }).toList();
      default:
        return _consultationRequests;
    }
  }

  int get pendingCount => _consultationRequests.where((r) => r.status == ConsultationStatus.pending).length;
  int get scheduledCount => _consultationRequests.where((r) => r.status == ConsultationStatus.scheduled).length;
  int get todayCount {
    final now = DateTime.now();
    return _consultationRequests.where((r) {
      if (r.scheduledDate == null) return false;
      return DateUtils.isSameDay(r.scheduledDate!, now);
    }).length;
  }

  @override
  void onInit() {
    super.onInit();
    loadConsultationRequests();
  }

  void setSelectedFilter(String filter) {
    _selectedFilter.value = filter;
  }

  void setSelectedDate(DateTime date) {
    _selectedDate.value = date;
  }

  Future<void> loadConsultationRequests() async {
    try {
      _isLoading.value = true;

      final user = _authController.userModel.value;
      if (user == null) {
        throw Exception('Usuário não encontrado');
      }

      final requests = await _consultationService.getMediumConsultationRequests(user.id);
      _consultationRequests.assignAll(requests);

      debugPrint('✅ ${requests.length} solicitações carregadas');

    } catch (e) {
      debugPrint('❌ Erro ao carregar solicitações: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível carregar as solicitações',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshRequests() async {
    try {
      _isRefreshing.value = true;
      await loadConsultationRequests();
    } finally {
      _isRefreshing.value = false;
    }
  }

  Future<void> acceptRequest(ConsultationRequest request) async {
    try {
      await _consultationService.acceptConsultationRequest(request.id);

      final index = _consultationRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _consultationRequests[index] = request.copyWith(
          status: ConsultationStatus.scheduled,
        );
      }

      Get.snackbar(
        'Sucesso',
        'Solicitação aceita! Entre em contato com o cliente para agendar.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      await loadConsultationRequests();

    } catch (e) {
      debugPrint('❌ Erro ao aceitar solicitação: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível aceitar a solicitação',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> declineRequest(ConsultationRequest request, {String? reason}) async {
    try {
      await _consultationService.declineConsultationRequest(request.id, reason: reason);

      final index = _consultationRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _consultationRequests[index] = request.copyWith(
          status: ConsultationStatus.cancelled,
          notes: reason ?? request.notes,
        );
      }

      Get.snackbar(
        'Solicitação Recusada',
        'A solicitação foi recusada',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      await loadConsultationRequests();

    } catch (e) {
      debugPrint('❌ Erro ao recusar solicitação: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível recusar a solicitação',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> scheduleRequest(ConsultationRequest request, DateTime scheduledDate) async {
    try {
      await _consultationService.scheduleConsultationRequest(request.id, scheduledDate);

      final index = _consultationRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _consultationRequests[index] = request.copyWith(
          status: ConsultationStatus.scheduled,
          scheduledDate: scheduledDate,
        );
      }

      Get.snackbar(
        'Consulta Agendada',
        'A consulta foi agendada com sucesso',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      await loadConsultationRequests();

    } catch (e) {
      debugPrint('❌ Erro ao agendar consulta: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível agendar a consulta',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> completeRequest(ConsultationRequest request, {String? notes}) async {
    try {
      await _consultationService.completeConsultationRequest(request.id, notes: notes);

      final index = _consultationRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _consultationRequests[index] = request.copyWith(
          status: ConsultationStatus.completed,
          completedAt: DateTime.now(),
          notes: notes ?? request.notes,
        );
      }

      Get.snackbar(
        'Consulta Concluída',
        'A consulta foi marcada como concluída',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );

      await loadConsultationRequests();

    } catch (e) {
      debugPrint('❌ Erro ao concluir consulta: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível concluir a consulta',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> updateRequestNotes(ConsultationRequest request, String notes) async {
    try {
      await _consultationService.updateConsultationRequest(request.id, {'notes': notes});

      final index = _consultationRequests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        _consultationRequests[index] = request.copyWith(notes: notes);
      }

      Get.snackbar(
        'Observações Atualizadas',
        'As observações foram salvas',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      debugPrint('❌ Erro ao atualizar observações: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível salvar as observações',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> deleteRequest(ConsultationRequest request) async {
    try {
      await _consultationService.deleteConsultationRequest(request.id);

      _consultationRequests.removeWhere((r) => r.id == request.id);

      Get.snackbar(
        'Solicitação Removida',
        'A solicitação foi removida',
        backgroundColor: Colors.grey,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

    } catch (e) {
      debugPrint('❌ Erro ao remover solicitação: $e');

      Get.snackbar(
        'Erro',
        'Não foi possível remover a solicitação',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void showDeclineDialog(ConsultationRequest request) {
    final TextEditingController reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF392F5A),
        title: const Text(
          'Recusar Solicitação',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tem certeza que deseja recusar a solicitação de ${request.clientName}?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C6BAE)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              declineRequest(request, reason: reasonController.text.trim());
            },
            child: const Text(
              'Recusar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void showScheduleDialog(ConsultationRequest request) {
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF392F5A),
            title: const Text(
              'Agendar Consulta',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Agendar consulta com ${request.clientName}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),

                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF8C6BAE)),
                  title: Text(
                    '${selectedDateTime.day.toString().padLeft(2, '0')}/'
                        '${selectedDateTime.month.toString().padLeft(2, '0')}/'
                        '${selectedDateTime.year}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Data da consulta',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF8C6BAE),
                              onPrimary: Colors.white,
                              surface: Color(0xFF392F5A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (date != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          selectedDateTime.hour,
                          selectedDateTime.minute,
                        );
                      });
                    }
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.access_time, color: Color(0xFF8C6BAE)),
                  title: Text(
                    '${selectedDateTime.hour.toString().padLeft(2, '0')}:'
                        '${selectedDateTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Horário da consulta',
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF8C6BAE),
                              onPrimary: Colors.white,
                              surface: Color(0xFF392F5A),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );

                    if (time != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          selectedDateTime.year,
                          selectedDateTime.month,
                          selectedDateTime.day,
                          time.hour,
                          time.minute,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              TextButton(
                onPressed: () {
                  Get.back();
                  scheduleRequest(request, selectedDateTime);
                },
                child: const Text(
                  'Agendar',
                  style: TextStyle(color: Color(0xFF8C6BAE)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void showCompletionDialog(ConsultationRequest request) {
    final TextEditingController notesController = TextEditingController(text: request.notes);

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF392F5A),
        title: const Text(
          'Concluir Consulta',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marcar consulta com ${request.clientName} como concluída?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Observações finais (opcional)',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF8C6BAE)),
                ),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              completeRequest(request, notes: notesController.text.trim());
            },
            child: const Text(
              'Concluir',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}