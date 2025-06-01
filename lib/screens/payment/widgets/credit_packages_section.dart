import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreditPackagesSection extends StatelessWidget {
  final List<Map<String, dynamic>> creditPackages;
  final Map<String, dynamic>? selectedPackage;
  final bool isTablet;
  final bool isSmallScreen;
  final Function(Map<String, dynamic>) onPackageSelected;

  const CreditPackagesSection({
    super.key,
    required this.creditPackages,
    required this.selectedPackage,
    required this.isTablet,
    required this.isSmallScreen,
    required this.onPackageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escolha um Pacote',
          style: TextStyle(
            fontSize: isTablet ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(height: isTablet ? 20 : 16),

        if (isTablet)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: creditPackages.length,
            itemBuilder: (context, index) {
              return _buildPackageCard(creditPackages[index], index, context);
            },
          )
        else
          SizedBox(
            height: isSmallScreen ? 160 : 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: creditPackages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: isSmallScreen ? 120 : 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildPackageCard(creditPackages[index], index, context),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> package, int index, BuildContext context) {
    final isSelected = selectedPackage == package;
    final popular = package['popular'] == true;

    return GestureDetector(
      onTap: () => onPackageSelected(package),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
              colors: [package['color'], package['color'].withOpacity(0.7)]
          )
              : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: package['color'].withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ] : null,
        ),
        child: Stack(
          children: [
            if (popular)
              Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    package['icon'],
                    size: isSmallScreen ? 28 : 32,
                    color: isSelected ? Colors.white : package['color'],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    package['description'],
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),

                  Text(
                    'R\$ ${package['amount'].toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
                    ),
                  ),

                  if (package['bonus'] > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${package['bonus']}% Bônus',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 8 : 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 600.ms)
          .slideX(begin: 0.3, end: 0),
    );
  }
}
