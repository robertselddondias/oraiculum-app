// lib/controllers/mystic_circles_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/auth_controller.dart';
import 'package:oraculum/models/mystic_circle_model.dart';
import 'package:oraculum/models/shared_reading_model.dart';
import 'package:oraculum/models/circle_invitation_model.dart';
import 'package:oraculum/services/mystic_circles_service.dart';

class MysticCirclesController extends GetxController {
  final MysticCirclesService _circlesService = Get.find<MysticCirclesService>();
  final AuthController _authController = Get.find<AuthController>();

  // Estados observáveis
  RxBool isLoading = false.obs;
  RxBool isCreatingCircle = false.obs;
  RxString error = ''.obs;

  // Listas principais
  RxList<MysticCircle> userCircles = <MysticCircle>[].obs;
  RxList<MysticCircle> discoveredCircles = <MysticCircle>[].obs;
  RxList<CircleInvitation> pendingInvitations = <CircleInvitation>[].obs;

  // Círculo atualmente selecionado
  Rx<MysticCircle?> selectedCircle = Rx<MysticCircle?>(null);
  RxList<SharedReading> circleReadings = <SharedReading>[].obs;

  // Estados de UI
  RxInt selectedTabIndex = 0.obs;
  RxString searchQuery = ''.obs;
  RxList<String> selectedTags = <String>[].obs;

  // Estatísticas
  Rx<Map<String, dynamic>> userStats = Rx<Map<String, dynamic>>({});

  String? get currentUserId => _authController.currentUser.value?.uid;
  String? get currentUserName => _authController.userModel.value?.name;
  String? get currentUserImageUrl => _authController.userModel.value?.profileImageUrl;

  @override
  void onInit() {
    super.onInit();
    debugPrint('=== MysticCirclesController.onInit() ===');

    if (currentUserId != null) {
      _initializeData();
    }
  }

  void _initializeData() {
    loadUserCircles();
    loadPendingInvitations();
    loadDiscoveredCircles();
    loadUserStatistics();
  }

  // ========== CIRCLE MANAGEMENT ==========

  /// Carregar círculos do usuário
  void loadUserCircles() {
    if (currentUserId == null) return;

    debugPrint('=== loadUserCircles() ===');

    _circlesService.getUserCircles(currentUserId!).listen(
          (circles) {
        userCircles.value = circles;
        debugPrint('✅ ${circles.length} círculos carregados');
      },
      onError: (e) {
        debugPrint('❌ Erro ao carregar círculos: $e');
        error.value = 'Erro ao carregar seus círculos';
        _showErrorSnackbar('Erro', 'Não foi possível carregar seus círculos');
      },
    );
  }

  /// Criar novo círculo
  Future<void> createCircle({
    required String name,
    required String description,
    required CircleType type,
    CircleSettings? settings,
    List<String>? tags,
  }) async {
    if (currentUserId == null || currentUserName == null) {
      _showErrorSnackbar('Erro', 'Você precisa estar logado');
      return;
    }

    try {
      debugPrint('=== createCircle() ===');
      isCreatingCircle.value = true;
      error.value = '';

      final circleId = await _circlesService.createCircle(
        name: name,
        description: description,
        type: type,
        creatorId: currentUserId!,
        creatorName: currentUserName!,
        settings: settings,
        tags: tags,
      );

      _showSuccessSnackbar('Sucesso', 'Círculo "$name" criado com sucesso!');

      // Recarregar lista de círculos
      loadUserCircles();

      // Navegar para o círculo criado
      await selectCircle(circleId);

    } catch (e) {
      debugPrint('❌ Erro ao criar círculo: $e');
      error.value = e.toString();
      _showErrorSnackbar('Erro', 'Não foi possível criar o círculo: $e');
    } finally {
      isCreatingCircle.value = false;
    }
  }

