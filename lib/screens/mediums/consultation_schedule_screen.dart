// lib/screens/mediums/consultation_schedule_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/consultation_schedule_controller.dart';
import 'package:oraculum/models/consultation_request_model.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class ConsultationScheduleScreen extends StatefulWidget {
  const ConsultationScheduleScreen({super.key});

  @override
  State<ConsultationScheduleScreen> createState() => _ConsultationScheduleScreenState();
}

class _ConsultationScheduleScreenState extends State<ConsultationScheduleScreen>
    with SingleTickerProviderStateMixin {

  final ConsultationScheduleController _controller = Get.put(ConsultationScheduleController());

  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _topAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
    ]).animate(_backgroundController);

    _bottomAlignmentAnimation = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomRight,
          end: Alignment.bottomLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.bottomLeft,
          end: Alignment.topLeft,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<Alignment>(
          begin: Alignment.topRight,
          end: Alignment.bottomRight,
        ),
        weight: 1,
      ),
    ]).animate(_backgroundController);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    Get.delete<ConsultationScheduleController>();
    super.dispose();
  }

  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth >= 600;

    return {
      'padding': isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0,
      'cardPadding': isTablet ? 24.0 : isSmallScreen ? 16.0 : 20.0,
      'titleSize': isTablet ? 28.0 : isSmallScreen ? 20.0 : 24.0,
      'subtitleSize': isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0,
      'bodySize': isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0,
      'iconSize': isTablet ? 28.0 : isSmallScreen ? 20.0 : 24.0,
      'spacing': isTablet ? 24.0 : isSmallScreen ? 16.0 : 20.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = _getResponsiveDimensions(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
                colors: const [
                  Color(0xFF392F5A),
                  Color(0xFF483D8B),
                  Color(0xFF8C6BAE),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              ...ZodiacUtils.buildStarParticles(context, isTablet ? 35 : 25),

              Column(
                children: [
                  _buildAppBar(dimensions),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _controller.refreshRequests,
                      color: const Color(0xFF8C6BAE),
                      child: Obx(() => _controller.isLoading
                          ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                          : _buildContent(dimensions)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showScheduleDialog(),
        backgroundColor: const Color(0xFF8C6BAE),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar(Map<String, double> dimensions) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dimensions['padding']!,
        vertical: 8.0,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: dimensions['iconSize']!,
            ),
            onPressed: () => Get.back(),
            splashRadius: 24,
          ),

          Expanded(
            child: Text(
              'Agenda de Consultas',
              style: TextStyle(
                color: Colors.white,
                fontSize: dimensions['titleSize']! - 4,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          IconButton(
            icon: Icon(
              Icons.calendar_today,
              color: Colors.white,
              size: dimensions['iconSize']!,
            ),
            onPressed: () => _showDatePicker(),
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, double> dimensions) {
    return Column(
      children: [
        _buildFilterChips(dimensions),

        SizedBox(height: dimensions['spacing']!),

        _buildStatCards(dimensions),

        SizedBox(height: dimensions['spacing']!),

        Expanded(
          child: _buildRequestsList(dimensions),
        ),
      ],
    );
  }

  Widget _buildFilterChips(Map<String, double> dimensions) {
    final filters = [
      {'key': 'all', 'label': 'Todas', 'icon': Icons.list},
      {'key': 'pending', 'label': 'Pendentes', 'icon': Icons.pending},
      {'key': 'scheduled', 'label': 'Agendadas', 'icon': Icons.schedule},
      {'key': 'today', 'label': 'Hoje', 'icon': Icons.today},
      {'key': 'completed', 'label': 'Concluídas', 'icon': Icons.check_circle},
    ];

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: dimensions['padding']!),
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _controller.selectedFilter == filter['key'];

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : const Color(0xFF8C6BAE),
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label'] as String),
                ],
              ),
              onSelected: (selected) => _controller.setSelectedFilter(filter['key'] as String),
              backgroundColor: Colors.white.withOpacity(0.1),
              selectedColor: const Color(0xFF8C6BAE),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF8C6BAE),
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFF8C6BAE) : Colors.white.withOpacity(0.3),
              ),
            ),
          );
        },
      )),
    );
  }

  Widget _buildStatCards(Map<String, double> dimensions) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: dimensions['padding']!),
      child: Obx(() => Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Pendentes',
              _controller.pendingCount.toString(),
              Icons.pending_actions,
              Colors.orange,
              dimensions,
            ),
          ),

          SizedBox(width: dimensions['spacing']!),

          Expanded(
            child: _buildStatCard(
              'Agendadas',
              _controller.scheduledCount.toString(),
              Icons.event_available,
              Colors.blue,
              dimensions,
            ),
          ),

          SizedBox(width: dimensions['spacing']!),

          Expanded(
            child: _buildStatCard(
              'Hoje',
              _controller.todayCount.toString(),
              Icons.today,
              Colors.green,
              dimensions,
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, Map<String, double> dimensions) {
    return Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(dimensions['cardPadding']! / 1.5),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: dimensions['iconSize']!,
            ),

            SizedBox(height: dimensions['spacing']! / 2),

            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: dimensions['subtitleSize']!,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              title,
              style: TextStyle(
                color: Colors.white70,
                fontSize: dimensions['bodySize']! - 2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(Map<String, double> dimensions) {
    return Obx(() {
      final filteredRequests = _controller.filteredRequests;

      if (filteredRequests.isEmpty) {
        return Center(
          child: Card(
            color: Colors.black.withOpacity(0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(dimensions['cardPadding']!),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_busy,
                    color: Colors.white70,
                    size: dimensions['iconSize']! * 2,
                  ),

                  SizedBox(height: dimensions['spacing']!),

                  Text(
                    'Nenhuma solicitação encontrada',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: dimensions['subtitleSize']!,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: dimensions['spacing']! / 2),

                  Text(
                    'Suas solicitações de consulta aparecerão aqui',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: dimensions['bodySize']!,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return ListView.builder(
        padding: EdgeInsets.all(dimensions['padding']!),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          final request = filteredRequests[index];
          return _buildRequestCard(request, dimensions);
        },
      );
    });
  }

  Widget _buildRequestCard(ConsultationRequest request, Map<String, double> dimensions) {
    final statusColor = _getStatusColor(request.status);
    final statusText = _getStatusText(request.status);

    return Card(
      elevation: 8,
      margin: EdgeInsets.only(bottom: dimensions['spacing']!),
      color: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(dimensions['cardPadding']!),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.clientName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: dimensions['subtitleSize']!,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: dimensions['spacing']! / 3),

                      Text(
                        request.consultationType,
                        style: TextStyle(
                          color: const Color(0xFF8C6BAE),
                          fontSize: dimensions['bodySize']!,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: dimensions['bodySize']! - 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: dimensions['spacing']!),

            if (request.description.isNotEmpty) ...[
              Text(
                request.description,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: dimensions['bodySize']!,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: dimensions['spacing']!),
            ],

            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Colors.white70,
                  size: 16,
                ),

                const SizedBox(width: 4),

                Text(
                  'Solicitado em ${DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt)}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: dimensions['bodySize']! - 2,
                  ),
                ),
              ],
            ),

            if (request.scheduledDate != null) ...[
              SizedBox(height: dimensions['spacing']! / 2),

              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: Colors.green,
                    size: 16,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    'Agendado para ${DateFormat('dd/MM/yyyy HH:mm').format(request.scheduledDate!)}',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: dimensions['bodySize']! - 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            SizedBox(height: dimensions['spacing']!),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (request.status == ConsultationStatus.pending) ...[
                  TextButton(
                    onPressed: () => _controller.acceptRequest(request),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Aceitar'),
                  ),

                  const SizedBox(width: 8),

                  TextButton(
                    onPressed: () => _controller.showDeclineDialog(request),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.2),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Recusar'),
                  ),
                ],

                if (request.status == ConsultationStatus.scheduled) ...[
                  TextButton(
                    onPressed: () => _controller.showScheduleDialog(request),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.2),
                      foregroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Reagendar'),
                  ),

                  const SizedBox(width: 8),

                  TextButton(
                    onPressed: () => _controller.showCompletionDialog(request),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF8C6BAE).withOpacity(0.2),
                      foregroundColor: const Color(0xFF8C6BAE),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Text('Concluir'),
                  ),
                ],

                TextButton(
                  onPressed: () => _viewRequestDetails(request),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text('Detalhes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.pending:
        return Colors.orange;
      case ConsultationStatus.scheduled:
        return Colors.blue;
      case ConsultationStatus.completed:
        return Colors.green;
      case ConsultationStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(ConsultationStatus status) {
    switch (status) {
      case ConsultationStatus.pending:
        return 'Pendente';
      case ConsultationStatus.scheduled:
        return 'Agendada';
      case ConsultationStatus.completed:
        return 'Concluída';
      case ConsultationStatus.cancelled:
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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

    if (picked != null) {
      _controller.setSelectedDate(picked);
    }
  }

  void _showScheduleDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF392F5A),
        title: const Text('Nova Consulta', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Funcionalidade em desenvolvimento.\nEm breve você poderá criar novos horários disponíveis.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar', style: TextStyle(color: Color(0xFF8C6BAE))),
          ),
        ],
      ),
    );
  }

  void _viewRequestDetails(ConsultationRequest request) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF392F5A),
        title: Text('Detalhes da Consulta', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Cliente:', request.clientName),
              _buildDetailRow('Tipo:', request.consultationType),
              _buildDetailRow('Status:', _getStatusText(request.status)),
              _buildDetailRow('Solicitado em:', DateFormat('dd/MM/yyyy HH:mm').format(request.createdAt)),

              if (request.scheduledDate != null)
                _buildDetailRow('Agendado para:', DateFormat('dd/MM/yyyy HH:mm').format(request.scheduledDate!)),

              if (request.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Descrição:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.description,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],

              if (request.notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Observações:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  request.notes,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Fechar', style: TextStyle(color: Color(0xFF8C6BAE))),
          ),

          if (request.status == ConsultationStatus.pending)
            TextButton(
              onPressed: () {
                Get.back();
                _controller.acceptRequest(request);
              },
              child: const Text('Aceitar', style: TextStyle(color: Colors.green)),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}