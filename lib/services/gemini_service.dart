import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;

  GeminiService({required this.apiKey});

  // URL base para a API do Gemini
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/';
  final String defaultModel = 'gemini-2.0-flash'; // Usando a versão correta do modelo

  // Método para obter a previsão do horóscopo diário em formato JSON
  Future<String> generateJsonHoroscope(String prompt) async {
    try {
      final response = await _generateContent(prompt, temperature: 0.7, maxOutputTokens: 1024);

      // Limpar a resposta para garantir que seja um JSON válido
      String cleanedResponse = response.trim();

      // Verificar se o texto começa com ``` e termina com ``` (caso o Gemini encapsule em código)
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }

      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }

      // Verificar se é um JSON válido
      try {
        json.decode(cleanedResponse);
        return cleanedResponse;
      } catch (e) {
        throw Exception('Resposta não é um JSON válido: $e');
      }
    } catch (e) {
      debugPrint('Erro ao gerar horóscopo JSON: $e');
      throw Exception('Falha ao gerar horóscopo: $e');
    }
  }

  // Método para obter a análise de compatibilidade em formato JSON
  Future<String> generateJsonCompatibility(String prompt) async {
    try {
      final response = await _generateContent(prompt, temperature: 0.7, maxOutputTokens: 1024);

      // Limpar a resposta para garantir que seja um JSON válido
      String cleanedResponse = response.trim();

      // Verificar se o texto começa com ``` e termina com ``` (caso o Gemini encapsule em código)
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }

      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }

      // Verificar se é um JSON válido
      try {
        json.decode(cleanedResponse);
        return cleanedResponse;
      } catch (e) {
        throw Exception('Resposta não é um JSON válido: $e');
      }
    } catch (e) {
      debugPrint('Erro ao gerar análise de compatibilidade JSON: $e');
      throw Exception('Falha ao gerar análise de compatibilidade: $e');
    }
  }

  // Método para obter a previsão do horóscopo diário
  Future<String> getDailyHoroscope(String sign) async {
    try {
      final prompt = '''
        Por favor, forneça uma previsão de horóscopo diária para o signo de $sign. 
        Coloque uma formatação  moderna separada, bem elegante e estruturada. Sem asterisco e coloque quebra de linhas e emoctions
        A previsão deve incluir:
        - Uma visão geral do dia
        - Perspectivas para amor e relacionamentos
        - Perspectivas para carreira e finanças
        - Conselhos gerais para o dia
        - Um número da sorte
        
        . A resposta deve ser detalhada, inspiradora e positiva, oferecendo orientação útil. E resumida.
      ''';

      final response = await _generateContent(prompt);
      return response;
    } catch (e) {
      debugPrint('Erro ao gerar horóscopo: $e');
      return 'Não foi possível gerar o horóscopo neste momento. Erro: $e';
    }
  }

  // Método para obter a interpretação de uma carta de tarot
  Future<String> getTarotInterpretation(List<String> cards) async {
    try {
      final cardsStr = cards.join(', ');
      final prompt = '''
        Por favor, forneça uma interpretação detalhada para a seguinte leitura de tarot: $cardsStr.
        Coloque uma formatação  moderna separada, bem elegante e estruturada. Sem asterisco e coloque quebra de linhas e emoctions
        A interpretação deve incluir:
        - O significado individual de cada carta
        - Como as cartas interagem entre si
        - A mensagem geral da leitura
        - Conselhos para a pessoa com base nesta leitura
        
        A resposta deve ser detalhada, perspicaz e oferecer orientação útil.
      ''';

      final response = await _generateContent(prompt);
      return response;
    } catch (e) {
      debugPrint('Erro ao interpretar cartas: $e');
      return 'Não foi possível interpretar as cartas neste momento. Erro: $e';
    }
  }

  // Método para obter uma análise de compatibilidade entre signos
  Future<String> getCompatibilityAnalysis(String sign1, String sign2) async {
    try {
      final prompt = '''
        Por favor, forneça uma análise de compatibilidade detalhada entre $sign1 e $sign2.
       Coloque uma formatação  moderna separada, bem elegante e estruturada. Sem asterisco e coloque quebra de linhas e emoctions
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

      final response = await _generateContent(prompt);
      return response;
    } catch (e) {
      debugPrint('Erro ao analisar compatibilidade: $e');
      return 'Não foi possível gerar a análise de compatibilidade neste momento. Erro: $e';
    }
  }

  // Método para obter uma interpretação do mapa astral
  Future<String> getBirthChartInterpretation(
      String birthDate,
      String birthTime,
      String birthPlace,
      {bool jsonFormat = false}
      ) async {
    try {
      String prompt;
      if (jsonFormat) {
        // Prompt estruturado em JSON
        prompt = '''
        Gere uma interpretação completa de mapa astral para alguém nascido em 
        $birthDate às $birthTime em $birthPlace.
        
        Retorne a interpretação como um objeto JSON com a seguinte estrutura:
        
        {
          "visao_geral": {
            "title": "Visão Geral", 
            "body": "Texto descrevendo o mapa como um todo..."
          },
          "sol": {
            "title": "Sol em [Signo]", 
            "body": "Texto sobre a posição do Sol..."
          },
          "lua": {
            "title": "Lua em [Signo]", 
            "body": "Texto sobre a posição da Lua..."
          },
          "ascendente": {
            "title": "Ascendente em [Signo]", 
            "body": "Texto sobre o Ascendente..."
          },
          "planetas": {
            "title": "Posições Planetárias", 
            "body": "Texto sobre os outros planetas importantes..."
          },
          "casas": {
            "title": "Casas Astrológicas", 
            "body": "Texto sobre as casas astrológicas..."
          },
          "aspectos": {
            "title": "Aspectos Importantes", 
            "body": "Texto sobre aspectos importantes entre planetas..."
          },
          "conclusao": {
            "title": "Conclusão", 
            "body": "Texto resumo com conselhos..."
          }
        }
        
        A resposta deve ser apenas o JSON válido, sem explicações adicionais ou formatação.
        Faça a interpretação detalhada, positiva e perspicaz.
      ''';
      } else {
        // Prompt de texto regular
        prompt = '''
        Gere uma interpretação detalhada de mapa astral para alguém nascido em 
        $birthDate às $birthTime em $birthPlace.
        
        Coloque uma formatação moderna separada, bem elegante e estruturada. Sem asterisco e coloque quebra de linhas e emoticons.
        
        Inclua informações sobre:
        - Análise geral do mapa
        - Signo solar e seu significado
        - Signo lunar e seu impacto emocional
        - Ascendente e sua influência na personalidade
        - Outras posições planetárias importantes
        - Aspectos-chave entre planetas
        - Áreas da vida afetadas (casas)
        - Conselhos baseados no mapa
        
        Faça a interpretação detalhada, positiva e perspicaz.
      ''';
      }

      final response = await _generateContent(prompt, temperature: 0.7);

      // Se solicitado em formato JSON, limpe a resposta
      if (jsonFormat) {
        // Limpar a resposta para garantir que seja um JSON válido
        String cleanedResponse = response.trim();

        // Verificar se o texto começa com ``` e termina com ``` (caso o Gemini encapsule em código)
        if (cleanedResponse.startsWith('```json')) {
          cleanedResponse = cleanedResponse.substring(7);
        } else if (cleanedResponse.startsWith('```')) {
          cleanedResponse = cleanedResponse.substring(3);
        }

        if (cleanedResponse.endsWith('```')) {
          cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
        }

        // Verificar se é um JSON válido
        try {
          json.decode(cleanedResponse);
          return cleanedResponse;
        } catch (e) {
          debugPrint('Resposta não é um JSON válido: $e');
          // Se não for JSON válido, retorne como texto comum
          return response;
        }
      }

      return response;
    } catch (e) {
      debugPrint('Erro ao gerar interpretação do mapa astral: $e');
      throw Exception('Falha ao gerar interpretação do mapa astral: $e');
    }
  }

  // Método principal para fazer requisições à API do Gemini
  Future<String> _generateContent(String prompt, {double? temperature, int? maxOutputTokens}) async {
    final url = '$baseUrl$defaultModel:generateContent?key=$apiKey';

    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "parts": [
            {
              "text": prompt
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": temperature ?? 0.7,
        "topK": 40,
        "topP": 0.95,
        "maxOutputTokens": maxOutputTokens ?? 5000,
      }
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final generatedText = jsonResponse['candidates'][0]['content']['parts'][0]['text'];
        return generatedText;
      } else {
        throw Exception('Falha ao gerar conteúdo: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Erro na requisição: $e');
      rethrow;
    }
  }

  // Método para obter a interpretação do tarô em formato JSON
  Future<String> generateJsonInterpretation(String prompt) async {
    try {
      final response = await _generateContent(prompt, temperature: 0.7, maxOutputTokens: 1024);

      // Limpar a resposta para garantir que seja um JSON válido
      String cleanedResponse = response.trim();

      // Verificar se o texto começa com ``` e termina com ``` (caso o Gemini encapsule em código)
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      } else if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }

      if (cleanedResponse.endsWith('```')) {
        cleanedResponse = cleanedResponse.substring(0, cleanedResponse.length - 3);
      }

      // Verificar se é um JSON válido
      try {
        json.decode(cleanedResponse);
        return cleanedResponse;
      } catch (e) {
        throw Exception('Resposta não é um JSON válido: $e');
      }
    } catch (e) {
      debugPrint('Erro ao gerar interpretação JSON: $e');
      throw Exception('Falha ao gerar interpretação: $e');
    }
  }
}