  /// Selecionar círculo para visualização
  Future<void> selectCircle(String circleId) async {
    try {
      debugPrint('=== selectCircle() ===');
      isLoading.value = true;

      final circle = await _circlesService.getCircle(circleId);
      if (circle != null) {
        selectedCircle.value = circle;
        loadCircleReadings(circleId);
        debugPrint('✅ Círculo selecionado: ${circle.name}');
      } else {
        throw Exception('Círculo não encontrado');
      }

    } catch (e) {
      debugPrint('❌ Erro ao selecionar círculo: $e');
      _showErrorSnackbar('Erro', 'Não foi possível carregar o círculo');
    } finally {
      isLoading.value = false;
    }
  }

  /// Atualizar configurações do círculo
  Future<void> updateCircleSettings({
    required String circleId,
    String? name,
    String? description,
    CircleSettings? settings,
    List<String>? tags,
  }) async {
    try {
      debugPrint('=== updateCircleSettings() ===');
      isLoading.value = true;

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (settings != null) updates['settings'] = settings.toMap();
      if (tags != null) updates['tags'] = tags;

      await _circlesService.updateCircle(circleId, updates);

      _showSuccessSnackbar('Sucesso', 'Configurações atualizadas');

      // Recarregar círculo se for o selecionado
      if (selectedCircle.value?.id == circleId) {
        await selectCircle(circleId);
      }

    } catch (e) {
      debugPrint('❌ Erro ao atualizar configurações: $e');
      _showErrorSnackbar('Erro', 'Não foi possível atualizar as configurações');
    } finally {
      isLoading.value = false;
    }
  }

