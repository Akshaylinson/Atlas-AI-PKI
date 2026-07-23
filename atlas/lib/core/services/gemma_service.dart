import '../database/app_database.dart';
import '../models/models.dart';
import 'decision_intelligence.dart';
import 'model_loader.dart';
import 'retrieval_engine.dart';

/// Local AI layer.
/// Answers are grounded in the Atlas knowledge base.
class GemmaService {
  final AppDatabase _db;
  final RetrievalEngine _retrieval;
  final DecisionIntelligenceEngine _decisionIntelligence;
  final ModelLoader _loader;

  GemmaService(this._db)
      : _retrieval = RetrievalEngine(_db),
        _decisionIntelligence = DecisionIntelligenceEngine(_db),
        _loader = ModelLoader();

  bool get isModelLoaded => _loader.isLoaded;
  bool get isModelLoading => _loader.isLoading;
  String? get modelLoadError => _loader.loadError;

  Future<bool> loadModel(String installDir) => _loader.load(installDir);

  Future<AIResponse> query(String userQuestion) async {
    final evidence = await _retrieval.retrieve(userQuestion);
    final context = await _buildContext(userQuestion, evidence);
    final responseText = _buildResponse(userQuestion, evidence, context);

    return AIResponse(
      question: userQuestion,
      answer: responseText,
      evidencePackage: evidence,
      context: context,
      timestamp: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _buildContext(
    String query,
    EvidencePackage evidence,
  ) async {
    final context = <String, dynamic>{};
    final matchedEntities = await _findMatchedEntities(query, evidence);
    final entityProfiles = <Map<String, dynamic>>[];

    for (final entity in matchedEntities.take(3)) {
      entityProfiles.add(await _buildEntityProfile(entity));
    }

    final events = <Map<String, dynamic>>[];
    for (final eventId in evidence.eventIds.take(10)) {
      final event = await _db.getEventById(eventId);
      if (event != null) {
        events.add({
          'id': event.id,
          'title': event.title,
          'note': event.note,
          'timestamp': event.timestamp.toIso8601String(),
          'mood': event.mood,
          'importance': event.importance,
          'isDecision': event.isDecision,
          'decisionReasoning': event.decisionReasoning,
          'decisionExpectedOutcome': event.decisionExpectedOutcome,
          'decisionActualOutcome': event.decisionActualOutcome,
          'decisionConfidence': event.decisionConfidence,
          'decisionReviewDate': event.decisionReviewDate?.toIso8601String(),
        });
      }
    }

    final patterns = <Map<String, dynamic>>[];
    final allPatterns = await _db.getAllPatterns();
    for (final patternId in evidence.patternIds.take(5)) {
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

    context['query'] = query;
    context['matchedEntities'] = entityProfiles;
    context['events'] = events;
    context['patterns'] = patterns;
    context['statistics'] = evidence.statistics;

    if (matchedEntities.isNotEmpty) {
      context['bestEntity'] = entityProfiles.isNotEmpty ? entityProfiles.first : null;
    }

    return context;
  }

  Future<List<Entity>> _findMatchedEntities(
    String query,
    EvidencePackage evidence,
  ) async {
    final byId = <String, Entity>{};
    final normalizedQuery = _normalizeQuery(query);

    for (final entityId in evidence.entityIds.take(10)) {
      final entity = await _db.getEntityById(entityId);
      if (entity != null) {
        byId[entity.id] = entity;
      }
    }

    final directMatches = await _db.searchEntities(query);
    for (final entity in directMatches) {
      byId[entity.id] = entity;
    }

    if (normalizedQuery != query) {
      final normalizedMatches = await _db.searchEntities(normalizedQuery);
      for (final entity in normalizedMatches) {
        byId[entity.id] = entity;
      }
    }

    final allEntities = await _db.getAllEntities();
    for (final entity in allEntities) {
      final score = _entityScore(entity, query, normalizedQuery);
      if (score > 0) {
        byId[entity.id] = entity;
      }
    }

    final entities = byId.values.toList();
    entities.sort((a, b) =>
        _entityScore(b, query, normalizedQuery).compareTo(_entityScore(a, query, normalizedQuery)));
    return entities;
  }

  String _normalizeQuery(String query) {
    var cleaned = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    const phrases = <String>[
      'say about',
      'tell me about',
      'show me',
      'what about',
      'who is',
      "who's",
      'whos',
      'describe',
      'explain',
      'give me details on',
      'give me info on',
      'information about',
      'details about',
    ];
    for (final phrase in phrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  double _entityScore(Entity entity, String query, String normalizedQuery) {
    final q = query.toLowerCase().trim();
    final nq = normalizedQuery.toLowerCase().trim();
    final name = entity.name.toLowerCase();
    final description = (entity.description ?? '').toLowerCase();
    final tags = entity.tags.toLowerCase();

    if (q.isEmpty && nq.isEmpty) {
      return 0.0;
    }
    if (name == q || name == nq) return 100.0;
    if (name.startsWith(nq) || name.startsWith(q)) return 95.0;
    if (name.contains(nq) || name.contains(q)) return 90.0;
    if (nq.contains(name) || q.contains(name)) return 85.0;
    if (description.contains(nq) || description.contains(q) || tags.contains(nq) || tags.contains(q)) {
      return 50.0;
    }

    final qWords = nq.isNotEmpty
        ? nq.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet()
        : q.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final nameWords = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final overlap = qWords.intersection(nameWords).length;
    if (overlap > 0) {
      return overlap * 10.0;
    }
    return 0.0;
  }

  Future<Map<String, dynamic>> _buildEntityProfile(Entity entity) async {
    final stats = await _db.getStatisticsForEntity(entity.id);
    final relationships = await _db.getRelationshipsForEntity(entity.id);
    final recentEvents = await _db.getEventsForEntity(entity.id);

    final relationshipSummaries = <Map<String, dynamic>>[];
    for (final rel in relationships.take(6)) {
      final otherId = rel.fromEntityId == entity.id ? rel.toEntityId : rel.fromEntityId;
      final other = await _db.getEntityById(otherId);
      relationshipSummaries.add({
        'otherEntityId': otherId,
        'otherEntityName': other?.name ?? otherId,
        'relationshipType': rel.relationshipType,
        'description': rel.description,
        'strength': rel.strength,
      });
    }

    final decisionEvents = recentEvents.where((e) => e.isDecision).take(5).map((e) {
      return {
        'title': e.title,
        'note': e.note,
        'confidence': e.decisionConfidence,
        'expectedOutcome': e.decisionExpectedOutcome,
        'actualOutcome': e.decisionActualOutcome,
        'reviewDate': e.decisionReviewDate?.toIso8601String(),
      };
    }).toList();

    Map<String, dynamic>? intelligence;
    try {
      final analysis = await _decisionIntelligence.analyzeEntity(entity.id);
      intelligence = {
        'trend': analysis.trend,
        'riskLevel': analysis.riskLevel,
        'evidenceStrength': analysis.evidenceStrength,
        'decisionCount': analysis.decisionCount,
        'relatedPatternCount': analysis.relatedPatternCount,
      };
    } catch (_) {
      intelligence = null;
    }

    return {
      'id': entity.id,
      'name': entity.name,
      'description': entity.description,
      'status': entity.status,
      'isDecision': entity.isDecision,
      'decisionReasoning': entity.decisionReasoning,
      'decisionConfidence': entity.decisionConfidence,
      'decisionExpectedOutcome': entity.decisionExpectedOutcome,
      'decisionActualOutcome': entity.decisionActualOutcome,
      'decisionReviewDate': entity.decisionReviewDate?.toIso8601String(),
      'totalEvents': stats?.totalEvents ?? 0,
      'totalDecisions': stats?.totalDecisions ?? 0,
      'avgMoodScore': stats?.avgMoodScore ?? 0.0,
      'avgImportance': stats?.avgImportance ?? 0.0,
      'lastEventAt': stats?.lastEventAt?.toIso8601String(),
      'moodDistribution': stats?.moodDistribution,
      'relationships': relationshipSummaries,
      'decisionEvents': decisionEvents,
      'intelligence': intelligence,
      'recentEvents': recentEvents.take(5).map((e) {
        return {
          'id': e.id,
          'title': e.title,
          'note': e.note,
          'timestamp': e.timestamp.toIso8601String(),
          'mood': e.mood,
          'importance': e.importance,
        };
      }).toList(),
    };
  }

  String _buildResponse(
    String question,
    EvidencePackage evidence,
    Map<String, dynamic> context,
  ) {
    final matchedEntities = (context['matchedEntities'] as List?) ?? [];
    final events = (context['events'] as List?) ?? [];
    final patterns = (context['patterns'] as List?) ?? [];
    final stats = (context['statistics'] as Map?) ?? {};
    final query = question.trim();

    if (query.isEmpty) {
      return 'Please ask a question about an entity, event, decision, or pattern.';
    }

    if (matchedEntities.isEmpty) {
      return _buildNoMatchResponse(question, evidence, stats, events, patterns);
    }

    final best = matchedEntities.first as Map<String, dynamic>;
    final name = best['name'] as String? ?? 'this entity';
    final description = (best['description'] as String? ?? '').trim();
    final status = best['status'] as String? ?? 'active';
    final totalEvents = best['totalEvents'] as int? ?? 0;
    final totalDecisions = best['totalDecisions'] as int? ?? 0;
    final avgMood = (best['avgMoodScore'] as num?)?.toDouble() ?? 0.0;
    final avgImportance = (best['avgImportance'] as num?)?.toDouble() ?? 0.0;
    final lastEventAt = best['lastEventAt'] as String?;
    final intelligence = best['intelligence'] as Map<String, dynamic>?;
    final relationships = (best['relationships'] as List?) ?? [];
    final decisionEvents = (best['decisionEvents'] as List?) ?? [];
    final recentEvents = (best['recentEvents'] as List?) ?? [];

    final sb = StringBuffer();
    sb.writeln('I found $name in your knowledge base.');
    sb.writeln('');

    if (description.isNotEmpty) {
      sb.writeln('Summary');
      sb.writeln('- $description');
      sb.writeln('');
    }

    sb.writeln('Profile');
    sb.writeln('- Status: $status');
    sb.writeln('- Total events: $totalEvents');
    sb.writeln('- Total decisions: $totalDecisions');
    sb.writeln('- Average mood: ${avgMood.toStringAsFixed(2)}');
    sb.writeln('- Average importance: ${avgImportance.toStringAsFixed(2)}');
    if (lastEventAt != null) {
      sb.writeln('- Last activity: $lastEventAt');
    }
    if (intelligence != null) {
      final trend = intelligence['trend'];
      final riskLevel = intelligence['riskLevel'];
      final evidenceStrength = (intelligence['evidenceStrength'] as num?)?.toDouble() ?? 0.0;
      sb.writeln('- Trend: $trend');
      sb.writeln('- Risk level: $riskLevel');
      sb.writeln('- Evidence strength: ${evidenceStrength.toStringAsFixed(2)}');
    }
    sb.writeln('');

    sb.writeln('Relationships');
    if (relationships.isEmpty) {
      sb.writeln('- No relationships are recorded yet for $name.');
    } else {
      for (final rel in relationships.take(5)) {
        final otherName = rel['otherEntityName'] as String? ?? 'unknown';
        final relType = rel['relationshipType'] as String? ?? 'related_to';
        final strength = (rel['strength'] as num?)?.toDouble() ?? 0.0;
        final relDesc = rel['description'] as String?;
        final detail = relDesc != null && relDesc.trim().isNotEmpty ? ' - ${relDesc.trim()}' : '';
        sb.writeln('- $otherName: $relType (${strength.toStringAsFixed(2)})$detail');
      }
    }
    sb.writeln('');

    if (decisionEvents.isNotEmpty || best['decisionReasoning'] != null) {
      sb.writeln('Decision context');
      if ((best['decisionReasoning'] as String?)?.trim().isNotEmpty ?? false) {
        sb.writeln('- Reasoning: ${best['decisionReasoning']}');
      }
      if ((best['decisionExpectedOutcome'] as String?)?.trim().isNotEmpty ?? false) {
        sb.writeln('- Expected outcome: ${best['decisionExpectedOutcome']}');
      }
      if ((best['decisionActualOutcome'] as String?)?.trim().isNotEmpty ?? false) {
        sb.writeln('- Actual outcome: ${best['decisionActualOutcome']}');
      }
      if ((best['decisionReviewDate'] as String?)?.isNotEmpty ?? false) {
        sb.writeln('- Review date: ${best['decisionReviewDate']}');
      }
      if (decisionEvents.isNotEmpty) {
        for (final item in decisionEvents.take(3)) {
          final title = item['title'] as String? ?? 'Decision';
          final note = item['note'] as String? ?? '';
          final confidence = item['confidence'];
          sb.writeln('- Event: $title');
          if (note.isNotEmpty) {
            sb.writeln('  Note: $note');
          }
          if (confidence != null) {
            sb.writeln('  Confidence: $confidence/10');
          }
        }
      }
      sb.writeln('');
    }

    if (recentEvents.isNotEmpty) {
      sb.writeln('Recent activity');
      for (final item in recentEvents.take(5)) {
        final ts = DateTime.tryParse(item['timestamp'] as String? ?? '');
        final dateStr = ts == null ? '' : '${ts.day}/${ts.month}/${ts.year}';
        final note = item['note'] as String? ?? '';
        final preview = note.length > 100 ? '${note.substring(0, 100)}...' : note;
        sb.writeln('- [$dateStr] $preview');
      }
      sb.writeln('');
    }

    if (patterns.isNotEmpty) {
      sb.writeln('Related patterns');
      for (final p in patterns.take(4)) {
        final title = p['title'] as String? ?? 'Pattern';
        final confidence = (p['confidence'] as num?)?.toDouble() ?? 0.0;
        final occurrences = p['occurrences'] ?? 0;
        sb.writeln('- $title (${(confidence * 100).toStringAsFixed(0)}% confidence, $occurrences occurrences)');
      }
      sb.writeln('');
    }

    if (stats.isNotEmpty) {
      sb.writeln('Knowledge base coverage');
      sb.writeln('- Supporting events: ${stats['totalRelevantEvents'] ?? 0}');
      sb.writeln('- Related entities: ${stats['totalRelevantEntities'] ?? 0}');
    }

    return sb.toString().trim();
  }

  String _buildNoMatchResponse(
    String question,
    EvidencePackage evidence,
    Map stats,
    List events,
    List patterns,
  ) {
    final sb = StringBuffer();
    sb.writeln('I could not find an exact match for "$question" in your knowledge base.');
    sb.writeln('');

    if (evidence.entityIds.isNotEmpty) {
      sb.writeln('Closest linked entities');
      for (final entityId in evidence.entityIds.take(5)) {
        sb.writeln('- $entityId');
      }
      sb.writeln('');
    }

    if (events.isNotEmpty) {
      sb.writeln('Relevant evidence');
      for (final item in events.take(4)) {
        final note = item['note'] as String? ?? '';
        final preview = note.length > 100 ? '${note.substring(0, 100)}...' : note;
        sb.writeln('- $preview');
      }
      sb.writeln('');
    }

    if (patterns.isNotEmpty) {
      sb.writeln('Matching patterns');
      for (final p in patterns.take(4)) {
        sb.writeln('- ${p['title']}');
      }
      sb.writeln('');
    }

    if (stats.isNotEmpty) {
      sb.writeln('Coverage');
      sb.writeln('- Supporting events: ${stats['totalRelevantEvents'] ?? 0}');
      sb.writeln('- Related entities: ${stats['totalRelevantEntities'] ?? 0}');
    } else {
      sb.writeln('Try asking about a person, event, decision, or pattern that exists in the database.');
    }

    return sb.toString().trim();
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
