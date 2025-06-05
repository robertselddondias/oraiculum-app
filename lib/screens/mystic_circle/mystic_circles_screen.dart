// lib/screens/circles/mystic_circles_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/mystic_circles_controller.dart';
import 'package:oraculum/models/mystic_circle_model.dart';
import 'package:oraculum/models/circle_invitation_model.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class MysticCirclesScreen extends StatefulWidget {
  const MysticCirclesScreen({super.key});

  @override
  State<MysticCirclesScreen> createState() => _MysticCirclesScreenState();
}

class _MysticCirclesScreenState extends State<MysticCirclesScreen>
    with SingleTickerProviderStateMixin {

  late final MysticCirclesController _controller;
  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(MysticCirclesController());
    _setupAnimations();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat(reverse: true);

    _topAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );

    _bottomAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(
      CurvedAnimation(
        parent: _backgroundController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  Color(0xFF1A1A2E),
                  Color(0xFF2D1B69),
                  Color(0xFF16213E),
                  Color(0xFF0F0F23),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Partículas místicas de fundo
              ...ZodiacUtils.buildStarParticles(context, isTablet ? 40 : 30),

              Column(
                children: [
                  _buildHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: Obx(() => _buildTabContent()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Obx(() => _buildFloatingActionButton()),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups,
                        color: Color(0xFF6C63FF),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Círculos Místicos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conecte-se com outros praticantes',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Obx(() => _buildNotificationBadge()),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildNotificationBadge() {
    final pendingCount = _controller.pendingInvitations.length;

    if (pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mail,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$pendingCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Obx(() => Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Meus Círculos', Icons.home),
          _buildTabItem(1, 'Descobrir', Icons.explore),
          _buildTabItem(2, 'Convites', Icons.mail,
              badgeCount: _controller.pendingInvitations.length),
        ],
      ),
    ));
  }

  Widget _buildTabItem(int index, String title, IconData icon, {int? badgeCount}) {
    final isSelected = _controller.selectedTabIndex.value == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _controller.changeTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_controller.selectedTabIndex.value) {
      case 0:
        return _buildMyCirclesTab();
      case 1:
        return _buildDiscoverTab();
      case 2:
        return _buildInvitesTab();
      default:
        return _buildMyCirclesTab();
    }
  }

  // ========== MEUS CÍRCULOS TAB ==========

  Widget _buildMyCirclesTab() {
    return RefreshIndicator(
      onRefresh: () async => _controller.loadUserCircles(),
      color: const Color(0xFF6C63FF),
      child: Obx(() {
        if (_controller.userCircles.isEmpty) {
          return _buildEmptyState(
            icon: Icons.groups_outlined,
            title: 'Nenhum círculo ainda',
            subtitle: 'Crie seu primeiro círculo místico\nou junte-se a um existente',
            buttonText: 'Criar Círculo',
            onButtonPressed: _showCreateCircleDialog,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _controller.userCircles.length,
          itemBuilder: (context, index) {
            final circle = _controller.userCircles[index];
            return _buildCircleCard(circle, index);
          },
        );
      }),
    );
  }

  Widget _buildCircleCard(MysticCircle circle, int index) {
    final isCreator = circle.isCreator(_controller.currentUserId ?? '');
    final isAdmin = circle.isAdmin(_controller.currentUserId ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        color: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: _getCircleTypeColor(circle.type).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCircleDetails(circle),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getCircleTypeColor(circle.type).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getCircleTypeIcon(circle.type),
                        color: _getCircleTypeColor(circle.type),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  circle.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCreator)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'CRIADOR',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else if (isAdmin)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            circle.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: _buildStatChip(
                        icon: Icons.people,
                        value: '${circle.totalMembers}',
                        label: 'membros',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 2,
                      child: _buildStatChip(
                        icon: Icons.auto_stories,
                        value: '${circle.stats.totalReadings}',
                        label: 'leituras',
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      flex: 2,
                      child: _buildStatChip(
                        icon: Icons.comment,
                        value: '${circle.stats.totalComments}',
                        label: 'comentários',
                        color: Colors.green,
                      ),
                    ),
                    const Spacer(flex: 1),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.5),
                      size: 14,
                    ),
                  ],
                ),
                if (circle.tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: circle.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== DESCOBRIR TAB ==========

Widget _buildDiscoverTab() {
  return Column(
    children: [
      _buildSearchBar(),
      _buildFilterChips(),
      Expanded(
        child: RefreshIndicator(
          onRefresh: () async => _controller.loadDiscoveredCircles(),
          color: const Color(0xFF6C63FF),
          child: Obx(() {
            if (_controller.discoveredCircles.isEmpty) {
              return _buildEmptyState(
                icon: Icons.explore_outlined,
                title: 'Nenhum círculo encontrado',
                subtitle: 'Tente ajustar os filtros de busca\nou criar seu próprio círculo',
                buttonText: 'Limpar Filtros',
                onButtonPressed: _controller.clearFilters,
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _controller.discoveredCircles.length,
              itemBuilder: (context, index) {
                final circle = _controller.discoveredCircles[index];
                return _buildDiscoverCircleCard(circle, index);
              },
            );
          }),
        ),
      ),
    ],
  );
}

Widget _buildSearchBar() {
  return Container(
    margin: const EdgeInsets.all(20),
    child: TextField(
      onChanged: _controller.searchCircles,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Buscar círculos...',
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.search, color: Colors.white54),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(
            color: Color(0xFF6C63FF),
            width: 2,
          ),
        ),
      ),
    ),
  );
}

