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
    Key? key,
    required this.interpretation,
    required this.isSmallScreen,
    required this.isTablet,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cardPadding = isTablet ? 24.0 : isSmallScreen ? 12.0 : 16.0;
    final titleSize = isTablet ? 22.0 : isSmallScreen ? 18.0 : 20.0;
    final textSize = isTablet ? 16.0 : isSmallScreen ? 14.0 : 15.0;
    final iconSize = isTablet ? 24.0 : isSmallScreen ? 18.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.psychology,
              color: Theme.of(context).colorScheme.primary,
              size: iconSize,
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

        Card(
          elevation: isTablet ? 4 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            side: BorderSide(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          color: Colors.black.withOpacity(0.3),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...interpretationSections.map((section) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: isTablet ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.title.isNotEmpty) ...[
                          Text(
                            section.title,
                            style: TextStyle(
                              fontSize: isTablet ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: isTablet ? 10 : 6),
                        ],
                        Text(
                          section.content,
                          style: TextStyle(
                            fontSize: textSize,
                            height: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(
      delay: const Duration(milliseconds: 400),
      duration: const Duration(milliseconds: 500),
    );
  }

  List<InterpretationSection> get interpretationSections {
    if (interpretation.isEmpty) {
      return [InterpretationSection(title: '', content: 'Interpretação não disponível')];
    }

    try {
      final List<InterpretationSection> sections = [];

      final paragraphs = interpretation.split('\n\n');

      if (paragraphs.length <= 3) {
        return [InterpretationSection(title: '', content: interpretation)];
      }

      final regex = RegExp(r'([A-Z][A-Z\s]+:)|(SOL EM)|(LUA EM)|(ASCENDENTE EM)');
      String currentTitle = '';
      String currentContent = '';

      for (var paragraph in paragraphs) {
        final match = regex.firstMatch(paragraph);

        if (match != null) {
          if (currentContent.isNotEmpty) {
            sections.add(InterpretationSection(
                title: currentTitle,
                content: currentContent.trim()
            ));
            currentContent = '';
          }

          final splitIndex = paragraph.indexOf(':');
          if (splitIndex > 0) {
            currentTitle = paragraph.substring(0, splitIndex + 1).trim();
            currentContent = paragraph.substring(splitIndex + 1).trim();
          } else {
            currentTitle = match.group(0)!.trim();
            currentContent = paragraph.replaceFirst(currentTitle, '').trim();
          }
        } else {
          if (currentContent.isNotEmpty) {
            currentContent += '\n\n';
          }
          currentContent += paragraph;
        }
      }

      if (currentContent.isNotEmpty) {
        sections.add(InterpretationSection(
            title: currentTitle,
            content: currentContent.trim()
        ));
      }

      return sections.isEmpty ?
      [InterpretationSection(title: '', content: interpretation)] : sections;
    } catch (e) {
      return [InterpretationSection(title: '', content: interpretation)];
    }
  }
}