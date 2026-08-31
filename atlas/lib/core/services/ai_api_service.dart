import 'openrouter_service.dart';
import 'gemini_service.dart';

/// Unified AI API service.
/// Tries OpenRouter first. If it fails or is unconfigured, falls back to Gemini.
class AiApiService {
  final String openRouterKey;
  final String geminiKey;

  AiApiService({required this.openRouterKey, required this.geminiKey});

  bool get hasAnyKey => openRouterKey.trim().isNotEmpty || geminiKey.trim().isNotEmpty;

  Future<String> chat(String prompt) async {
    // Try OpenRouter first
    if (openRouterKey.trim().isNotEmpty) {
      try {
        return await OpenRouterService(openRouterKey).chat(prompt);
      } catch (e) {
        // OpenRouter failed — fall through to Gemini
        if (geminiKey.trim().isEmpty) rethrow;
      }
    }

    // Fallback to Gemini
    if (geminiKey.trim().isNotEmpty) {
      return GeminiService(geminiKey).chat(prompt);
    }

    throw StateError(
      'No API key configured. Add an OpenRouter or Gemini API key in Settings.',
    );
  }
}
