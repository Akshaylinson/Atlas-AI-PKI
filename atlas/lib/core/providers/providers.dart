import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../services/pki_pipeline.dart';
import '../services/retrieval_engine.dart';
import '../services/analytics_engine.dart';
import '../services/decision_intelligence.dart';
import '../services/gemma_service.dart';
import '../services/file_storage_service.dart';
import '../services/model_installer.dart';
import '../services/model_loader.dart';
import '../services/openrouter_service.dart';


final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

enum AiMode { off, api }

// ── Core Services ─────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final pkiPipelineProvider = Provider<PKIPipeline>((ref) {
  return PKIPipeline(ref.watch(databaseProvider));
});

final retrievalEngineProvider = Provider<RetrievalEngine>((ref) {
  return RetrievalEngine(ref.watch(databaseProvider));
});

final analyticsEngineProvider = Provider<AnalyticsEngine>((ref) {
  return AnalyticsEngine(ref.watch(databaseProvider));
});

final decisionIntelligenceProvider = Provider<DecisionIntelligenceEngine>((ref) {
  return DecisionIntelligenceEngine(ref.watch(databaseProvider));
});

final modelInstallerProvider = Provider<ModelInstaller>((ref) => ModelInstaller());

final modelInstallProvider = FutureProvider<String?>((ref) async {
  // First try the user-saved path from DB.
  final savedPath = await ref.watch(databaseProvider).getSetting('gemma_model_path');
  if (savedPath != null &&
      savedPath.isNotEmpty &&
      supportedGemmaModelExtensions.any(savedPath.toLowerCase().endsWith)) {
    return savedPath;
  }
  // Fallback: try bundled asset install.
  return ref.watch(modelInstallerProvider).ensureInstalled();
});

// Tracks model load state so the UI can rebuild on changes
class _ModelState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  const _ModelState({this.isLoading = false, this.isLoaded = false, this.error});
}

class GemmaServiceNotifier extends StateNotifier<_ModelState> {
  final GemmaService service;

  GemmaServiceNotifier(this.service) : super(const _ModelState());

  Future<void> loadModel(String path) async {
    state = const _ModelState(isLoading: true);
    final ok = await service.loadModel(path);
    if (ok) {
      state = const _ModelState(isLoaded: true);
    } else {
      state = _ModelState(error: service.modelLoadError ?? 'Unknown error');
    }
  }

  bool get isLoaded => state.isLoaded;
  bool get isLoading => state.isLoading;
  String? get modelLoadError => state.error;
}

final gemmaServiceProvider = StateNotifierProvider<GemmaServiceNotifier, _ModelState>((ref) {
  return GemmaServiceNotifier(GemmaService(ref.watch(databaseProvider)));
});

class _AiModeNotifier extends StateNotifier<AiMode> {
  final Ref _ref;

  _AiModeNotifier(this._ref) : super(AiMode.off) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _ref.read(databaseProvider).getSetting('ai_mode');
    if (raw == 'api') {
      state = AiMode.api;
    } else {
      state = AiMode.off;
    }
  }

  Future<void> set(AiMode mode) async {
    state = mode;
    await _ref.read(databaseProvider).setSetting(
          'ai_mode',
          mode == AiMode.api ? 'api' : 'off',
        );
  }
}

final aiModeProvider = StateNotifierProvider<_AiModeNotifier, AiMode>((ref) {
  return _AiModeNotifier(ref);
});

final fileStorageProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

// ── Entity Providers ──────────────────────────────────────────────────────────

final entitiesStreamProvider = StreamProvider<List<Entity>>((ref) {
  return ref.watch(databaseProvider).watchAllEntities();
});

final entityByIdProvider = StreamProvider.family<Entity?, String>((ref, id) {
  return ref.watch(databaseProvider).watchEntityById(id);
});

final entitySearchProvider = FutureProvider.family<List<Entity>, String>((ref, query) {
  if (query.isEmpty) return ref.watch(databaseProvider).getAllEntities();
  return ref.watch(databaseProvider).searchEntities(query);
});

// ── Event Providers ───────────────────────────────────────────────────────────

final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(databaseProvider).watchAllEvents();
});

final eventsForEntityProvider = StreamProvider.family<List<Event>, String>((ref, entityId) {
  return ref.watch(databaseProvider).watchEventsForEntity(entityId);
});

final matricesForEntityProvider = StreamProvider.family<List<DecisionMatrix>, String>((ref, entityId) {
  return ref.watch(databaseProvider).watchMatricesForEntity(entityId);
});

