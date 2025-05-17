import 'package:oraculum/config/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/models/medium_model.dart';

class MediumProfileScreen extends StatelessWidget {
  const MediumProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediumController controller = Get.find<MediumController>();

    return Scaffold(
      body: Obx(() {
        if (controller.selectedMedium.value == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final medium = controller.selectedMedium.value!;

        return CustomScrollView(
          slivers: [
            _buildAppBar(context, medium),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(context, medium),
                    const SizedBox(height: 24),
                    _buildAboutSection(context, medium),
                    const SizedBox(height: 24),
                    _buildSpecialtiesSection(context, medium),
                    const SizedBox(height: 24),
                    _buildInfoSection(context, medium),
                    const SizedBox(height: 32),
                    _buildAvailability(context, medium),
                    const SizedBox(height: 32),
                    _buildBookingButton(context, medium),
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

  Widget _buildAppBar(BuildContext context, MediumModel medium) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
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
          },
          tooltip: 'Adicionar aos favoritos',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Implementar compartilhamento
          },
          tooltip: 'Compartilhar',
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, MediumModel medium) {
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        medium.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${medium.reviewsCount} avaliações)',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: medium.isAvailable ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                medium.isAvailable ? 'Disponível' : 'Indisponível',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text('por minuto',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${medium.yearsOfExperience}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text('anos de experiência',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context, MediumModel medium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sobre',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          medium.biography,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtiesSection(BuildContext context, MediumModel medium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Especialidades',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: medium.specialties.map((specialty) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
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
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, MediumModel medium) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  context,
                  'Idiomas',
                  medium.languages.join(', '),
                  Icons.language,
                ),
                const Divider(),
                _buildInfoRow(
                  context,
                  'Experiência',
                  '${medium.yearsOfExperience} anos',
                  Icons.history,
                ),
                if (medium.isAvailable) ...[
                  const Divider(),
                  _buildInfoRow(
                    context,
                    'Status',
                    'Disponível para agendamento',
                    Icons.check_circle,
                    valueColor: Colors.green,
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
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailability(BuildContext context, MediumModel medium) {
    // Esta é uma simplificação. Idealmente, você teria uma lógica mais complexa
    // para mostrar a disponibilidade com base nos dados do Firebase.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Disponibilidade',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAvailabilityRow(context, 'Segunda', '09:00 - 18:00'),
                const Divider(),
                _buildAvailabilityRow(context, 'Terça', '09:00 - 18:00'),
                const Divider(),
                _buildAvailabilityRow(context, 'Quarta', '09:00 - 18:00'),
                const Divider(),
                _buildAvailabilityRow(context, 'Quinta', '09:00 - 18:00'),
                const Divider(),
                _buildAvailabilityRow(context, 'Sexta', '09:00 - 18:00'),
                const Divider(),
                _buildAvailabilityRow(context, 'Sábado', '10:00 - 14:00'),
                const Divider(),
                _buildAvailabilityRow(context, 'Domingo', 'Indisponível', isAvailable: false),
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
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              color: isAvailable
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(BuildContext context, MediumModel medium) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: medium.isAvailable
            ? () => Get.toNamed(AppRoutes.booking)
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          medium.isAvailable ? 'Agendar Consulta' : 'Indisponível para Agendamento',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}