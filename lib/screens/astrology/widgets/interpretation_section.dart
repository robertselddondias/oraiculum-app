import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class InterpretationSection {
  final String title;
  final String content;

  InterpretationSection({required this.title, required this.content});
}

class BirthChartInterpretation extends StatelessWidget {
  final String interpretation;
  final bool isSmallScreen;
  final bool isTablet;

  const BirthChartInterpretation({
    super.key,
    required this.interpretation,
    required this.isSmallScreen,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final sectionCardPadding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;
    final titleSize = isTablet ? 20.0 : isSmallScreen ? 16.0 : 18.0;
    final sectionTitleSize = isTablet ? 18.0 : isSmallScreen ? 14.0 : 16.0;
    final bodyTextSize = isTablet ? 16.0 : isSmallScreen ? 13.0 : 14.0;
    final iconSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;

    // Parse the interpretation
    final parsedSections = _parseInterpretation(interpretation);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.public,
                color: Theme.of(context).colorScheme.primary,
                size: iconSize,
              ),
            ),
            SizedBox(width: isTablet ? 12 : 8),
            Text(
              'Interpretação do Mapa Astral',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 16 : 12),

        // Display each section of the birth chart
        ...parsedSections.entries.map((entry) {
          final title = entry.key;
          final content = entry.value;

          // Skip empty sections
          if (content.isEmpty) return const SizedBox.shrink();

          // Determine section color and icon
          final sectionInfo = _getSectionInfo(title);

          return Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 20 : 16),
            child: Card(
              elevation: isTablet ? 4 : 2,
              color: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: sectionInfo.color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(sectionCardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sectionInfo.color.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            sectionInfo.icon,
                            color: sectionInfo.color,
                            size: iconSize,
                          ),
                        ),
                        SizedBox(width: isTablet ? 12 : 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.bold,
                              color: sectionInfo.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    Text(
                      content,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: bodyTextSize,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(
            delay: Duration(milliseconds: 200 + (100 * parsedSections.keys.toList().indexOf(title))),
            duration: const Duration(milliseconds: 500),
          ).slideY(
            begin: 0.1,
            end: 0,
            duration: const Duration(milliseconds: 400),
          );
        }),
      ],
    );
  }

  // Parse the interpretation string into sections
  Map<String, String> _parseInterpretation(String text) {
    Map<String, String> sections = {};

    try {
      // Try to parse as JSON first
      final jsonData = json.decode(text);

      if (jsonData is Map<String, dynamic>) {
        // Process JSON structure
        jsonData.forEach((key, value) {
          if (value is Map<String, dynamic> && value.containsKey('body')) {
            // Use title from JSON if available, otherwise capitalize the key
            final title = value['title'] ?? _capitalizeSection(key);
            sections[title] = value['body'] ?? '';
          } else if (value is String) {
            // Simple key-value pair
            sections[_capitalizeSection(key)] = value;
          }
        });

        return sections;
      }
    } catch (e) {
      // Not valid JSON, fallback to text processing
    }

    // Fallback: Try to identify sections by headings
    try {
      // Common section patterns in birth chart interpretations
      final sectionRegex = RegExp(
          r'(SOL EM .+?:)|(LUA EM .+?:)|(ASCENDENTE EM .+?:)|'
          r'(MERCÚRIO EM .+?:)|(VÊNUS EM .+?:)|(MARTE EM .+?:)|'
          r'(JÚPITER EM .+?:)|(SATURNO EM .+?:)|(CASAS ASTROLÓGICAS:)|'
          r'(ASPECTOS PLANETÁRIOS:)|(CONCLUSÃO:)',
          caseSensitive: false
      );

      // Split by detected section headers
      final matches = sectionRegex.allMatches(text);

      if (matches.isNotEmpty) {
        int startIndex = 0;
        String currentTitle = 'Visão Geral';

        // Extract leading text before first section as "General Overview"
        if (matches.first.start > 0) {
          sections[currentTitle] = text.substring(0, matches.first.start).trim();
        }

        // Process each section
        for (final match in matches) {
          // Save previous section
          if (match.start > startIndex && currentTitle.isNotEmpty) {
            final sectionText = text.substring(startIndex, match.start).trim();
            if (sectionText.isNotEmpty) {
              sections[currentTitle] = sectionText;
            }
          }

          // Update for next section
          currentTitle = text.substring(match.start, match.end).replaceAll(':', '').trim();
          startIndex = match.end;
        }

        // Add the last section
        if (startIndex < text.length && currentTitle.isNotEmpty) {
          final sectionText = text.substring(startIndex).trim();
          if (sectionText.isNotEmpty) {
            sections[currentTitle] = sectionText;
          }
        }

        return sections;
      }
    } catch (e) {
      // Fallback to simple overview if section parsing fails
    }

    // If all parsing fails, just use the whole text as a general section
    sections['Interpretação Completa'] = text;
    return sections;
  }

  // Helper function to capitalize section names
  String _capitalizeSection(String text) {
    if (text.isEmpty) return 'Visão Geral';

    // Special case handling for common astrological terms
    switch (text.toLowerCase()) {
      case 'sol':
      case 'solar':
        return 'Sol (Personalidade)';
      case 'lua':
      case 'lunar':
        return 'Lua (Emoções)';
      case 'asc':
      case 'ascendente':
        return 'Ascendente';
      case 'mc':
      case 'meio_do_ceu':
        return 'Meio do Céu';
      case 'venus':
      case 'vênus':
        return 'Vênus (Amor)';
      case 'marte':
        return 'Marte (Energia)';
      case 'mercurio':
      case 'mercúrio':
        return 'Mercúrio (Comunicação)';
      case 'jupiter':
      case 'júpiter':
        return 'Júpiter (Expansão)';
      case 'saturno':
        return 'Saturno (Limitações)';
      case 'urano':
        return 'Urano (Originalidade)';
      case 'netuno':
        return 'Netuno (Espiritualidade)';
      case 'plutao':
      case 'plutão':
        return 'Plutão (Transformação)';
      case 'casas':
        return 'Casas Astrológicas';
      case 'aspectos':
        return 'Aspectos Planetários';
      case 'geral':
      case 'visao_geral':
      case 'visão_geral':
        return 'Visão Geral';
      case 'conclusao':
      case 'conclusão':
        return 'Conclusão';
      default:
      // Capitalize each word
        return text.split('_').map((word) =>
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
        ).join(' ');
    }
  }

  // Section styling information
  _SectionInfo _getSectionInfo(String sectionTitle) {
    final title = sectionTitle.toLowerCase();

    if (title.contains('sol') || title.contains('personalidade')) {
      return _SectionInfo(
        color: Colors.orange,
        icon: Icons.wb_sunny_outlined,
      );
    } else if (title.contains('lua') || title.contains('emoções')) {
      return _SectionInfo(
        color: Colors.blueGrey,
        icon: Icons.nightlight_round,
      );
    } else if (title.contains('mercúrio') || title.contains('comunicação')) {
      return _SectionInfo(
        color: Colors.lightBlue,
        icon: Icons.message_outlined,
      );
    } else if (title.contains('vênus') || title.contains('amor')) {
      return _SectionInfo(
        color: Colors.pink,
        icon: Icons.favorite_outline,
      );
    } else if (title.contains('marte') || title.contains('energia')) {
      return _SectionInfo(
        color: Colors.red,
        icon: Icons.flash_on_outlined,
      );
    } else if (title.contains('ascendente')) {
      return _SectionInfo(
        color: Colors.amber,
        icon: Icons.arrow_upward,
      );
    } else if (title.contains('casas')) {
      return _SectionInfo(
        color: Colors.teal,
        icon: Icons.home_outlined,
      );
    } else if (title.contains('aspectos')) {
      return _SectionInfo(
        color: Colors.deepPurple,
        icon: Icons.connecting_airports_outlined,
      );
    } else if (title.contains('conclusão')) {
      return _SectionInfo(
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    } else {
      // Default
      return _SectionInfo(
        color: Colors.deepPurple,
        icon: Icons.public,
      );
    }
  }
}

// Helper class for section styling
class _SectionInfo {
  final Color color;
  final IconData icon;

  _SectionInfo({
    required this.color,
    required this.icon,
  });
}