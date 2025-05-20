import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:oraculum/config/routes.dart';
import 'package:oraculum/controllers/medium_controller.dart';
import 'package:oraculum/models/medium_model.dart';

class MediumsListScreen extends StatefulWidget {
  const MediumsListScreen({Key? key}) : super(key: key);

  @override
  State<MediumsListScreen> createState() => _MediumsListScreenState();
}

class _MediumsListScreenState extends State<MediumsListScreen> {
  final MediumController _controller = Get.find<MediumController>();
  final TextEditingController _searchController = TextEditingController();
  RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    _controller.loadMediums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médiuns'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSpecialtiesFilter(),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_controller.filteredMediums.isEmpty) {
                return const Center(
                  child: Text('Nenhum médium encontrado'),
                );
              }

              return _buildMediumsList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar médium pelo nome',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Obx(() => searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              searchQuery.value = '';
              _applyFilters();
            },
          )
              : const SizedBox()),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        ),
        onChanged: (value) {
          searchQuery.value = value;
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildSpecialtiesFilter() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _controller.specialties.length + 1, // +1 para a opção "Todos"
        itemBuilder: (context, index) {
          // A primeira opção é "Todos"
          if (index == 0) {
            return Obx(() => _buildFilterChip(
              label: 'Todos',
              isSelected: _controller.selectedSpecialty.isEmpty,
              onTap: () {
                _controller.filterBySpecialty('');
              },
            ));
          }

          final specialty = _controller.specialties[index - 1];
          return Obx(() => _buildFilterChip(
            label: specialty,
            isSelected: _controller.selectedSpecialty.value == specialty,
            onTap: () {
              _controller.filterBySpecialty(specialty);
            },
          ));
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMediumsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _controller.filteredMediums.length,
      itemBuilder: (context, index) {
        final medium = _controller.filteredMediums[index];
        return _buildMediumCard(medium, index);
      },
    );
  }

  Widget _buildMediumCard(MediumModel medium, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          _controller.selectMedium(medium.id);
          Get.toNamed(AppRoutes.mediumProfile);
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(medium.imageUrl),
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                onBackgroundImageError: (_, __) {},
                child: medium.imageUrl.isEmpty
                    ? Icon(
                  Icons.person,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            medium.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (medium.isAvailable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Disponível',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          medium.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${medium.reviewsCount})',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      medium.description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: medium.specialties.map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            specialty,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'R\$ ${medium.pricePerMinute.toStringAsFixed(2)}/min',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _controller.selectMedium(medium.id);
                            Get.toNamed(AppRoutes.booking);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          child: const Text('Agendar'),
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
    ).animate().fadeIn(
      delay: Duration(milliseconds: 100 * index),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _applyFilters() {
    final query = searchQuery.value.toLowerCase();
    final specialty = _controller.selectedSpecialty.value;

    if (query.isEmpty && specialty.isEmpty) {
      // Sem filtros aplicados
      _controller.filteredMediums.value = List.from(_controller.allMediums);
      return;
    }

    // Filtrar por nome e especialidade
    _controller.filteredMediums.value = _controller.allMediums.where((medium) {
      final matchesName = query.isEmpty || medium.name.toLowerCase().contains(query);
      final matchesSpecialty = specialty.isEmpty || medium.specialties.contains(specialty);
      return matchesName && matchesSpecialty;
    }).toList();
  }
}