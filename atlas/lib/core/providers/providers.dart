import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/models.dart';
import '../services/pki_pipeline.dart';
import '../services/retrieval_engine.dart';
import '../services/analytics_engine.dart';
import '../services/decision_intelligence.dart';
import '../services/gemma_service.dart';
import '../services/pattern_ai_service.dart';
import '../services/file_storage_service.dart';
import '../services/ai_api_service.dart'
    show AiApiService, kPrimaryAiProviderName, kFallbackAiProviderName;
import '../services/host_capability.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

enum AiMode { off, local, api }

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

final decisionIntelligenceProvider =
    Provider<DecisionIntelligenceEngine>((ref) {
  return DecisionIntelligenceEngine(ref.watch(databaseProvider));
});

// Tracks model load state so the UI can rebuild on changes
class _ModelState {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  const _ModelState(
      {this.isLoading = false, this.isLoaded = false, this.error});
}

class GemmaServiceNotifier extends StateNotifier<_ModelState> {
  final GemmaService service;

  GemmaServiceNotifier(this.service) : super(const _ModelState());

  Future<void> loadModel(String path) async {
    state = const _ModelState(isLoading: true);
    final ok = await service.loadModel(path);
    state = ok
        ? const _ModelState(isLoaded: true)
        : _ModelState(error: service.modelLoadError ?? 'Unknown error');
  }

  Future<void> unloadModel() async {
    await service.disposeRuntime();
    state = const _ModelState();
  }

  bool get isLoaded => state.isLoaded;
  bool get isLoading => state.isLoading;
  String? get modelLoadError => state.error;
}

final gemmaServiceProvider =
    StateNotifierProvider<GemmaServiceNotifier, _ModelState>((ref) {
  return GemmaServiceNotifier(GemmaService(ref.watch(databaseProvider)));
});

class _AiModeNotifier extends StateNotifier<AiMode> {
  final Ref _ref;

  _AiModeNotifier(this._ref) : super(AiMode.off) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _ref.read(databaseProvider).getSetting('ai_mode');
    if (!mounted) return;
    final mode = raw == 'api'
        ? AiMode.api
        : raw == 'local'
            ? AiMode.local
            : AiMode.off;
    state = mode;
  }

  Future<void> set(AiMode mode) async {
    final prev = state;
    state = mode;
    await _ref.read(databaseProvider).setSetting(
        'ai_mode',
        mode == AiMode.api
            ? 'api'
            : mode == AiMode.local
                ? 'local'
                : 'off');
    if (mode != AiMode.local && prev == AiMode.local) {
      await _ref.read(gemmaServiceProvider.notifier).unloadModel();
    }
  }
}

final aiModeProvider = StateNotifierProvider<_AiModeNotifier, AiMode>((ref) {
  return _AiModeNotifier(ref);
});

final fileStorageProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

/// Builds AiApiService from both stored keys — used by chat and matrix AI.
final aiApiServiceProvider = FutureProvider<AiApiService>((ref) async {
  final db = ref.watch(databaseProvider);
  final orKey = await db.getSetting('openrouter_api_key') ?? '';
  final geminiKey = await db.getSetting('gemini_api_key') ?? '';
  return AiApiService(openRouterKey: orKey, geminiKey: geminiKey);
});

final hostCapabilityProvider = FutureProvider<HostCapabilityProfile>((ref) {
  return HostCapabilityProfile.detect();
});

// ── Entity Providers ──────────────────────────────────────────────────────────

final entitiesStreamProvider = StreamProvider<List<Entity>>((ref) {
  return ref.watch(databaseProvider).watchAllEntities();
});

final entityByIdProvider = StreamProvider.family<Entity?, String>((ref, id) {
  return ref.watch(databaseProvider).watchEntityById(id);
});

final entitySearchProvider =
    FutureProvider.family<List<Entity>, String>((ref, query) {
  if (query.isEmpty) return ref.watch(databaseProvider).getAllEntities();
  return ref.watch(databaseProvider).searchEntities(query);
});

// ── Event Providers ───────────────────────────────────────────────────────────

final eventsStreamProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(databaseProvider).watchAllEvents();
});

final eventsForEntityProvider =
    StreamProvider.family<List<Event>, String>((ref, entityId) {
  return ref.watch(databaseProvider).watchEventsForEntity(entityId);
});

