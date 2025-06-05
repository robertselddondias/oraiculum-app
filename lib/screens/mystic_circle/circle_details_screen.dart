// lib/screens/circles/circle_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/mystic_circles_controller.dart';
import 'package:oraculum/models/mystic_circle_model.dart';
import 'package:oraculum/models/shared_reading_model.dart';
import 'package:oraculum/utils/zodiac_utils.dart';

class CircleDetailsScreen extends StatefulWidget {
  const CircleDetailsScreen({super.key});

  @override
  State<CircleDetailsScreen> createState() => _CircleDetailsScreenState();
}

class _CircleDetailsScreenState extends State<CircleDetailsScreen>
    with SingleTickerProviderStateMixin {

  late final MysticCirclesController _controller;
  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  final String circleId = Get.parameters['circleId'] ?? '';

  @override
  void initState() {
    super.initState();
    _controller = Get.find<MysticCirclesController>();
    _setupAnimations();

    if (circleId.isNotEmpty) {
      _controller.selectCircle(circleId);
    }
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _topAlignmentAnimation = Tween<Alignment>(
      begin: Alignment.topLeft,
      end: Alignment.topCenter,
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
                  Color(0xFF2D1B69),
                  Color(0xFF1A1A2E),
                  Color(0xFF16213E),
                ],
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Stack(
            children: [
              // Partículas místicas
              ...ZodiacUtils.buildStarParticles(context, 25),

              Obx(() {
                final circle = _controller.selectedCircle.value;
                if (circle == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  );
                }

                return _buildCircleContent(circle);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleContent(MysticCircle circle) {
    return DefaultTabController(
      length: 3,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildSliverAppBar(circle),
          _buildSliverTabBar(),
        ],
        body: TabBarView(
          children: [
            _buildReadingsTab(),
            _buildMembersTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(MysticCircle circle) {
    final isCreator = circle.isCreator(_controller.currentUserId ?? '');
    final isAdmin = circle.isAdmin(_controller.currentUserId ?? '');

    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      ),
      actions: [
        if (isAdmin)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF2A2A40),
            onSelected: (value) => _handleMenuAction(value, circle),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'invite',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Convidar Membros', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              if (isCreator) ...[
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Configurações', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Excluir Círculo', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ],
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getCircleTypeColor(circle.type).withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Space for app bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getCircleTypeColor(circle.type).withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getCircleTypeColor(circle.type).withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _getCircleTypeIcon(circle.type),
                    color: _getCircleTypeColor(circle.type),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  circle.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  circle.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(
                      icon: Icons.people,
                      value: '${circle.totalMembers}',
                      label: 'Membros',
                      color: Colors.blue,
                    ),
                    _buildStatColumn(
                      icon: Icons.auto_stories,
                      value: '${circle.stats.totalReadings}',
                      label: 'Leituras',
                      color: Colors.purple,
                    ),
                    _buildStatColumn(
                      icon: Icons.comment,
                      value: '${circle.stats.totalComments}',
                      label: 'Comentários',
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverTabBar() {
    return SliverPersistentHeader(
      delegate: _SliverTabBarDelegate(
        TabBar(
          indicatorColor: const Color(0xFF6C63FF),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Leituras', icon: Icon(Icons.auto_stories, size: 20)),
            Tab(text: 'Membros', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Sobre', icon: Icon(Icons.info, size: 20)),
          ],
        ),
      ),
      pinned: true,
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ========== READINGS TAB ==========

  Widget _buildReadingsTab() {
    return Obx(() {
      if (_controller.circleReadings.isEmpty) {
        return _buildEmptyReadings();
      }

      return RefreshIndicator(
        onRefresh: () async {
          _controller.loadCircleReadings(circleId);
        },
        color: const Color(0xFF6C63FF),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _controller.circleReadings.length,
          itemBuilder: (context, index) {
            final reading = _controller.circleReadings[index];
            return _buildReadingCard(reading, index);
          },
        ),
      );
    });
  }

  Widget _buildEmptyReadings() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories_outlined,
                        size: 64,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Nenhuma leitura ainda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Seja o primeiro a compartilhar\numa leitura neste círculo',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: ElevatedButton.icon(
                      onPressed: _showShareReadingDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Compartilhar Leitura'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(SharedReading reading, int index) {
    final isOwnReading = reading.userId == _controller.currentUserId;

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
            color: _getReadingTypeColor(reading.type).withOpacity(0.3),
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
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: reading.userImageUrl != null
                        ? NetworkImage(reading.userImageUrl!)
                        : null,
                    backgroundColor: _getReadingTypeColor(reading.type).withOpacity(0.3),
                    child: reading.userImageUrl == null
                        ? Icon(
                      Icons.person,
                      color: _getReadingTypeColor(reading.type),
                      size: 20,
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              reading.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isOwnReading) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'VOCÊ',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _formatDateTime(reading.createdAt),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getReadingTypeColor(reading.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getReadingTypeLabel(reading.type),
                      style: TextStyle(
                        color: _getReadingTypeColor(reading.type),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                reading.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reading.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildReadingAction(
                    icon: reading.isLikedBy(_controller.currentUserId ?? '')
                        ? Icons.favorite
                        : Icons.favorite_border,
                    label: '${reading.likesCount}',
                    color: Colors.red,
                    onTap: () {
                      if (reading.isLikedBy(_controller.currentUserId ?? '')) {
                        _controller.unlikeReading(reading.id);
                      } else {
                        _controller.likeReading(reading.id);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildReadingAction(
                    icon: Icons.comment_outlined,
                    label: '${reading.commentsCount}',
                    color: Colors.blue,
                    onTap: () => _showCommentsDialog(reading),
                  ),
                  const SizedBox(width: 16),
                  _buildReadingAction(
                    icon: Icons.share_outlined,
                    label: 'Compartilhar',
                    color: Colors.green,
                    onTap: () => _shareReading(reading),
                  ),
                  const Spacer(),
                  if (reading.tags.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      children: reading.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ========== MEMBERS TAB ==========

  Widget _buildMembersTab() {
    final circle = _controller.selectedCircle.value;
    if (circle == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMembersList(circle),
        const SizedBox(height: 24),
        if (circle.isAdmin(_controller.currentUserId ?? ''))
          _buildInviteButton(),
      ],
    );
  }

  Widget _buildMembersList(MysticCircle circle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Membros (${circle.totalMembers})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Aqui você precisaria implementar a busca de dados dos membros
        // Por simplicidade, vou mostrar apenas o conceito
        ...circle.memberIds.map((memberId) {
          final isCreator = circle.isCreator(memberId);
          final isAdmin = circle.isAdmin(memberId);
          final isCurrentUser = memberId == _controller.currentUserId;

          return _buildMemberCard(
            memberId: memberId,
            isCreator: isCreator,
            isAdmin: isAdmin,
            isCurrentUser: isCurrentUser,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildMemberCard({
    required String memberId,
    required bool isCreator,
    required bool isAdmin,
    required bool isCurrentUser,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: Colors.black.withOpacity(0.3),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.3),
            child: const Icon(Icons.person, color: Color(0xFF6C63FF)),
          ),
          title: Row(
            children: [
              Text(
                'Membro $memberId', // Aqui você carregaria o nome real
                style: const TextStyle(color: Colors.white),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VOCÊ',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            isCreator ? 'Criador' : isAdmin ? 'Administrador' : 'Membro',
            style: TextStyle(
              color: isCreator ? Colors.amber : isAdmin ? Colors.blue : Colors.white70,
            ),
          ),
          trailing: !isCurrentUser && _controller.isCurrentUserAdmin
              ? PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            color: const Color(0xFF2A2A40),
            onSelected: (value) => _handleMemberAction(value, memberId),
            itemBuilder: (context) => [
              if (!isCreator) ...[
                PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      const Icon(Icons.remove_circle, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Remover', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                if (!isAdmin && _controller.isCurrentUserCreator)
                  PopupMenuItem(
                    value: 'promote',
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Tornar Admin', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
              ],
            ],
          )
              : null,
        ),
      ),
    );
  }

  Widget _buildInviteButton() {
    return ElevatedButton.icon(
      onPressed: _showInviteDialog,
      icon: const Icon(Icons.person_add),
      label: const Text('Convidar Membros'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ========== SETTINGS TAB ==========

  Widget _buildSettingsTab() {
    final circle = _controller.selectedCircle.value;
    if (circle == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoSection(circle),
        const SizedBox(height: 24),
        _buildStatisticsSection(circle),
        const SizedBox(height: 24),
        _buildActionsSection(circle),
      ],
    );
  }

  Widget _buildInfoSection(MysticCircle circle) {
    return Card(
      color: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tipo', _getCircleTypeLabel(circle.type)),
            _buildInfoRow('Criado em', _formatDateTime(circle.createdAt)),
            _buildInfoRow('Privacidade', circle.settings.isPrivate ? 'Privado' : 'Público'),
            _buildInfoRow('Aprovação', circle.settings.requireApproval ? 'Necessária' : 'Automática'),
            if (circle.tags.isNotEmpty)
              _buildInfoRow('Tags', circle.tags.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(MysticCircle circle) {
    return Card(
      color: Colors.black.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    value: '${circle.totalMembers}',
                    label: 'Membros',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.auto_stories,
                    value: '${circle.stats.totalReadings}',
                    label: 'Leituras',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.comment,
                    value: '${circle.stats.totalComments}',
                    label: 'Comentários',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.trending_up,
                    value: '${circle.stats.weeklyActivity}',
                    label: 'Atividade',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(MysticCircle circle) {
    final isCurrentUserAdmin = circle.isAdmin(_controller.currentUserId ?? '');
    final isCurrentUserCreator = circle.isCreator(_controller.currentUserId ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCurrentUserAdmin) ...[
          ElevatedButton.icon(
            onPressed: _showInviteDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Convidar Membros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ElevatedButton.icon(
          onPressed: _showShareReadingDialog,
          icon: const Icon(Icons.auto_stories),
          label: const Text('Compartilhar Leitura'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!isCurrentUserCreator)
          TextButton.icon(
            onPressed: () => _showLeaveCircleDialog(circle),
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            label: const Text(
              'Sair do Círculo',
              style: TextStyle(color: Colors.red),
            ),
          ),
        if (isCurrentUserCreator)
          TextButton.icon(
            onPressed: () => _showDeleteCircleDialog(circle),
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: const Text(
              'Excluir Círculo',
              style: TextStyle(color: Colors.red),
            ),
          ),
      ],
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

  String _getCircleTypeLabel(CircleType type) {
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

  Color _getReadingTypeColor(ReadingType type) {
    switch (type) {
      case ReadingType.tarot:
        return Colors.purple;
      case ReadingType.astrology:
        return Colors.blue;
      case ReadingType.oracle:
        return Colors.green;
      case ReadingType.runes:
        return Colors.orange;
      case ReadingType.numerology:
        return Colors.red;
    }
  }

  String _getReadingTypeLabel(ReadingType type) {
    switch (type) {
      case ReadingType.tarot:
        return 'Tarô';
      case ReadingType.astrology:
        return 'Astrologia';
      case ReadingType.oracle:
        return 'Oráculo';
      case ReadingType.runes:
        return 'Runas';
      case ReadingType.numerology:
        return 'Numerologia';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  // ========== DIALOG METHODS ==========

  void _handleMenuAction(String action, MysticCircle circle) {
    switch (action) {
      case 'invite':
        _showInviteDialog();
        break;
      case 'settings':
        _showCircleSettingsDialog(circle);
        break;
      case 'delete':
        _showDeleteCircleDialog(circle);
        break;
    }
  }

  void _handleMemberAction(String action, String memberId) {
    switch (action) {
      case 'remove':
        _removeMember(memberId);
        break;
      case 'promote':
        _promoteMember(memberId);
        break;
    }
  }

  void _showInviteDialog() {
    final emailController = TextEditingController();
    final messageController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Color(0xFF6C63FF)),
            SizedBox(width: 12),
            Text('Convidar Membro', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email do usuário',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Mensagem (opcional)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _controller.inviteToCircle(
                  circleId: circleId,
                  inviteeEmail: emailController.text.trim(),
                  message: messageController.text.trim().isNotEmpty
                      ? messageController.text.trim()
                      : null,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Enviar Convite'),
          ),
        ],
      ),
    );
  }

  void _showShareReadingDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    ReadingType selectedType = ReadingType.tarot;

    Get.dialog(
      Dialog(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_stories,
                        color: Colors.purple,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Compartilhar Leitura',
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
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Título da Leitura',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Descrição',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tipo de Leitura',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                StatefulBuilder(
                  builder: (context, setState) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ReadingType.values.map((type) {
                        final isSelected = selectedType == type;
                        return GestureDetector(
                          onTap: () => setState(() => selectedType = type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getReadingTypeColor(type).withOpacity(0.3)
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _getReadingTypeColor(type)
                                    : Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              _getReadingTypeLabel(type),
                              style: TextStyle(
                                color: isSelected ? _getReadingTypeColor(type) : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleController.text.isNotEmpty &&
                              descriptionController.text.isNotEmpty) {
                            _controller.shareReading(
                              circleId: circleId,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim(),
                              type: selectedType,
                              readingData: {
                                'type': selectedType.toString().split('.').last,
                                'timestamp': DateTime.now().toIso8601String(),
                              },
                            );
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Compartilhar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCommentsDialog(SharedReading reading) {
    final commentController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.comment, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Comentários (${reading.commentsCount})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: reading.comments.isEmpty
                    ? const Center(
                  child: Text(
                    'Nenhum comentário ainda',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: reading.comments.length,
                  itemBuilder: (context, index) {
                    final comment = reading.comments[index];
                    return _buildCommentItem(comment);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Adicionar comentário...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        if (commentController.text.trim().isNotEmpty) {
                          _controller.addComment(
                            readingId: reading.id,
                            content: commentController.text.trim(),
                          );
                          commentController.clear();
                        }
                      },
                      icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentItem(ReadingComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundImage: comment.userImageUrl != null
                    ? NetworkImage(comment.userImageUrl!)
                    : null,
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.3),
                child: comment.userImageUrl == null
                    ? const Icon(Icons.person, color: Color(0xFF6C63FF), size: 12)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                comment.userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _formatDateTime(comment.createdAt),
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCircleDialog(MysticCircle circle) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever, color: Colors.red),
            SizedBox(width: 12),
            Text('Excluir Círculo', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Tem certeza que deseja excluir o círculo "${circle.name}"? Esta ação não pode ser desfeita.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.deleteCircle(circle.id).then((_) {
                Navigator.pop(context); // Voltar para a tela anterior
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showLeaveCircleDialog(MysticCircle circle) {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.orange),
            SizedBox(width: 12),
            Text('Sair do Círculo', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Tem certeza que deseja sair do círculo "${circle.name}"?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.removeMember(
                circleId: circle.id,
                memberId: _controller.currentUserId!,
              ).then((_) {
                Navigator.pop(context); // Voltar para a tela anterior
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  void _showCircleSettingsDialog(MysticCircle circle) {
    // Implementar dialog de configurações do círculo
    Get.snackbar(
      'Em Desenvolvimento',
      'Funcionalidade de configurações em breve!',
      backgroundColor: const Color(0xFF6C63FF),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _removeMember(String memberId) {
    _controller.removeMember(
      circleId: circleId,
      memberId: memberId,
    );
  }

  void _promoteMember(String memberId) {
    // Implementar promoção de membro
    Get.snackbar(
      'Em Desenvolvimento',
      'Funcionalidade de promoção em breve!',
      backgroundColor: const Color(0xFF6C63FF),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _shareReading(SharedReading reading) {
    // Implementar compartilhamento externo
    Get.snackbar(
      'Compartilhar',
      'Funcionalidade de compartilhamento em desenvolvimento',
      backgroundColor: const Color(0xFF6C63FF),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}

// ========== CUSTOM SLIVER TAB BAR DELEGATE ==========

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context,
      double shrinkOffset,
      bool overlapsContent,
      ) {
    return Container(
      color: const Color(0xFF1A1A2E).withOpacity(0.9),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}