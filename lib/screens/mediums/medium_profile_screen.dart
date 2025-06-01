import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/models/medium_model.dart';

class MediumProfileScreen extends StatelessWidget {
  const MediumProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final MediumController controller = Get.find<MediumController>();

    // Obter dimensões da tela para layout responsivo
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    // Ajustar padding baseado no tamanho da tela
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      body: Obx(() {
        if (controller.selectedMedium.value == null) {
          return const Center(child: CircularProgressIndicator());
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
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildAboutSection(context, medium, isSmallScreen),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildSpecialtiesSection(context, medium, isSmallScreen),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    _buildInfoSection(context, medium, isSmallScreen),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildAvailability(context, medium, isSmallScreen),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    _buildBookingButton(context, medium, isSmallScreen),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAppBar(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final expandedHeight = isSmallScreen ? 180.0 : 200.0;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      elevation: 0,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Imagem de fundo
            Image.network(
              medium.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white54,
                  ),
                );
              },
            ),
            // Overlay gradiente para melhorar a legibilidade
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
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // Implementar adição aos favoritos
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Adicionado aos favoritos"))
            );
          },
          tooltip: 'Adicionar aos favoritos',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Implementar compartilhamento
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
    // Ajustes para telas pequenas
    final titleSize = isSmallScreen ? 20.0 : 22.0;
    final iconSize = isSmallScreen ? 16.0 : 18.0;

    return Column(
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: iconSize,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        medium.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${medium.reviewsCount} avaliações)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: medium.isAvailable ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                medium.isAvailable ? 'Disponível' : 'Indisponível',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Preço e experiência
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                context,
                title: 'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}',
                subtitle: 'por minuto',
                isSmallScreen: isSmallScreen,
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 16),
            Expanded(
              child: _buildInfoCard(
                context,
                title: '${medium.yearsOfExperience}',
                subtitle: 'anos de experiência',
                isSmallScreen: isSmallScreen,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, {required String title, required String subtitle, required bool isSmallScreen}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 16 : 18,
              ),
            ),
            Text(subtitle,
              style: TextStyle(fontSize: isSmallScreen ? 11 : 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 16.0 : 18.0;
    final contentTextSize = isSmallScreen ? 13.0 : 14.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          medium.biography,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.5,
            fontSize: contentTextSize,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtiesSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 16.0 : 18.0;
    final chipTextSize = isSmallScreen ? 11.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Especialidades',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: medium.specialties.map((specialty) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 10 : 12,
                vertical: isSmallScreen ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                specialty,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: chipTextSize,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 16.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  'Idiomas',
                  medium.languages.join(', '),
                  Icons.language,
                  isSmallScreen: isSmallScreen,
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  'Experiência',
                  '${medium.yearsOfExperience} anos',
                  Icons.history,
                  isSmallScreen: isSmallScreen,
                ),
                if (medium.isAvailable) ...[
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Status',
                    'Disponível para agendamento',
                    Icons.check_circle,
                    valueColor: Colors.green,
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context,
      String label,
      String value,
      IconData icon, {
        Color? valueColor,
        required bool isSmallScreen,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: isSmallScreen ? 18 : 20,
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: isSmallScreen ? 11 : 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 13 : 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final sectionTitleSize = isSmallScreen ? 16.0 : 18.0;
    final dayTextSize = isSmallScreen ? 13.0 : 14.0;
    final hoursTextSize = isSmallScreen ? 12.0 : 13.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disponibilidade',
          style: TextStyle(
            fontSize: sectionTitleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              children: [
                _buildAvailabilityRow(context, 'Segunda', '09:00 - 18:00',
                    dayTextSize: dayTextSize, hoursTextSize: hoursTextSize),
                const Divider(),
                _buildAvailabilityRow(context, 'Terça', '09:00 - 18:00',
                    dayTextSize: dayTextSize, hoursTextSize: hoursTextSize),
                const Divider(),
                _buildAvailabilityRow(context, 'Quarta', '09:00 - 18:00',
                    dayTextSize: dayTextSize, hoursTextSize: hoursTextSize),
                const Divider(),
                _buildAvailabilityRow(context, 'Quinta', '09:00 - 18:00',
                    dayTextSize: dayTextSize, hoursTextSize: hoursTextSize),
                const Divider(),
                _buildAvailabilityRow(context, 'Sexta', '09:00 - 18:00',
                    dayTextSize: dayTextSize, hoursTextSize: hoursTextSize),
                const Divider(),
                _buildAvailabilityRow(context, 'Sábado', '10:00 - 14:00',
                    dayTextSize: dayTextSize, hoursTextSize: hoursTextSize),
                const Divider(),
                _buildAvailabilityRow(context, 'Domingo', 'Indisponível',
                    isAvailable: false, dayTextSize: dayTextSize, hoursTextSize: hoursTextSize),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityRow(
      BuildContext context,
      String day,
      String hours, {
        bool isAvailable = true,
        required double dayTextSize,
        required double hoursTextSize,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: dayTextSize,
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              color: isAvailable
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontSize: hoursTextSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(BuildContext context, MediumModel medium, bool isSmallScreen) {
    final buttonTextSize = isSmallScreen ? 14.0 : 16.0;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: medium.isAvailable
            ? () => Get.toNamed(AppRoutes.booking)
            : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 16),
          ),
        ),
        child: Text(
          medium.isAvailable ? 'Agendar Consulta' : 'Indisponível para Agendamento',
          style: TextStyle(
            fontSize: buttonTextSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}