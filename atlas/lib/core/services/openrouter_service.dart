import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey;

  OpenRouterService(this.apiKey);

  bool get isConfigured => apiKey.trim().isNotEmpty;

  Future<String> chat(String prompt) async {
    if (!isConfigured) {
      throw StateError('OpenRouter API key is not configured');
    }

    final response = await http
        .post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'atlas-app',
          },
          body: jsonEncode({
            'model': 'google/gemma-3-4b-it',
            'messages': [
              {'role': 'user', 'content': prompt},
            ],
            'max_tokens': 512,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'OpenRouter request failed (${response.statusCode}): ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final firstChoice = choices?.isNotEmpty == true ? choices!.first : null;
    final message = firstChoice is Map<String, dynamic>
        ? firstChoice['message'] as Map<String, dynamic>?
        : null;
    final rawContent = message?['content']?.toString();
    final content = rawContent?.trim();

    if (content == null || content.isEmpty) {
      throw Exception('OpenRouter returned an empty response');
    }

    return content;
  }
}
