import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:oraculum/controllers/notification_controller.dart';
import 'package:oraculum/config/routes.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen>
    with SingleTickerProviderStateMixin {

  final NotificationController _notificationController = Get.find<NotificationController>();

  late AnimationController _backgroundController;
  late Animation<Alignment> _topAlignmentAnimation;
  late Animation<Alignment> _bottomAlignmentAnimation;

  String _selectedFilter = 'all'; // all, unread, horoscope, appointment, promotion
  final List<String> _filterOptions = [
    'all',
    'unread',
    'horoscope',
    'appointment',
    'promotion',
    'default'
  ];

  final Map<String, String> _filterLabels = {
    'all': 'Todas',
    'unread': 'Não Lidas',
    'horoscope': 'Horóscopo',
    'appointment': 'Consultas',
    'promotion': 'Promoções',
    'default': 'Gerais',
  };

  final Map<String, IconData> _filterIcons = {
    'all': Icons.notifications,
    'unread': Icons.mark_email_unread,
    'horoscope': Icons.auto_awesome,
    'appointment': Icons.event,
    'promotion': Icons.local_offer,
    'default': Icons.info,
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
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

  List<Map<String, dynamic>> _getFilteredNotifications() {
    final notifications = _notificationController.notifications;

    switch (_selectedFilter) {
      case 'unread':
        return notifications.where((n) => n['read'] == false).toList();
      case 'horoscope':
      case 'appointment':
      case 'promotion':
      case 'default':
        return notifications.where((n) {
          final type = n['data']?['type'] ?? 'default';
          return type == _selectedFilter;
        }).toList();
      default:
        return notifications.toList();
    }
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
          child: Column(
            children: [
              _buildAppBar(),
              _buildFilterBar(),
              Expanded(
                child: Obx(() {
                  final filteredNotifications = _getFilteredNotifications();

                  if (filteredNotifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      // Aqui você pode implementar a lógica de refresh
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    color: const Color(0xFF6C63FF),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = filteredNotifications[index];
                        return _buildNotificationCard(notification, index);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 24,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Notificações',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Obx(() => Text(
                  '${_notificationController.unreadCount.value} não lidas',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                )),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white,
            ),
            color: const Color(0xFF2A2A40),
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _notificationController.markAllAsRead();
                  break;
                case 'clear_all':
                  _showClearAllDialog();
                  break;
                case 'settings':
                  Get.toNamed(AppRoutes.notificationSettings);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Marcar todas como lidas', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpar todas', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Configurações', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          final filter = _filterOptions[index];
          final isSelected = _selectedFilter == filter;
          final label = _filterLabels[filter]!;
          final icon = _filterIcons[filter]!;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF6C63FF).withOpacity(0.8)
                    : Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C63FF)
                      : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 100 * index),
            duration: const Duration(milliseconds: 300),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, int index) {
    final isRead = notification['read'] ?? false;
    final title = notification['title'] ?? 'Notificação';
    final body = notification['body'] ?? '';
    final timestamp = notification['timestamp'] as DateTime;
    final data = notification['data'] as Map<String, dynamic>? ?? {};
    final type = data['type'] ?? 'default';
    final notificationId = notification['id'] ?? '';

    final typeColor = _getTypeColor(type);
    final typeIcon = _getTypeIcon(type);

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _notificationController.removeNotification(notificationId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notificação removida'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Desfazer',
              textColor: Colors.white,
              onPressed: () {
                // Implementar desfazer se necessário
              },
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isRead ? 2 : 6,
        color: isRead
            ? Colors.black.withOpacity(0.2)
            : Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isRead
                ? Colors.white.withOpacity(0.1)
                : typeColor.withOpacity(0.5),
            width: isRead ? 1 : 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!isRead) {
              _notificationController.markAsRead(notificationId);
            }
            _handleNotificationTap(data);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone do tipo de notificação
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    typeIcon,
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Conteúdo da notificação
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: Colors.white.withOpacity(0.5),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getTypeLabel(type),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(
      delay: Duration(milliseconds: 50 * index),
      duration: const Duration(milliseconds: 300),
    ).slideX(
      begin: 0.1,
      end: 0,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildEmptyState() {
    final String message;
    final IconData icon;

    switch (_selectedFilter) {
      case 'unread':
        message = 'Nenhuma notificação não lida';
        icon = Icons.mark_email_read;
        break;
      case 'horoscope':
        message = 'Nenhuma notificação de horóscopo';
        icon = Icons.auto_awesome;
        break;
      case 'appointment':
        message = 'Nenhuma notificação de consulta';
        icon = Icons.event;
        break;
      case 'promotion':
        message = 'Nenhuma promoção recebida';
        icon = Icons.local_offer;
        break;
      default:
        message = 'Nenhuma notificação encontrada';
        icon = Icons.notifications_none;
        break;
    }

    return Center(
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
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'As notificações aparecerão aqui quando você recebê-las',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.notificationSettings),
            icon: const Icon(Icons.settings),
            label: const Text('Configurar Notificações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).scale(delay: 300.ms);
  }

  Widget _buildFloatingActionButton() {
    return Obx(() {
      final unreadCount = _notificationController.unreadCount.value;

      if (unreadCount == 0) {
        return const SizedBox.shrink();
      }

      return FloatingActionButton.extended(
        onPressed: () {
          _notificationController.markAllAsRead();
        },
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.done_all),
        label: Text('Marcar $unreadCount como lidas'),
      );
    });
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'horoscope':
        return Colors.orange;
      case 'appointment':
        return Colors.green;
      case 'promotion':
        return Colors.pink;
      case 'tarot':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'horoscope':
        return Icons.auto_awesome;
      case 'appointment':
        return Icons.event;
      case 'promotion':
        return Icons.local_offer;
      case 'tarot':
        return Icons.style;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'horoscope':
        return 'Horóscopo';
      case 'appointment':
        return 'Consulta';
      case 'promotion':
        return 'Promoção';
      case 'tarot':
        return 'Tarô';
      default:
        return 'Geral';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final targetId = data['target_id'] ?? '';

    switch (type) {
      case 'horoscope':
        Get.toNamed(AppRoutes.horoscope);
        break;
      // case 'appointment':
      //   if (targetId.isNotEmpty) {
      //     Get.toNamed('${AppRoutes.mediumDetail}/$targetId');
      //   } else {
      //     Get.toNamed(AppRoutes.mediums);
      //   }
      //   break;
      case 'tarot':
        Get.toNamed(AppRoutes.tarotReading);
        break;
      case 'promotion':
        Get.toNamed(AppRoutes.paymentMethods);
        break;
      case 'welcome':
        Get.toNamed(AppRoutes.navigation);
        break;
      case 'birthday':
        Get.toNamed(AppRoutes.horoscope);
        break;
      default:
      // Não navegar para lugar nenhum específico
        break;
    }
  }

  void _showClearAllDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF2A2A40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever,
                color: Colors.red,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Limpar Todas',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'Tem certeza que deseja remover todas as notificações? Esta ação não pode ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _notificationController.clearAllNotifications();
              Get.back();
              Get.snackbar(
                'Sucesso',
                'Todas as notificações foram removidas',
                backgroundColor: Colors.green,
                colorText: Colors.white,
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Limpar Todas'),
          ),
        ],
      ),
    );
  }
}