final matricesForEntityProvider =
    StreamProvider.family<List<DecisionMatrix>, String>((ref, entityId) {
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

class PatternAiState {
  final bool isRunning;
  final String? error;
  final List<PatternAiRun> history;

  const PatternAiState({
    this.isRunning = false,
    this.error,
    this.history = const [],
  });

  PatternAiRun? get latestRun => history.isEmpty ? null : history.first;

  Map<String, PatternAiLabel> get latestLabelsByPatternId {
    final latest = latestRun;
    if (latest == null) return const {};
    return {
      for (final label in latest.labels) label.patternId: label,
    };
  }

  static const Object _unset = Object();

  PatternAiState copyWith({
    bool? isRunning,
    Object? error = _unset,
    List<PatternAiRun>? history,
  }) {
    return PatternAiState(
      isRunning: isRunning ?? this.isRunning,
      error: error == _unset ? this.error : error as String?,
      history: history ?? this.history,
    );
  }
}

class PatternAiNotifier extends StateNotifier<PatternAiState> {
  final Ref _ref;

  PatternAiNotifier(this._ref) : super(const PatternAiState()) {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final raw = await _ref
        .read(databaseProvider)
        .getSetting(PatternAiService.historySettingKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final history = decoded
            .whereType<Map>()
            .map((item) =>
                PatternAiRun.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        if (!mounted) return;
        state = state.copyWith(history: history);
      }
    } catch (_) {
      if (!mounted) return;
      state =
          state.copyWith(error: 'Stored pattern AI history could not be read.');
    }
  }

  Future<void> runScan() async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, error: null);

    try {
      final db = _ref.read(databaseProvider);
      final patterns = await db.getAllPatterns();
      final recentEvents = await db.getRecentEvents(limit: 20);
      final relationships = await db.getAllRelationships();

      if (patterns.isEmpty) {
        throw StateError('No patterns available to analyze yet.');
      }

      final service = _ref.read(patternAiServiceProvider);
      final prompt = service.buildPrompt(
        patterns: patterns,
        recentEvents: recentEvents,
        relationships: relationships,
      );

      final backend = await _resolveBackend();
      final rawResponse = switch (backend.$1) {
        _PatternAiBackend.local => backend.$2.generateRaw(prompt),
        _PatternAiBackend.api => backend.$3.chat(prompt),
      };

      final response = await rawResponse;
      final analysis = service.parseAnalysis(response, patterns);
      final run = PatternAiRun(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        timestamp: DateTime.now(),
        backend: backend.$1.name,
        summary:
            analysis.summary.isEmpty ? 'AI scan completed.' : analysis.summary,
        labels: analysis.labels,
      );

      final history = [run, ...state.history].take(10).toList();
      await db.setSetting(
        PatternAiService.historySettingKey,
        jsonEncode(history.map((item) => item.toJson()).toList()),
      );

      if (!mounted) return;
      state = state.copyWith(isRunning: false, history: history, error: null);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isRunning: false, error: e.toString());
    }
  }

  Future<(_PatternAiBackend, GemmaService, AiApiService)>
      _resolveBackend() async {
    final mode = _ref.read(aiModeProvider);
    final gemma = _ref.read(gemmaServiceProvider.notifier).service;
    final api = await _ref.read(aiApiServiceProvider.future);

    final candidates = switch (mode) {
      AiMode.local => [_PatternAiBackend.local, _PatternAiBackend.api],
      AiMode.api => [_PatternAiBackend.api, _PatternAiBackend.local],
      AiMode.off => [_PatternAiBackend.local, _PatternAiBackend.api],
    };

    for (final candidate in candidates) {
      if (candidate == _PatternAiBackend.local && gemma.isModelLoaded) {
        return (candidate, gemma, api);
      }
      if (candidate == _PatternAiBackend.api && api.hasAnyKey) {
        return (candidate, gemma, api);
      }
    }

    throw StateError(
      mode == AiMode.api
          ? 'No API key configured. Add a Gemini or OpenRouter API key in Settings.'
          : 'No AI model is available yet. Load a local model or configure an API key in Settings.',
    );
  }
}

enum _PatternAiBackend { local, api }

final patternAiServiceProvider = Provider<PatternAiService>((ref) {
  return PatternAiService();
});

final patternAiProvider =
    StateNotifierProvider<PatternAiNotifier, PatternAiState>((ref) {
  return PatternAiNotifier(ref);
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

    final history = state
        .where((m) => m.id != userMsg.id)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'text': m.text})
        .toList();

    try {
      final response = await _gemma.query(text, history: history);
      String finalAnswer = response.answer;

      if (mode == AiMode.local) {
        final isLoaded = _ref.read(gemmaServiceProvider.notifier).isLoaded;
        if (!isLoaded) {
          finalAnswer =
              'Local AI model is not loaded yet. Toggle AI off and on again to reload.';
        } else {
          final hasKbData = response.context.isNotEmpty &&
              ((response.context['entities'] as List?)?.isNotEmpty == true ||
                  (response.context['events'] as List?)?.isNotEmpty == true ||
                  (response.context['patterns'] as List?)?.isNotEmpty == true);
          final prompt = hasKbData
              ? 'You are Atlas, a personal knowledge assistant. Answer using ONLY the evidence below. Be concise.\n\nEvidence:\n${response.answer}\n\nQuestion: $text'
              : 'You are Atlas, a personal knowledge assistant. The user asked: "$text"\n\nKnowledge base result: "${response.answer}"\n\nRespond helpfully.';
          finalAnswer = await _gemma.generateRaw(prompt);
        }
      } else if (mode == AiMode.api) {
        final apiService = await _ref.read(aiApiServiceProvider.future);
        if (!apiService.hasAnyKey) {
          finalAnswer =
              'No API key configured. Go to Settings and add an $kPrimaryAiProviderName or $kFallbackAiProviderName API key.';
        } else {
          final hasKbData = response.context.isNotEmpty &&
              ((response.context['entities'] as List?)?.isNotEmpty == true ||
                  (response.context['events'] as List?)?.isNotEmpty == true ||
                  (response.context['patterns'] as List?)?.isNotEmpty == true);
          final prompt = hasKbData
              ? 'You are Atlas, a personal knowledge assistant. Answer the user question using ONLY the evidence below. Be concise and natural.\n\nEvidence:\n${response.answer}\n\nQuestion: $text'
              : 'You are Atlas, a personal knowledge assistant. The user asked: "$text"\n\nThe knowledge base returned: "${response.answer}"\n\nRespond helpfully. If the entity or data is not found, say so clearly and suggest the user verify the name or add data first.';
          finalAnswer = await apiService.chat(prompt);
        }
      }

      state = [
        ...state,
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_ai',
          text: finalAnswer,
          isUser: false,
          timestamp: DateTime.now(),
          context: response.context,
        )
      ];
    } catch (e) {
      state = [
        ...state,
        ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_err',
          text: 'Error: $e',
          isUser: false,
          timestamp: DateTime.now(),
        )
      ];
    }
  }

  void clear() {
    _gemma.clearSession();
    state = [];
  }
}

final aiChatProvider =
    StateNotifierProvider<AIChatNotifier, List<ChatMessage>>((ref) {
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