Widget _buildFilterChips() {
  final tags = ['Tarô', 'Astrologia', 'Numerologia', 'Meditação', 'Cristais', 'Runas'];

  return Container(
    height: 50,
    margin: const EdgeInsets.symmetric(horizontal: 20),
    child: Obx(() => ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: tags.length,
      itemBuilder: (context, index) {
        final tag = tags[index];
        final isSelected = _controller.selectedTags.contains(tag);

        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (_) => _controller.toggleTag(tag),
            backgroundColor: Colors.black.withOpacity(0.3),
            selectedColor: const Color(0xFF6C63FF).withOpacity(0.3),
            labelStyle: TextStyle(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.2),
            ),
          ),
        );
      },
    )),
  );
}

Widget _buildDiscoverCircleCard(MysticCircle circle, int index) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: _getCircleTypeColor(circle.type).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCircleTypeColor(circle.type).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCircleTypeIcon(circle.type),
                    color: _getCircleTypeColor(circle.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        circle.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.people,
                  value: '${circle.totalMembers}',
                  label: 'membros',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.auto_stories,
                  value: '${circle.stats.totalReadings}',
                  label: 'leituras',
                  color: Colors.purple,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _controller.requestToJoinCircle(circleId: circle.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        circle.settings.requireApproval ? 'Solicitar' : 'Entrar',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (circle.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: circle.tags.take(4).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    ),
  ).animate(delay: Duration(milliseconds: index * 100))
      .fadeIn(duration: 600.ms)
      .slideX(begin: 0.1, end: 0);
}

// ========== CONVITES TAB ==========