  /// Excluir círculo
  Future<void> deleteCircle(String circleId) async {
    try {
      debugPrint('=== deleteCircle() ===');
      isLoading.value = true;

      await _circlesService.deleteCircle(circleId, currentUserId!);

      _showSuccessSnackbar('Sucesso', 'Círculo excluído com sucesso');

      // Limpar seleção se for o círculo atual
      if (selectedCircle.value?.id == circleId) {
        selectedCircle.value = null;
        circleReadings.clear();
      }

      loadUserCircles();

    } catch (e) {
      debugPrint('❌ Erro ao excluir círculo: $e');
      _showErrorSnackbar('Erro', 'Não foi possível excluir o círculo: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ========== MEMBER MANAGEMENT ==========

  /// Convidar usuário para círculo
  Future<void> inviteToCircle({
    required String circleId,
    required String inviteeEmail,
    String? message,
  }) async {
    if (currentUserId == null || currentUserName == null) return;

    try {
      debugPrint('=== inviteToCircle() ===');
      isLoading.value = true;

      await _circlesService.inviteToCircle(
        circleId: circleId,
        inviterId: currentUserId!,
        inviterName: currentUserName!,
        inviteeEmail: inviteeEmail,
        message: message,
      );

      _showSuccessSnackbar('Sucesso', 'Convite enviado para $inviteeEmail');

    } catch (e) {
      debugPrint('❌ Erro ao enviar convite: $e');
      _showErrorSnackbar('Erro', 'Não foi possível enviar o convite: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Carregar convites pendentes
  void loadPendingInvitations() {
    if (currentUserId == null) return;

    debugPrint('=== loadPendingInvitations() ===');

    _circlesService.getUserInvitations(currentUserId!).listen(
          (invitations) {
        pendingInvitations.value = invitations;
        debugPrint('✅ ${invitations.length} convites pendentes');
      },
      onError: (e) {
        debugPrint('❌ Erro ao carregar convites: $e');
      },
    );
  }

  /// Responder a convite
  Future<void> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    try {
      debugPrint('=== respondToInvitation() ===');
      isLoading.value = true;

      await _circlesService.respondToInvitation(
        invitationId: invitationId,
        accept: accept,
      );

      final action = accept ? 'aceito' : 'recusado';
      _showSuccessSnackbar('Sucesso', 'Convite $action com sucesso');

      if (accept) {
        loadUserCircles();
      }

    } catch (e) {
      debugPrint('❌ Erro ao responder convite: $e');
      _showErrorSnackbar('Erro', 'Não foi possível responder ao convite: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Remover membro do círculo
  Future<void> removeMember({
    required String circleId,
    required String memberId,
  }) async {
    try {
      debugPrint('=== removeMember() ===');
      isLoading.value = true;

      await _circlesService.removeMember(
        circleId: circleId,
        memberId: memberId,
        removedById: currentUserId!,
      );

      _showSuccessSnackbar('Sucesso', 'Membro removido do círculo');

      // Recarregar círculo se for o selecionado
      if (selectedCircle.value?.id == circleId) {
        await selectCircle(circleId);
      }

    } catch (e) {
      debugPrint('❌ Erro ao remover membro: $e');
      _showErrorSnackbar('Erro', 'Não foi possível remover o membro: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ========== SHARED READINGS ==========

  /// Carregar leituras do círculo
  void loadCircleReadings(String circleId) {
    debugPrint('=== loadCircleReadings() ===');

    _circlesService.getCircleReadings(circleId).listen(
          (readings) {
        circleReadings.value = readings;
        debugPrint('✅ ${readings.length} leituras carregadas');
      },
      onError: (e) {
        debugPrint('❌ Erro ao carregar leituras: $e');
      },
    );
  }

  /// Compartilhar leitura
  Future<void> shareReading({
    required String circleId,
    required String title,
    required String description,
    required ReadingType type,
    required Map<String, dynamic> readingData,
    List<String>? tags,
    ReadingVisibility visibility = ReadingVisibility.circle,
  }) async {
    if (currentUserId == null || currentUserName == null) return;

    try {
      debugPrint('=== shareReading() ===');
      isLoading.value = true;

      await _circlesService.shareReading(
        circleId: circleId,
        userId: currentUserId!,
        userName: currentUserName!,
        userImageUrl: currentUserImageUrl,
        title: title,
        description: description,
        type: type,
        readingData: readingData,
        tags: tags,
        visibility: visibility,
      );

      _showSuccessSnackbar('Sucesso', 'Leitura compartilhada com sucesso!');

    } catch (e) {
      debugPrint('❌ Erro ao compartilhar leitura: $e');
      _showErrorSnackbar('Erro', 'Não foi possível compartilhar a leitura: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Curtir leitura
  Future<void> likeReading(String readingId) async {
    if (currentUserId == null) return;

    try {
      await _circlesService.likeReading(readingId, currentUserId!);
    } catch (e) {
      debugPrint('❌ Erro ao curtir leitura: $e');
      _showErrorSnackbar('Erro', 'Não foi possível curtir a leitura');
    }
  }

  /// Descurtir leitura
  Future<void> unlikeReading(String readingId) async {
    if (currentUserId == null) return;

    try {
      await _circlesService.unlikeReading(readingId, currentUserId!);
    } catch (e) {
      debugPrint('❌ Erro ao descurtir leitura: $e');
      _showErrorSnackbar('Erro', 'Não foi possível descurtir a leitura');
    }
  }

  /// Adicionar comentário
  Future<void> addComment({
    required String readingId,
    required String content,
    String? replyToId,
  }) async {
    if (currentUserId == null || currentUserName == null) return;

    try {
      await _circlesService.addComment(
        readingId: readingId,
        userId: currentUserId!,
        userName: currentUserName!,
        userImageUrl: currentUserImageUrl,
        content: content,
        replyToId: replyToId,
      );

      _showSuccessSnackbar('Sucesso', 'Comentário adicionado');

    } catch (e) {
      debugPrint('❌ Erro ao adicionar comentário: $e');
      _showErrorSnackbar('Erro', 'Não foi possível adicionar o comentário');
    }
  }

  // ========== DISCOVERY ==========

  /// Carregar círculos para descoberta
  void loadDiscoveredCircles({
    CircleType? type,
    List<String>? tags,
  }) {
    debugPrint('=== loadDiscoveredCircles() ===');

    _circlesService.discoverCircles(
      type: type,
      tags: tags,
      searchTerm: searchQuery.value.isNotEmpty ? searchQuery.value : null,
    ).listen(
          (circles) {
        // Filtrar círculos que o usuário já é membro
        final filteredCircles = circles.where((circle) {
          return !circle.isMember(currentUserId ?? '');
        }).toList();

        discoveredCircles.value = filteredCircles;
        debugPrint('✅ ${filteredCircles.length} círculos descobertos');
      },
      onError: (e) {
        debugPrint('❌ Erro ao descobrir círculos: $e');
      },
    );
  }

  /// Solicitar entrada em círculo
  Future<void> requestToJoinCircle({
    required String circleId,
    String? message,
  }) async {
    if (currentUserId == null || currentUserName == null) return;

    try {
      debugPrint('=== requestToJoinCircle() ===');
      isLoading.value = true;

      await _circlesService.requestToJoinCircle(
        circleId: circleId,
        userId: currentUserId!,
        userName: currentUserName!,
        message: message,
      );

      _showSuccessSnackbar('Sucesso', 'Solicitação enviada com sucesso!');

      // Recarregar círculos descobertos
      loadDiscoveredCircles();

    } catch (e) {
      debugPrint('❌ Erro ao solicitar entrada: $e');
      _showErrorSnackbar('Erro', 'Não foi possível enviar a solicitação: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Buscar círculos
  Future<void> searchCircles(String query) async {
    try {
      searchQuery.value = query;

      if (query.isNotEmpty) {
        debugPrint('=== searchCircles() ===');
        debugPrint('Query: $query');

        final results = await _circlesService.searchCircles(query);

        // Filtrar círculos que o usuário já é membro
        final filteredResults = results.where((circle) {
          return !circle.isMember(currentUserId ?? '');
        }).toList();

        discoveredCircles.value = filteredResults;
        debugPrint('✅ ${filteredResults.length} resultados encontrados');
      } else {
        loadDiscoveredCircles();
      }

    } catch (e) {
      debugPrint('❌ Erro na busca: $e');
      _showErrorSnackbar('Erro', 'Erro na busca de círculos');
    }
  }

  // ========== STATISTICS ==========

  /// Carregar estatísticas do usuário
  Future<void> loadUserStatistics() async {
    if (currentUserId == null) return;

    try {
      debugPrint('=== loadUserStatistics() ===');

      final stats = await _circlesService.getUserCircleStatistics(currentUserId!);
      userStats.value = stats;

      debugPrint('✅ Estatísticas carregadas');
    } catch (e) {
      debugPrint('❌ Erro ao carregar estatísticas: $e');
    }
  }

  // ========== UI HELPERS ==========

  /// Alterar aba selecionada
  void changeTab(int index) {
    selectedTabIndex.value = index;

    // Carregar dados específicos da aba se necessário
    switch (index) {
      case 0: // Meus Círculos
        loadUserCircles();
        break;
      case 1: // Descobrir
        loadDiscoveredCircles();
        break;
      case 2: // Convites
        loadPendingInvitations();
        break;
    }
  }

  /// Filtrar por tags
  void toggleTag(String tag) {
    if (selectedTags.contains(tag)) {
      selectedTags.remove(tag);
    } else {
      selectedTags.add(tag);
    }

    // Recarregar círculos descobertos com novos filtros
    loadDiscoveredCircles(tags: selectedTags.toList());
  }

  /// Limpar filtros
  void clearFilters() {
    selectedTags.clear();
    searchQuery.value = '';
    loadDiscoveredCircles();
  }

  // ========== UTILITY METHODS ==========

  /// Verificar se usuário pode acessar círculo
  Future<bool> canAccessCircle(String circleId) async {
    if (currentUserId == null) return false;
    return await _circlesService.canAccessCircle(circleId, currentUserId!);
  }

  /// Obter círculo por ID das listas locais
  MysticCircle? getCircleById(String circleId) {
    // Procurar nos círculos do usuário primeiro
    final userCircle = userCircles.firstWhereOrNull((c) => c.id == circleId);
    if (userCircle != null) return userCircle;

    // Procurar nos círculos descobertos
    final discoveredCircle = discoveredCircles.firstWhereOrNull((c) => c.id == circleId);
    if (discoveredCircle != null) return discoveredCircle;

    return null;
  }

  /// Obter leitura por ID
  SharedReading? getReadingById(String readingId) {
    return circleReadings.firstWhereOrNull((r) => r.id == readingId);
  }

  /// Verificar se usuário é admin do círculo selecionado
  bool get isCurrentUserAdmin {
    final circle = selectedCircle.value;
    return circle != null && circle.isAdmin(currentUserId ?? '');
  }

  /// Verificar se usuário é criador do círculo selecionado
  bool get isCurrentUserCreator {
    final circle = selectedCircle.value;
    return circle != null && circle.isCreator(currentUserId ?? '');
  }

  /// Obter estatística específica
  T? getStat<T>(String key, [T? defaultValue]) {
    return userStats.value[key] as T? ?? defaultValue;
  }

  /// Verificar se há convites pendentes
  bool get hasPendingInvitations => pendingInvitations.isNotEmpty;

  /// Obter contagem total de leituras compartilhadas pelo usuário
  int? get totalReadingsShared => getStat<int>('totalReadingsShared', 0);

  /// Obter número de círculos criados pelo usuário
  int? get circlesCreated => getStat<int>('createdCircles', 0);

  /// Obter número de círculos onde é admin
  int? get circlesAsAdmin => getStat<int>('adminCircles', 0);

  // ========== VALIDATION HELPERS ==========

  /// Validar dados do círculo
  String? validateCircleData({
    required String name,
    required String description,
  }) {
    if (name.trim().isEmpty) {
      return 'Nome do círculo é obrigatório';
    }

    if (name.trim().length < 3) {
      return 'Nome deve ter pelo menos 3 caracteres';
    }

    if (name.trim().length > 50) {
      return 'Nome deve ter no máximo 50 caracteres';
    }

    if (description.trim().isEmpty) {
      return 'Descrição é obrigatória';
    }

    if (description.trim().length < 10) {
      return 'Descrição deve ter pelo menos 10 caracteres';
    }

    if (description.trim().length > 200) {
      return 'Descrição deve ter no máximo 200 caracteres';
    }

    return null;
  }

  /// Validar email para convite
  String? validateInviteEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Email é obrigatório';
    }

    if (!GetUtils.isEmail(email.trim())) {
      return 'Email inválido';
    }

    return null;
  }

  // ========== SNACKBAR HELPERS ==========

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showInfoSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      backgroundColor: const Color(0xFF6C63FF),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }

  // ========== REFRESH METHODS ==========

  /// Atualizar todos os dados
  Future<void> refreshAll() async {
    debugPrint('=== refreshAll() ===');

    if (currentUserId != null) {
      loadUserCircles();
      loadPendingInvitations();
      loadDiscoveredCircles();
      await loadUserStatistics();

      // Recarregar círculo selecionado se houver
      if (selectedCircle.value != null) {
        await selectCircle(selectedCircle.value!.id);
      }
    }
  }

  /// Atualizar dados específicos da aba atual
  Future<void> refreshCurrentTab() async {
    switch (selectedTabIndex.value) {
      case 0:
        loadUserCircles();
        break;
      case 1:
        loadDiscoveredCircles();
        break;
      case 2:
        loadPendingInvitations();
        break;
    }
  }

  @override
  void onClose() {
    debugPrint('=== MysticCirclesController.onClose() ===');
    super.onClose();
  }
}