final allMatricesProvider = StreamProvider<List<DecisionMatrix>>((ref) {
  return ref.watch(databaseProvider).watchAllMatrices();
});
final recentEventsProvider = FutureProvider<List<Event>>((ref) {
  return ref.watch(databaseProvider).getRecentEvents(limit: 20);
});

// ── Relationship Providers ────────────────────────────────────────────────────

final allRelationshipsProvider = StreamProvider<List<Relationship>>((ref) {
  return ref.watch(databaseProvider).watchAllRelationships();
});

final relationshipsForEntityProvider =
    FutureProvider.family<List<Relationship>, String>((ref, entityId) {
  return ref.watch(databaseProvider).getRelationshipsForEntity(entityId);
});

// ── Pattern Providers ─────────────────────────────────────────────────────────

final patternsStreamProvider = StreamProvider<List<Pattern>>((ref) {
  return ref.watch(databaseProvider).watchAllPatterns();
});

// ── Statistics Providers ──────────────────────────────────────────────────────

final entityStatsProvider =
    FutureProvider.family<EntityStatistic?, String>((ref, entityId) {
  return ref.watch(databaseProvider).getStatisticsForEntity(entityId);
});

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(databaseProvider);
  final totalEvents = await db.getTotalEventCount();
  final totalEntities = await db.getTotalEntityCount();
  final moodDist = await db.getMoodDistribution();
  final recentEvents = await db.getRecentEvents(limit: 5);
  final patterns = await db.getAllPatterns();
  return DashboardStats(
    totalEvents: totalEvents,
    totalEntities: totalEntities,
    moodDistribution: moodDist,
    recentEvents: recentEvents,
    patternCount: patterns.length,
    highConfidencePatterns: patterns.where((p) => p.confidence > 0.7).length,
  );
});

// ── Decision Providers ────────────────────────────────────────────────────────

final decisionEntitiesProvider = FutureProvider<List<Entity>>((ref) {
  return ref.watch(databaseProvider).getDecisionEntities();
});

final decisionEventsProvider = FutureProvider<List<Event>>((ref) {
  return ref.watch(databaseProvider).getDecisionEvents();
});

// ── AI Chat State ─────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Map<String, dynamic>? context;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.context,
  });
}

class AIChatNotifier extends StateNotifier<List<ChatMessage>> {
  final GemmaService _gemma;
  final Ref _ref;

  AIChatNotifier(this._gemma, this._ref) : super([]);

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    state = [...state, userMsg];
    final mode = _ref.read(aiModeProvider);

    // Build history from current messages (excluding the one just added).
    final history = state
        .where((m) => m.id != userMsg.id)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();

    try {
      final response = await _gemma.query(text, history: history);
      String finalAnswer = response.answer;

      if (mode == AiMode.api) {
        final apiKey =
            await _ref.read(databaseProvider).getSetting('openrouter_api_key');
        if (apiKey == null || apiKey.trim().isEmpty) {
          finalAnswer =
              'OpenRouter API key not set. Go to Settings and add your API key.';
        } else {
          final openrouter = OpenRouterService(apiKey);
          final enrichedPrompt = '''
System: Atlas is a personal knowledge assistant that answers only from evidence.
Evidence from the knowledge base:
${response.answer}

Original user question:
$text
''';
          finalAnswer = await openrouter.chat(enrichedPrompt);
        }
      }

      final aiMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_ai',
        text: finalAnswer,
        isUser: false,
        timestamp: DateTime.now(),
        context: response.context,
      );
      state = [...state, aiMsg];
    } catch (e) {
      final errMsg = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_err',
        text: 'Error: $e',
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = [...state, errMsg];
    }
  }

  void clear() {
    _gemma.clearSession();
    state = [];
  }
}

final aiChatProvider = StateNotifierProvider<AIChatNotifier, List<ChatMessage>>((ref) {
  return AIChatNotifier(ref.watch(gemmaServiceProvider.notifier).service, ref);
});

// ── Dashboard Stats Model ─────────────────────────────────────────────────────

class DashboardStats {
  final int totalEvents;
  final int totalEntities;
  final Map<String, int> moodDistribution;
  final List<Event> recentEvents;
  final int patternCount;
  final int highConfidencePatterns;

  const DashboardStats({
    required this.totalEvents,
    required this.totalEntities,
    required this.moodDistribution,
    required this.recentEvents,
    required this.patternCount,
    required this.highConfidencePatterns,
  });
}




