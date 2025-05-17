import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    const apiKey = 'AIzaSyD2aGQjaAvnlm75UwuEsT6QR0R9jZ1bKW0';
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  // Método para obter a previsão do horóscopo diário
  Future<String> getDailyHoroscope(String sign) async {
    try {
      final prompt = '''
        Por favor, forneça uma previsão de horóscopo diária para o signo de $sign.
        A previsão deve incluir:
        - Uma visão geral do dia
        - Perspectivas para amor e relacionamentos
        - Perspectivas para carreira e finanças
        - Conselhos gerais para o dia
        - Um número da sorte
        
        A resposta deve ser detalhada, inspiradora e positiva, oferecendo orientação útil.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Não foi possível gerar o horóscopo neste momento.';
    } catch (e) {
      return 'Não foi possível gerar o horóscopo neste momento. Erro: $e';
    }
  }

  // Método para obter a interpretação de uma carta de tarot
  Future<String> getTarotInterpretation(List<String> cards) async {
    try {
      final cardsStr = cards.join(', ');
      final prompt = '''
        Por favor, forneça uma interpretação detalhada para a seguinte leitura de tarot: $cardsStr.
        A interpretação deve incluir:
        - O significado individual de cada carta
        - Como as cartas interagem entre si
        - A mensagem geral da leitura
        - Conselhos para a pessoa com base nesta leitura
        
        A resposta deve ser detalhada, perspicaz e oferecer orientação útil.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Não foi possível interpretar as cartas neste momento.';
    } catch (e) {
      return 'Não foi possível interpretar as cartas neste momento. Erro: $e';
    }
  }

  // Método para obter uma análise de compatibilidade entre signos
  Future<String> getCompatibilityAnalysis(String sign1, String sign2) async {
    try {
      final prompt = '''
        Por favor, forneça uma análise de compatibilidade detalhada entre $sign1 e $sign2.
        A análise deve incluir:
        - Compatibilidade geral
        - Compatibilidade emocional
        - Compatibilidade de comunicação
        - Compatibilidade sexual
        - Pontos fortes da relação
        - Desafios potenciais
        - Conselhos para melhorar a relação
        
        A resposta deve ser detalhada, equilibrada e oferecer insights úteis.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Não foi possível gerar a análise de compatibilidade neste momento.';
    } catch (e) {
      return 'Não foi possível gerar a análise de compatibilidade neste momento. Erro: $e';
    }
  }

  // Método para obter uma interpretação do mapa astral
  Future<String> getBirthChartInterpretation(
      DateTime birthDate,
      String birthTime,
      String birthPlace,
      ) async {
    try {
      final dateStr = '${birthDate.day}/${birthDate.month}/${birthDate.year}';
      final prompt = '''
        Por favor, forneça uma interpretação para o mapa astral de uma pessoa nascida em:
        - Data: $dateStr
        - Hora: $birthTime
        - Local: $birthPlace
        
        A interpretação deve incluir:
        - Signo solar, lunar e ascendente
        - Posições dos planetas nas casas
        - Aspectos planetários importantes
        - Personalidade geral
        - Pontos fortes e desafios
        - Potenciais caminhos de vida
        - Conselhos para desenvolvimento pessoal
        
        A resposta deve ser detalhada, perspicaz e oferecer orientação útil.
      ''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? 'Não foi possível interpretar o mapa astral neste momento.';
    } catch (e) {
      return 'Não foi possível interpretar o mapa astral neste momento. Erro: $e';
    }
  }
}