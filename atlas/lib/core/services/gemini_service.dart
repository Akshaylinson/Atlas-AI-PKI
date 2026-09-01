import 'dart:convert';
import 'package:http/http.dart' as http;

/// Google Gemini API (AI Studio).
class GeminiService {
  final String apiKey;
  static const _model = 'gemini-2.5-flash';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  GeminiService(this.apiKey);

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> chat(String prompt) async {
    if (!isConfigured) throw StateError('Gemini API key is not configured');

    final response = await http
        .post(
          Uri.parse('$_endpoint?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {'maxOutputTokens': 512},
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Gemini request failed (${response.statusCode}): ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    final content = candidates?.isNotEmpty == true
        ? (candidates!.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?
        : null;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.isNotEmpty == true
        ? (parts!.first as Map<String, dynamic>)['text']?.toString().trim()
        : null;

    if (text == null || text.isEmpty) throw Exception('Gemini returned empty response');
    return text;
  }
}
