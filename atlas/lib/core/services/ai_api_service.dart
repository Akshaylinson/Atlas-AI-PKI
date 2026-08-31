import 'openrouter_service.dart';
import 'gemini_service.dart';

const String kPrimaryAiProviderName = 'Gemini';
const String kFallbackAiProviderName = 'OpenRouter';

/// Unified AI API service.
/// Tries Gemini first. If it fails or is unconfigured, falls back to OpenRouter.
class AiApiService {
  final String openRouterKey;
  final String geminiKey;

  AiApiService({required this.openRouterKey, required this.geminiKey});

  bool get hasAnyKey =>
      openRouterKey.trim().isNotEmpty || geminiKey.trim().isNotEmpty;

  Future<String> chat(String prompt) async {
    // Try Gemini first.
    if (geminiKey.trim().isNotEmpty) {
      try {
        return await GeminiService(geminiKey).chat(prompt);
      } catch (e) {
        // Gemini failed — fall through to OpenRouter if available.
        if (openRouterKey.trim().isEmpty) rethrow;
      }
    }

    // Fallback to OpenRouter.
    if (openRouterKey.trim().isNotEmpty) {
      return OpenRouterService(openRouterKey).chat(prompt);
    }

    throw StateError(
      'No API key configured. Add an $kPrimaryAiProviderName or $kFallbackAiProviderName API key in Settings.',
    );
  }
}