Widget _buildInvitesTab() {
  return RefreshIndicator(
    onRefresh: () async => _controller.loadPendingInvitations(),
    color: const Color(0xFF6C63FF),
    child: Obx(() {
      if (_controller.pendingInvitations.isEmpty) {
        return _buildEmptyState(
          icon: Icons.mail_outline,
          title: 'Nenhum convite pendente',
          subtitle: 'Quando alguém te convidar para\num círculo, aparecerá aqui',
          buttonText: 'Descobrir Círculos',
          onButtonPressed: () => _controller.changeTab(1),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _controller.pendingInvitations.length,
        itemBuilder: (context, index) {
          final invitation = _controller.pendingInvitations[index];
          return _buildInvitationCard(invitation, index);
        },
      );
    }),
  );
}

Widget _buildInvitationCard(CircleInvitation invitation, int index) {
  return AnimatedContainer(
    duration: Duration(milliseconds: 300 + (index * 50)),
    curve: Curves.easeOutQuad,
    margin: const EdgeInsets.only(bottom: 16),
    child: Card(
      elevation: 8,
      color: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: const Color(0xFF6C63FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mail,
                    color: Color(0xFF6C63FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Convite para ${invitation.circleName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Convidado por ${invitation.inviterName}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (invitation.message != null && invitation.message!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  invitation.message!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  _formatDate(invitation.createdAt),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 70,
                  height: 32,
                  child: TextButton(
                    onPressed: () => _controller.respondToInvitation(
                      invitationId: invitation.id,
                      accept: false,
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const FittedBox(
                      child: Text(
                        'Recusar',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () => _controller.respondToInvitation(
                      invitationId: invitation.id,
                      accept: true,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const FittedBox(
                      child: Text(
                        'Aceitar',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ========== HELPER WIDGETS ==========

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
  required String buttonText,
  required VoidCallback onButtonPressed,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onButtonPressed,
            icon: const Icon(Icons.add),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatChip({
  required IconData icon,
  required String value,
  required String label,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    ),
  );
}

Widget _buildFloatingActionButton() {
  if (_controller.selectedTabIndex.value != 0) {
    return const SizedBox.shrink();
  }

  return FloatingActionButton.extended(
    onPressed: _showCreateCircleDialog,
    backgroundColor: const Color(0xFF6C63FF),
    foregroundColor: Colors.white,
    icon: const Icon(Icons.add),
    label: const Text('Criar Círculo'),
  );
}

// ========== HELPER METHODS ==========

Color _getCircleTypeColor(CircleType type) {
  switch (type) {
    case CircleType.friends:
      return Colors.blue;
    case CircleType.family:
      return Colors.green;
    case CircleType.studyGroup:
      return Colors.purple;
    case CircleType.open:
      return Colors.orange;
  }
}

IconData _getCircleTypeIcon(CircleType type) {
  switch (type) {
    case CircleType.friends:
      return Icons.people;
    case CircleType.family:
      return Icons.family_restroom;
    case CircleType.studyGroup:
      return Icons.school;
    case CircleType.open:
      return Icons.public;
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays > 0) {
    return '${difference.inDays}d atrás';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h atrás';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m atrás';
  } else {
    return 'Agora';
  }
}

void _openCircleDetails(MysticCircle circle) {
  _controller.selectCircle(circle.id);
  Get.toNamed(AppRoutes.circleDetails, parameters: {'circleId': circle.id});
}

void _showCreateCircleDialog() {
  Get.dialog(_CreateCircleDialog(controller: _controller));
}
}

// ========== CREATE CIRCLE DIALOG ==========

class _CreateCircleDialog extends StatefulWidget {
  final MysticCirclesController controller;

  const _CreateCircleDialog({required this.controller});

  @override
  State<_CreateCircleDialog> createState() => _CreateCircleDialogState();
}

class _CreateCircleDialogState extends State<_CreateCircleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  CircleType _selectedType = CircleType.friends;
  bool _isPrivate = true;
  bool _requireApproval = false;
  final List<String> _selectedTags = [];

  final List<String> _availableTags = [
    'Tarô', 'Astrologia', 'Numerologia', 'Meditação', 'Cristais', 'Runas',
    'Iniciantes', 'Avançado', 'Estudos', 'Prática', 'Discussão'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogHeader(),
                const SizedBox(height: 24),
                _buildNameField(),
                const SizedBox(height: 16),
                _buildDescriptionField(),
                const SizedBox(height: 16),
                _buildTypeSelector(),
                const SizedBox(height: 16),
                _buildSettingsToggle(),
                const SizedBox(height: 16),
                _buildTagsSelector(),
                const SizedBox(height: 24),
                _buildDialogActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_circle,
            color: Color(0xFF6C63FF),
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Criar Novo Círculo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Nome do Círculo',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Nome é obrigatório';
        }
        if (value.trim().length < 3) {
          return 'Nome deve ter pelo menos 3 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: const TextStyle(color: Colors.white),
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Descrição',
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Descrição é obrigatória';
        }
        if (value.trim().length < 10) {
          return 'Descrição deve ter pelo menos 10 caracteres';
        }
        return null;
      },
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo do Círculo',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CircleType.values.map((type) {
            final isSelected = _selectedType == type;
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getTypeLabel(type),
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSettingsToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configurações',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Círculo Privado', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Apenas membros convidados', style: TextStyle(color: Colors.white70)),
          value: _isPrivate,
          onChanged: (value) => setState(() => _isPrivate = value),
          activeColor: const Color(0xFF6C63FF),
        ),
        SwitchListTile(
          title: const Text('Aprovar Novos Membros', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Administradores devem aprovar solicitações', style: TextStyle(color: Colors.white70)),
          value: _requireApproval,
          onChanged: (value) => setState(() => _requireApproval = value),
          activeColor: const Color(0xFF6C63FF),
        ),
      ],
    );
  }

  Widget _buildTagsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags (opcional)',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else if (_selectedTags.length < 5) {
                    _selectedTags.add(tag);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6C63FF).withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedTags.length >= 5)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Máximo de 5 tags permitidas',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDialogActions() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Obx(() => ElevatedButton(
            onPressed: widget.controller.isCreatingCircle.value
                ? null
                : _createCircle,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: widget.controller.isCreatingCircle.value
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Text('Criar Círculo'),
          )),
        ),
      ],
    );
  }

  String _getTypeLabel(CircleType type) {
    switch (type) {
      case CircleType.friends:
        return 'Amigos';
      case CircleType.family:
        return 'Família';
      case CircleType.studyGroup:
        return 'Grupo de Estudo';
      case CircleType.open:
        return 'Aberto';
    }
  }

  void _createCircle() {
    if (!_formKey.currentState!.validate()) return;

    final settings = CircleSettings(
      isPrivate: _isPrivate,
      requireApproval: _requireApproval,
    );

    widget.controller.createCircle(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _selectedType,
      settings: settings,
      tags: _selectedTags,
    ).then((_) {
      Navigator.pop(context);
    });
  }
}
