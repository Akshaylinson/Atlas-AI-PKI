import '../database/app_database.dart';
import '../models/models.dart';
import 'decision_intelligence.dart';
import 'model_loader.dart';
import 'retrieval_engine.dart';
import '../../shared/utils/utils.dart';

/// Local AI layer.
/// Answers are grounded in the Atlas knowledge base.
enum _QuestionIntent { relationship, decision, trend, profile, general }

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

  Future<AIResponse> query(
    String userQuestion, {
    List<Map<String, String>> history = const [],
  }) async {
    final resolvedQuestion = await _resolveWithHistory(userQuestion, history);
    final evidence = await _retrieval.retrieve(resolvedQuestion);
    final context = await _buildContext(resolvedQuestion, evidence);
    final responseText = _buildResponse(resolvedQuestion, evidence, context);

    return AIResponse(
      question: userQuestion,
      answer: responseText,
      evidencePackage: evidence,
      context: context,
      timestamp: DateTime.now(),
    );
  }

  /// Resolves pronouns and vague references using conversation history.
  /// If the current question has no direct entity match, injects the last
  /// clearly-named entity from prior turns into the query.
  Future<String> _resolveWithHistory(
    String question,
    List<Map<String, String>> history,
  ) async {
    if (history.isEmpty) return question;

    // Check if the current question already resolves to an entity on its own.
    final directMatches = await _db.searchEntities(question);
    final allEntities = await _db.getAllEntities();
    final hasDirectMatch = directMatches.isNotEmpty ||
        allEntities.any((e) => _entityScore(e, question, _normalizeQuery(question)) > 0);
    if (hasDirectMatch) return question;

    // Walk history newest-first to find the last entity that was clearly named.
    final userTurns = history.reversed
        .where((m) => m['role'] == 'user')
        .map((m) => m['text'] ?? '')
        .toList();

    for (final pastQuery in userTurns) {
      final matches = await _db.searchEntities(pastQuery);
      if (matches.isNotEmpty) {
        // Inject the resolved entity name as context prefix.
        return '${matches.first.name}: $question';
      }
      final normalized = _normalizeQuery(pastQuery);
      final scored = allEntities
          .where((e) => _entityScore(e, pastQuery, normalized) > 0)
          .toList();
      if (scored.isNotEmpty) {
        scored.sort((a, b) => _entityScore(b, pastQuery, normalized)
            .compareTo(_entityScore(a, pastQuery, normalized)));
        return '${scored.first.name}: $question';
      }
    }

    return question;
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
    final lastEventAt = _safeDateLabel(best['lastEventAt'] as String?);
    final intelligence = best['intelligence'] as Map<String, dynamic>?;
    final relationships = (best['relationships'] as List?) ?? [];
    final recentEvents = (best['recentEvents'] as List?) ?? [];
    final intent = _detectIntent(query);
    final relationshipNature = _inferRelationshipNature(relationships);
    final confidence = _estimateConfidence(best, evidence, matchedEntities, intent);
    final confidenceText = confidenceLabel(confidence);
    final confidencePct = (confidence * 100).round();

    final sb = StringBuffer();
    sb.writeln(_openingLine(intent, name, relationshipNature));
    sb.writeln('');

    if (intent == _QuestionIntent.relationship) {
      sb.writeln('Short answer');
      if (relationshipNature == 'personal') {
        sb.writeln('- Your records point to a personal relationship with $name.');
      } else if (relationshipNature == 'professional') {
        sb.writeln('- Your records point mostly to a professional relationship with $name.');
      } else {
        sb.writeln('- Your records point to a mixed or unclear relationship with $name.');
      }
      sb.writeln('');
      sb.writeln('Why I think that');
      sb.writeln('- Relationship type: $relationshipNature');
      sb.writeln('- Total events: $totalEvents');
      sb.writeln('- Decision records: $totalDecisions');
      sb.writeln('- Average mood: ${avgMood.toStringAsFixed(2)}');
      sb.writeln('- Average importance: ${avgImportance.toStringAsFixed(2)}');
      if (description.isNotEmpty) {
        sb.writeln('- Profile note: $description');
      }
      if (lastEventAt != 'Unknown date') {
        sb.writeln('- Last activity: $lastEventAt');
      }
      sb.writeln('');
      _writeRelationshipEvidence(sb, relationships, recentEvents, patterns, best);
    } else if (intent == _QuestionIntent.decision) {
      sb.writeln('Short answer');
      sb.writeln('- This looks like a decision that needs more evidence before you act.');
      sb.writeln('');
      sb.writeln('Evidence');
      sb.writeln('- Entity: $name');
      sb.writeln('- Relationship type: $relationshipNature');
      sb.writeln('- Total events: $totalEvents');
      sb.writeln('- Decision records: $totalDecisions');
      sb.writeln('- Average mood: ${avgMood.toStringAsFixed(2)}');
      sb.writeln('- Average importance: ${avgImportance.toStringAsFixed(2)}');
      if (lastEventAt != 'Unknown date') {
        sb.writeln('- Last activity: $lastEventAt');
      }
      sb.writeln('');
      _writeRelationshipEvidence(sb, relationships, recentEvents, patterns, best);
    } else if (intent == _QuestionIntent.trend) {
      final trend = intelligence?['trend'] as String? ?? 'Stable';
      sb.writeln('Trend summary');
      sb.writeln('- $name is trending $trend based on the recorded activity.');
      sb.writeln('- Total events: $totalEvents');
      sb.writeln('- Average mood: ${avgMood.toStringAsFixed(2)}');
      sb.writeln('- Average importance: ${avgImportance.toStringAsFixed(2)}');
      if (lastEventAt != 'Unknown date') {
        sb.writeln('- Last activity: $lastEventAt');
      }
      sb.writeln('');
      _writeRelationshipEvidence(sb, relationships, recentEvents, patterns, best);
    } else {
      sb.writeln('Summary');
      if (description.isNotEmpty) {
        sb.writeln('- $description');
      }
      sb.writeln('- Status: $status');
      sb.writeln('- Relationship type: $relationshipNature');
      sb.writeln('- Total events: $totalEvents');
      sb.writeln('- Decision records: $totalDecisions');
      sb.writeln('- Average mood: ${avgMood.toStringAsFixed(2)}');
      sb.writeln('- Average importance: ${avgImportance.toStringAsFixed(2)}');
      if (lastEventAt != 'Unknown date') {
        sb.writeln('- Last activity: $lastEventAt');
      }
      if (intelligence != null) {
        sb.writeln('- Trend: ${intelligence['trend']}');
        sb.writeln('- Risk level: ${intelligence['riskLevel']}');
      }
      sb.writeln('');
      _writeRelationshipEvidence(sb, relationships, recentEvents, patterns, best);
    }

    sb.writeln('Confidence');
    sb.writeln('- $confidenceText ($confidencePct%)');
    sb.writeln('- Evidence coverage: ${stats['totalRelevantEvents'] ?? 0} events, ${stats['totalRelevantEntities'] ?? 0} entities');

    return sb.toString().trim();
  }

  String _openingLine(
    _QuestionIntent intent,
    String name,
    String relationshipNature,
  ) {
    switch (intent) {
      case _QuestionIntent.relationship:
        if (relationshipNature == 'personal') {
          return 'I found $name, and your records point to a personal relationship.';
        }
        if (relationshipNature == 'professional') {
          return 'I found $name, and your records point mostly to a professional relationship.';
        }
        return 'I found $name, but the relationship type is still mixed or unclear.';
      case _QuestionIntent.decision:
        return 'I found $name, and this looks like a decision question.';
      case _QuestionIntent.trend:
        return 'I found $name, and I can summarize the trend from your records.';
      case _QuestionIntent.profile:
      case _QuestionIntent.general:
        return 'I found $name in your knowledge base.';
    }
  }

  _QuestionIntent _detectIntent(String query) {
    final q = query.toLowerCase();
    if (_containsAny(q, const [
      'relationship',
      'partner',
      'dating',
      'date',
      'marry',
      'married',
      'boyfriend',
      'girlfriend',
      'husband',
      'wife',
      'love',
      'crush',
      'standards',
      'deserve',
      'compatible',
      'compatibility',
    ])) {
      return _QuestionIntent.relationship;
    }

    if (_containsAny(q, const [
      'should i',
      'should we',
      'recommend',
      'decision',
      'choose',
      'decide',
      'whether',
      'worth',
      'take',
      'accept',
      'reject',
      'make',
      'move',
      'next step',
    ])) {
      return _QuestionIntent.decision;
    }

    if (_containsAny(q, const [
      'trend',
      'trending',
      'change',
      'changed',
      'over time',
      'recent',
      'this month',
      'this week',
      'last week',
      'last month',
      'pattern',
      'history',
      'timeline',
      'progress',
      'increase',
      'decrease',
    ])) {
      return _QuestionIntent.trend;
    }

    if (_containsAny(q, const [
      'who is',
      'tell me about',
      'say about',
      'describe',
      'explain',
      'what is',
      'summary',
      'details about',
      'info on',
      'information about',
    ])) {
      return _QuestionIntent.profile;
    }

    return _QuestionIntent.general;
  }

  bool _containsAny(String value, List<String> phrases) {
    for (final phrase in phrases) {
      if (value.contains(phrase)) {
        return true;
      }
    }
    return false;
  }

  String _inferRelationshipNature(List relationships) {
    var personalScore = 0;
    var professionalScore = 0;

    for (final rel in relationships) {
      final type = (rel['relationshipType'] as String? ?? '').toLowerCase();
      final description = (rel['description'] as String? ?? '').toLowerCase();
      final combined = '$type $description';

      if (_containsAny(combined, const [
        'friend',
        'partner',
        'spouse',
        'dating',
        'romantic',
        'love',
        'family',
        'wife',
        'husband',
      ])) {
        personalScore += 2;
      }

      if (_containsAny(combined, const [
        'manage',
        'manager',
        'reports_to',
        'report_to',
        'coworker',
        'colleague',
        'project',
        'team',
        'work',
        'client',
        'influence',
        'part_of',
      ])) {
        professionalScore += 2;
      }
    }

    if (personalScore > professionalScore) return 'personal';
    if (professionalScore > personalScore) return 'professional';
    return 'mixed';
  }

  double _estimateConfidence(
    Map<String, dynamic> best,
    EvidencePackage evidence,
    List matchedEntities,
    _QuestionIntent intent,
  ) {
    var score = 0.35;

    if ((best['name'] as String?)?.isNotEmpty ?? false) {
      score += 0.15;
    }
    if (evidence.eventIds.isNotEmpty) {
      score += (evidence.eventIds.length.clamp(0, 20) / 20.0) * 0.15;
    }
    if (evidence.entityIds.isNotEmpty) {
      score += (evidence.entityIds.length.clamp(0, 10) / 10.0) * 0.1;
    }
    if ((best['relationships'] as List?)?.isNotEmpty ?? false) {
      score += 0.1;
    }
    if ((best['recentEvents'] as List?)?.isNotEmpty ?? false) {
      score += 0.1;
    }
    if ((best['decisionEvents'] as List?)?.isNotEmpty ?? false) {
      score += 0.05;
    }
    if (matchedEntities.length > 1) {
      score += 0.05;
    }
    if (intent == _QuestionIntent.relationship || intent == _QuestionIntent.decision) {
      score += 0.05;
    }

    return score.clamp(0.0, 0.98);
  }

  String _safeDateLabel(String? iso) {
    if (iso == null || iso.isEmpty) return 'Unknown date';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Unknown date';
    final currentYear = DateTime.now().year;
    if (dt.year < 1970 || dt.year > currentYear + 5) {
      return 'Unknown date';
    }
    return formatDate(dt);
  }

  void _writeRelationshipEvidence(
    StringBuffer sb,
    List relationships,
    List recentEvents,
    List patterns,
    Map<String, dynamic> best,
  ) {
    sb.writeln('Evidence');

    final hasDecisionReasoning = _hasText(best['decisionReasoning']);
    final hasDecisionExpected = _hasText(best['decisionExpectedOutcome']);
    final hasDecisionActual = _hasText(best['decisionActualOutcome']);
    final hasDecisionReview = _hasText(best['decisionReviewDate']);

    if (relationships.isNotEmpty) {
      sb.writeln('- Relationships');
      for (final rel in relationships.take(4)) {
        final otherName = rel['otherEntityName'] as String? ?? 'unknown';
        final relType = rel['relationshipType'] as String? ?? 'related_to';
        final strength = (rel['strength'] as num?)?.toDouble() ?? 0.0;
        final relDesc = (rel['description'] as String?)?.trim();
        final detail = relDesc != null && relDesc.isNotEmpty ? ' - $relDesc' : '';
        sb.writeln('  - $otherName: $relType (${strength.toStringAsFixed(2)})$detail');
      }
    }

    if (hasDecisionReasoning || hasDecisionExpected || hasDecisionActual || hasDecisionReview) {
      sb.writeln('- Decision context');
      if (hasDecisionReasoning) {
        sb.writeln('  - Reasoning: ${best['decisionReasoning']}');
      }
      if (hasDecisionExpected) {
        sb.writeln('  - Expected outcome: ${best['decisionExpectedOutcome']}');
      }
      if (hasDecisionActual) {
        sb.writeln('  - Actual outcome: ${best['decisionActualOutcome']}');
      }
      final decisionReview = _safeDateLabel(best['decisionReviewDate'] as String?);
      if (decisionReview != 'Unknown date') {
        sb.writeln('  - Review date: $decisionReview');
      }
    }

    if (recentEvents.isNotEmpty) {
      sb.writeln('- Recent activity');
      for (final item in recentEvents.take(4)) {
        final ts = _safeDateLabel(item['timestamp'] as String?);
        final note = item['note'] as String? ?? '';
        final preview = note.length > 100 ? '${note.substring(0, 100)}...' : note;
        sb.writeln('  - [$ts] $preview');
      }
    }

    if (patterns.isNotEmpty) {
      sb.writeln('- Related patterns');
      for (final p in patterns.take(4)) {
        final title = p['title'] as String? ?? 'Pattern';
        final confidence = (p['confidence'] as num?)?.toDouble() ?? 0.0;
        final occurrences = p['occurrences'] ?? 0;
        sb.writeln('  - $title (${(confidence * 100).toStringAsFixed(0)}% confidence, $occurrences occurrences)');
      }
    }

    sb.writeln('');
  }

  bool _hasText(Object? value) {
    return value is String && value.trim().isNotEmpty;
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
