import 'dart:convert';
import '../database/app_database.dart';
import '../models/models.dart';
import 'retrieval_engine.dart';
import 'analytics_engine.dart';
import 'model_loader.dart';

/// Local AI Layer
/// Gemma reasons over evidence packages - never invents statistics.
class GemmaService {
  final AppDatabase _db;
  final RetrievalEngine _retrieval;
  final AnalyticsEngine _analytics;
  final ModelLoader _loader;

  GemmaService(this._db)
      : _retrieval = RetrievalEngine(_db),
        _analytics = AnalyticsEngine(_db),
        _loader = ModelLoader();

  bool get isModelLoaded => _loader.isLoaded;

  /// Load the Gemma model from internal storage install directory
  Future<bool> loadModel(String installDir) => _loader.load(installDir);

  /// Main query entry point
  Future<AIResponse> query(String userQuestion) async {
    // Step 1: Retrieve evidence
    final evidence = await _retrieval.retrieve(userQuestion);

    // Step 2: Build context from evidence
    final context = await _buildContext(evidence);

    // Step 3: Generate response
    String responseText;
    if (_loader.isLoaded) {
      responseText = await _runGemma(userQuestion, context);
    } else {
      responseText = _buildEvidenceBasedResponse(userQuestion, evidence, context);
    }

    return AIResponse(
      question: userQuestion,
      answer: responseText,
      evidencePackage: evidence,
      context: context,
      timestamp: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _buildContext(EvidencePackage evidence) async {
    final context = <String, dynamic>{};

    // Load relevant events
    final events = <Map<String, dynamic>>[];
    for (final eventId in evidence.eventIds.take(10)) {
      final event = await _db.getEventById(eventId);
      if (event != null) {
        events.add({
          'note': event.note,
          'timestamp': event.timestamp.toIso8601String(),
          'mood': event.mood,
          'importance': event.importance,
        });
      }
    }
    context['events'] = events;

    // Load relevant entities
    final entities = <Map<String, dynamic>>[];
    for (final entityId in evidence.entityIds.take(5)) {
      final entity = await _db.getEntityById(entityId);
      if (entity != null) {
        final stats = await _db.getStatisticsForEntity(entityId);
        entities.add({
          'name': entity.name,
          'description': entity.description,
          'totalEvents': stats?.totalEvents ?? 0,
          'avgMood': stats?.avgMoodScore ?? 0.0,
        });
      }
    }
    context['entities'] = entities;

    // Load patterns
    final patterns = <Map<String, dynamic>>[];
    for (final patternId in evidence.patternIds.take(5)) {
      final allPatterns = await _db.getAllPatterns();
      final pattern = allPatterns.where((p) => p.id == patternId).firstOrNull;
      if (pattern != null) {
        patterns.add({
          'title': pattern.title,
          'description': pattern.description,
          'confidence': pattern.confidence,
          'occurrences': pattern.occurrences,
        });
      }
    }
    context['patterns'] = patterns;
    context['statistics'] = evidence.statistics;

    return context;
  }

  /// When Gemma model is loaded, pass structured prompt
  Future<String> _runGemma(String question, Map<String, dynamic> context) async {
    final prompt = _buildPrompt(question, context);
    return _loader.generate(prompt);
  }

  String _buildPrompt(String question, Map<String, dynamic> context) {
    final sb = StringBuffer();
    sb.writeln('You are Atlas, a personal intelligence assistant.');
    sb.writeln('You ONLY reason over the evidence provided. Never invent statistics.');
    sb.writeln('');
    sb.writeln('QUESTION: $question');
    sb.writeln('');
    sb.writeln('EVIDENCE:');
    sb.writeln(jsonEncode(context));
    sb.writeln('');
    sb.writeln('Provide an evidence-based answer. Reference specific events and patterns.');
    sb.writeln('Do not give absolute recommendations. Present evidence and let the user decide.');
    return sb.toString();
  }

  /// Fallback: structured evidence response without LLM
  String _buildEvidenceBasedResponse(
      String question, EvidencePackage? evidence, Map<String, dynamic> context) {
    final sb = StringBuffer();
    sb.writeln('Based on your recorded data:\n');

    final events = context['events'] as List? ?? [];
    final entities = context['entities'] as List? ?? [];
    final patterns = context['patterns'] as List? ?? [];
    final stats = context['statistics'] as Map? ?? {};

    if (events.isEmpty && entities.isEmpty) {
      return 'No relevant data found for your query. Try recording more events related to this topic.';
    }

    if (entities.isNotEmpty) {
      sb.writeln('**Relevant Entities (${entities.length})**');
      for (final e in entities) {
        sb.writeln('• ${e['name']}: ${e['totalEvents']} events recorded');
      }
      sb.writeln('');
    }

    if (events.isNotEmpty) {
      sb.writeln('**Recent Relevant Events (${events.length})**');
      for (final e in events.take(5)) {
        final note = e['note'] as String;
        final ts = DateTime.tryParse(e['timestamp'] ?? '');
        final dateStr = ts != null ? '${ts.day}/${ts.month}/${ts.year}' : '';
        sb.writeln('• [$dateStr] ${note.length > 80 ? '${note.substring(0, 80)}...' : note}');
      }
      sb.writeln('');
    }

    if (patterns.isNotEmpty) {
      sb.writeln('**Discovered Patterns**');
      for (final p in patterns) {
        final conf = ((p['confidence'] as double) * 100).toStringAsFixed(0);
        sb.writeln('• ${p['title']} (${conf}% confidence, ${p['occurrences']} occurrences)');
      }
      sb.writeln('');
    }

    if (stats['totalRelevantEvents'] != null) {
      sb.writeln('**Evidence Summary**');
      sb.writeln('• Supporting events: ${stats['totalRelevantEvents']}');
      sb.writeln('• Related entities: ${stats['totalRelevantEntities']}');
    }

    return sb.toString();
  }
}

class AIResponse {
  final String question;
  final String answer;
  final EvidencePackage evidencePackage;
  final Map<String, dynamic> context;
  final DateTime timestamp;

  const AIResponse({
    required this.question,
    required this.answer,
    required this.evidencePackage,
    required this.context,
    required this.timestamp,
  });
}
