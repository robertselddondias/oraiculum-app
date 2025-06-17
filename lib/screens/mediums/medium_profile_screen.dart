import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/models/medium_model.dart';

class MediumProfileScreen extends StatelessWidget {
  const MediumProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MediumController controller = Get.find<MediumController>();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF533483),
            ],
          ),
        ),
        child: Obx(() {
          if (controller.selectedMedium.value == null) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            );
          }

          final medium = controller.selectedMedium.value!;

          return CustomScrollView(
            slivers: [
              _buildAppBar(context, medium, isSmallScreen),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      _buildAboutSection(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      _buildSpecialtiesSection(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      _buildInfoSection(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 20 : 28),
                      _buildAvailability(context, medium, isSmallScreen),
                      SizedBox(height: isSmallScreen ? 28 : 36),
                      _buildBookingButton(context, medium, isSmallScreen),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final expandedHeight = isSmallScreen ? 180.0 : 200.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              medium.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white54,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: Text(
          medium.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Adicionado aos favoritos"))
            );
          },
          tooltip: 'Adicionar aos favoritos',
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Compartilhando perfil..."))
            );
          },
          tooltip: 'Compartilhar',
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final titleSize = isSmallScreen ? 20.0 : 22.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
                      medium.name,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9D8A).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: const Color(0xFFFF9D8A),
                                size: iconSize,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                medium.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF9D8A),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${medium.reviewsCount} avaliações)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}/min',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildStatCard(
                    'Online',
                    medium.isAvailable ? 'Agora' : 'Offline',
                    medium.isAvailable ? Icons.circle : Icons.circle_outlined,
                    medium.isAvailable ? const Color(0xFF4CAF50) : Colors.grey,
                    isSmallScreen: isSmallScreen,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    'Consultas',
                    '${medium.reviewsCount}',
                    Icons.psychology,
                    const Color(0xFF8E78FF),
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStatCard(
      String title,
      String subtitle,
      IconData icon,
      Color iconColor, {
        required bool isSmallScreen,
      }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: isSmallScreen ? 20 : 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 16 : 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmallScreen ? 11 : 12,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 18.0 : 20.0;
    final contentTextSize = isSmallScreen ? 14.0 : 15.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Sobre',
                style: TextStyle(
                  fontSize: sectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            medium.biography,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              height: 1.6,
              fontSize: contentTextSize,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildSpecialtiesSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 18.0 : 20.0;
    final chipTextSize = isSmallScreen ? 12.0 : 13.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9D8A), Color(0xFF8E78FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Especialidades',
                style: TextStyle(
                  fontSize: sectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: medium.specialties.asMap().entries.map((entry) {
              final index = entry.key;
              final specialty = entry.value;
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 12 : 14,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.3),
                      const Color(0xFF8E78FF).withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  specialty,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: chipTextSize,
                  ),
                ),
              ).animate().fadeIn(
                delay: Duration(milliseconds: 100 * index),
                duration: const Duration(milliseconds: 300),
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildInfoSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 18.0 : 20.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8E78FF), Color(0xFF6C63FF)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Informações',
                style: TextStyle(
                  fontSize: sectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            context,
            'Idiomas',
            medium.languages.join(', '),
            Icons.language,
            isSmallScreen: isSmallScreen,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            context,
            'Experiência',
            '${medium.yearsOfExperience} anos',
            Icons.history,
            isSmallScreen: isSmallScreen,
          ),
          if (medium.isAvailable) ...[
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Status',
              'Disponível para agendamento',
              Icons.check_circle,
              valueColor: const Color(0xFF4CAF50),
              isSmallScreen: isSmallScreen,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: 600.ms, duration: 600.ms).slideX(begin: -0.2, end: 0);
  }

  Widget _buildInfoRow(
      BuildContext context,
      String label,
      String value,
      IconData icon, {
        Color? valueColor,
        required bool isSmallScreen,
      }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6C63FF),
              size: isSmallScreen ? 16 : 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: isSmallScreen ? 11 : 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 18.0 : 20.0;
    final dayTextSize = isSmallScreen ? 13.0 : 14.0;
    final hoursTextSize = isSmallScreen ? 12.0 : 13.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFFFF9D8A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Disponibilidade',
                style: TextStyle(
                  fontSize: sectionTitleSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...medium.availability.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: dayTextSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    entry.value,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: hoursTextSize,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms, duration: 600.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildBookingButton(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final buttonTextSize = isSmallScreen ? 14.0 : 16.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: medium.isAvailable
            ? const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8E78FF)],
        )
            : LinearGradient(
          colors: [Colors.grey.withOpacity(0.5), Colors.grey.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: medium.isAvailable
            ? [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ]
            : [],
      ),
      child: ElevatedButton.icon(
        onPressed: medium.isAvailable
            ? () => Get.toNamed(AppRoutes.booking)
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: Icon(
          medium.isAvailable ? Icons.calendar_today : Icons.block,
          color: Colors.white,
          size: 20,
        ),
        label: Text(
          medium.isAvailable ? 'Agendar Consulta' : 'Indisponível para Agendamento',
          style: TextStyle(
            fontSize: buttonTextSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0));
  }
}