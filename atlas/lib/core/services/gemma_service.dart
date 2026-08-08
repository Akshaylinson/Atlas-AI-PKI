import '../database/app_database.dart';
import '../models/models.dart';
import 'decision_intelligence.dart';
import 'model_loader.dart';
import 'retrieval_engine.dart';
import '../../shared/utils/utils.dart';

enum _QuestionIntent {
  relationship,
  decision,
  trend,
  profile,
  riskLevel,
  comparison,
  compatibility,
  general,
}

class GemmaService {
  final AppDatabase _db;
  final RetrievalEngine _retrieval;
  final DecisionIntelligenceEngine _decisionIntelligence;
  final ModelLoader _loader;

  final Map<String, Map<String, dynamic>> _sessionMemory = {};
  String? _activeEntityId;

  GemmaService(this._db)
      : _retrieval = RetrievalEngine(_db),
        _decisionIntelligence = DecisionIntelligenceEngine(_db),
        _loader = ModelLoader();

  bool get isModelLoaded => _loader.isLoaded;
  bool get isModelLoading => _loader.isLoading;
  String? get modelLoadError => _loader.loadError;

  Future<bool> loadModel(String installDir) => _loader.load(installDir);

  Future<String> generateRaw(String prompt) => _loader.generate(prompt);

  void clearSession() {
    _sessionMemory.clear();
    _activeEntityId = null;
  }

  Future<AIResponse> query(
    String userQuestion, {
    List<Map<String, String>> history = const [],
  }) async {
    final allEntities = await _db.getAllEntities();
    final intent = _detectIntent(userQuestion);
    final resolved = await _resolveEntities(
      userQuestion,
      intent,
      history,
      allEntities,
    );

    if (resolved.isAmbiguous) {
      return AIResponse(
        question: userQuestion,
        answer: resolved.clarificationQuestion!,
        evidencePackage: _emptyEvidence(userQuestion),
        context: const {},
        timestamp: DateTime.now(),
      );
    }

    if (resolved.entities.isEmpty) {
      return AIResponse(
        question: userQuestion,
        answer: _noMatchResponse(userQuestion),
        evidencePackage: _emptyEvidence(userQuestion),
        context: const {},
        timestamp: DateTime.now(),
      );
    }

    final profiles = <Map<String, dynamic>>[];
    for (final entity in resolved.entities) {
      profiles.add(await _cachedProfile(entity));
    }

    if (resolved.entities.length == 1) {
      _activeEntityId = resolved.entities.first.id;
    }

    String answer;
    if (intent == _QuestionIntent.comparison && profiles.length >= 2) {
      answer = _buildComparisonResponse(userQuestion, profiles[0], profiles[1]);
    } else if (intent == _QuestionIntent.compatibility) {
      answer = _buildCompatibilityResponse(userQuestion, profiles.first);
    } else {
      answer = _buildConversationalResponse(userQuestion, intent, profiles.first);
    }

    final evidence = await _retrieval.retrieve(userQuestion);
    final contextMap = <String, dynamic>{
      'matchedEntities': profiles,
      'events': profiles.first['recentEvents'] ?? const [],
      'entities': resolved.entities.map((e) => e.id).toList(),
      'patterns': evidence.patternIds,
      'statistics': evidence.statistics,
    };

    return AIResponse(
      question: userQuestion,
      answer: answer,
      evidencePackage: evidence,
      context: contextMap,
      timestamp: DateTime.now(),
    );
  }

  Future<_ResolvedEntities> _resolveEntities(
    String question,
    _QuestionIntent intent,
    List<Map<String, String>> history,
    List<Entity> allEntities,
  ) async {
    final query = question.toLowerCase();
    final focus = _extractFocusPhrase(question);

    if (intent == _QuestionIntent.comparison) {
      final pair = _findComparisonPair(question, allEntities);
      if (pair != null) {
        return _ResolvedEntities(entities: pair);
      }
    }

    final ranked = _rankEntities(question, focus, allEntities);
    if (ranked.isNotEmpty) {
      final best = ranked.first;
      final second = ranked.length > 1 ? ranked[1] : null;
      final gap = second == null ? 999.0 : best.value - second.value;
      final vague = _hasPronoun(query) || _isVague(query) || focus.isEmpty;

      if (best.value < 30.0) {
        return const _ResolvedEntities(entities: []);
      }

      if (vague && second != null && gap < 6.0 && best.value < 70.0) {
        return _ResolvedEntities.ambiguous(
          'I found a few possible matches: ${best.key.name}, ${second.key.name}. Which one did you mean?',
        );
      }

      return _ResolvedEntities(entities: [best.key]);
    }

    if (_hasPronoun(query) || _isVague(query)) {
      if (_activeEntityId != null) {
        final active = _entityById(allEntities, _activeEntityId!);
        if (active != null) {
          return _ResolvedEntities(entities: [active]);
        }
      }

      final fromHistory = _resolveFromHistory(history, allEntities);
      if (fromHistory != null) {
        return _ResolvedEntities(entities: [fromHistory]);
      }

      return const _ResolvedEntities.ambiguous(
        'I am not sure who you mean. Please mention the name.',
      );
    }

    return const _ResolvedEntities(entities: []);
  }

  List<MapEntry<Entity, double>> _rankEntities(
    String question,
    String focus,
    List<Entity> allEntities,
  ) {
    final scored = <MapEntry<Entity, double>>[];
    for (final entity in allEntities) {
      final score = _entityScore(entity, question, focus);
      if (score > 0) {
        scored.add(MapEntry(entity, score));
      }
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored;
  }

  double _entityScore(Entity entity, String question, String focus) {
    final q = _normalizeQuery(question);
    final fq = _normalizeQuery(focus);
    final name = _normalizeQuery(entity.name);
    final description = _normalizeQuery(entity.description ?? '');
    final tags = _normalizeQuery(entity.tags);

    if (q.isEmpty && fq.isEmpty) {
      return 0.0;
    }

    if (name == q || name == fq) {
      return 100.0;
    }

    if (fq.isNotEmpty && (name.contains(fq) || description.contains(fq) || tags.contains(fq))) {
      return 95.0;
    }

    if (name.contains(q) || q.contains(name)) {
      return 88.0;
    }

    if (description.contains(q) || tags.contains(q)) {
      return 70.0;
    }

    final queryTokens = _tokenize(fq.isNotEmpty ? fq : q);
    final nameTokens = _tokenize(name);
    final descTokens = _tokenize(description);
    final tagTokens = _tokenize(tags);
    final overlapTokens = _tokenOverlapCount(queryTokens, nameTokens) +
        _tokenOverlapCount(queryTokens, descTokens) +
        _tokenOverlapCount(queryTokens, tagTokens);

    if (overlapTokens < 2 && queryTokens.length > 1) {
      return 0.0;
    }

    final nameOverlap = _overlapScore(queryTokens, nameTokens);
    final descOverlap = _overlapScore(queryTokens, descTokens);
    final tagOverlap = _overlapScore(queryTokens, tagTokens);
    final focusOverlap = fq.isNotEmpty ? _overlapScore(_tokenize(fq), nameTokens) : 0.0;

    final score = (nameOverlap * 60.0) +
        (descOverlap * 18.0) +
        (tagOverlap * 22.0) +
        (focusOverlap * 20.0);

    return score.clamp(0.0, 84.0);
  }

  List<Entity>? _findComparisonPair(String query, List<Entity> all) {
    final ranked = _rankEntities(query, _extractFocusPhrase(query), all);
    if (ranked.length >= 2 && ranked[1].value >= 45.0) {
      return [ranked[0].key, ranked[1].key];
    }
    return null;
  }

  Entity? _resolveFromHistory(
    List<Map<String, String>> history,
    List<Entity> allEntities,
  ) {
    for (final turn in history.reversed.where((m) => m['role'] == 'user')) {
      final text = turn['text'] ?? '';
      final matches = _rankEntities(text, _extractFocusPhrase(text), allEntities);
      if (matches.isNotEmpty) {
        return matches.first.key;
      }
    }
    return null;
  }

  bool _hasPronoun(String q) {
    const pronouns = ['she', 'her', 'he', 'him', 'his', 'they', 'them', 'it', 'this', 'that'];
    final words = q.split(RegExp(r'\s+'));
    return words.any((w) => pronouns.contains(w.replaceAll(RegExp(r'[^a-z]'), '')));
  }

  bool _isVague(String q) {
    const vague = ['the project', 'the company', 'the person', 'the entity', 'the startup', 'more details'];
    return vague.any((v) => q.contains(v));
  }

  Future<Map<String, dynamic>> _cachedProfile(Entity entity) async {
    if (_sessionMemory.containsKey(entity.id)) {
      return _sessionMemory[entity.id]!;
    }
    final profile = await _buildEntityProfile(entity);
    _sessionMemory[entity.id] = profile;
    return profile;
  }

  String _buildConversationalResponse(
    String question,
    _QuestionIntent intent,
    Map<String, dynamic> profile,
  ) {
    final name = profile['name'] as String? ?? 'this entity';
    final intelligence = profile['intelligence'] as Map<String, dynamic>?;
    final relationships = (profile['relationships'] as List?) ?? const [];
    final recentEvents = (profile['recentEvents'] as List?) ?? const [];

    switch (intent) {
      case _QuestionIntent.profile:
        return _buildDetailedProfileResponse(name, profile, intelligence, relationships, recentEvents);
      case _QuestionIntent.trend:
        final trend = intelligence?['trend'] as String? ?? 'Stable';
        final totalEvents = profile['totalEvents'] as int? ?? 0;
        final lastAt = _safeDateLabel(profile['lastEventAt'] as String?);
        final sb = StringBuffer();
        sb.writeln('$name is trending $trend based on $totalEvents recorded events.');
        if (lastAt != 'Unknown date') {
          sb.writeln('Last activity: $lastAt.');
        }
        return sb.toString().trim();
      case _QuestionIntent.riskLevel:
        final risk = intelligence?['riskLevel'] as String? ?? 'Unknown';
        final evidenceStrength = intelligence?['evidenceStrength'] as num?;
        final sb = StringBuffer();
        sb.writeln('Risk level for $name: $risk.');
        if (evidenceStrength != null) {
          sb.writeln('Evidence strength: ${evidenceStrength.toStringAsFixed(2)}.');
        }
        if (recentEvents.isNotEmpty) {
          final latest = recentEvents.first;
          final note = latest['note'] as String? ?? '';
          if (note.isNotEmpty) {
            sb.writeln('Most recent: ${_shorten(note, 80)}');
          }
        }
        return sb.toString().trim();
      case _QuestionIntent.relationship:
        final nature = _inferRelationshipNature(relationships);
        final sb = StringBuffer();
        sb.writeln('Your relationship with $name appears to be $nature.');
        if (relationships.isNotEmpty) {
          for (final rel in relationships.take(3)) {
            final other = rel['otherEntityName'] as String? ?? '';
            final type = rel['relationshipType'] as String? ?? '';
            if (other.isNotEmpty) {
              sb.writeln('- $other: $type');
            }
          }
        }
        return sb.toString().trim();
      case _QuestionIntent.decision:
        final decisionEvents = (profile['decisionEvents'] as List?) ?? const [];
        final sb = StringBuffer();
        if (decisionEvents.isEmpty) {
          sb.writeln('No decision records found for $name yet.');
        } else {
          sb.writeln('${decisionEvents.length} decision(s) recorded for $name.');
          final latest = decisionEvents.first;
          final expected = latest['expectedOutcome'] as String? ?? '';
          final actual = latest['actualOutcome'] as String? ?? '';
          if (expected.isNotEmpty) sb.writeln('Expected: $expected');
          if (actual.isNotEmpty) sb.writeln('Actual: $actual');
        }
        return sb.toString().trim();
      case _QuestionIntent.comparison:
        return 'Tell me the second entity to compare with $name.';
      case _QuestionIntent.compatibility:
        return _buildCompatibilityResponse(question, profile);
      case _QuestionIntent.general:
        return _answerGeneralQuestion(question, name, profile, intelligence, relationships, recentEvents);
    }
  }

  String _answerGeneralQuestion(
    String question,
    String name,
    Map<String, dynamic> profile,
    Map<String, dynamic>? intelligence,
    List relationships,
    List recentEvents,
  ) {
    final q = question.toLowerCase();

    if (_containsAny(q, [
      'qualify as',
      'good fit',
      'fit as',
      'suitable for',
      'compatible with',
      'good life partner',
      'life partner',
      'partner for me',
      'does she fit',
      'does he fit',
      'right for me',
      'works for me',
    ])) {
      return _buildCompatibilityResponse(question, profile);
    }

    if (_containsAny(q, ['more details', 'tell me more', 'more about', 'expand', 'deeper', 'full details'])) {
      return _buildDetailedProfileResponse(name, profile, intelligence, relationships, recentEvents);
    }

    if (_containsAny(q, [
      'when did she joined',
      'when did he joined',
      'when did it join',
      'when did they join',
      'joined',
      'join',
      'first seen',
      'first activity',
      'started',
      'created',
      'added',
    ])) {
      final firstAt = _safeDateLabel(profile['firstEventAt'] as String?);
      final createdAt = _safeDateLabel(profile['createdAt'] as String?);
      if (firstAt != 'Unknown date') {
        return '$name first appears in your records on $firstAt.';
      }
      if (createdAt != 'Unknown date') {
        return '$name was added to your knowledge base on $createdAt.';
      }
      return 'I do not have a reliable join date for $name yet.';
    }

    if (_containsAny(q, ['mood', 'feeling', 'emotion', 'happy', 'sad'])) {
      final avg = (profile['avgMoodScore'] as num?)?.toDouble() ?? 0.0;
      final label = avg > 0.6 ? 'generally positive' : avg > 0.3 ? 'mixed' : 'mostly negative';
      final latest = recentEvents.isNotEmpty ? recentEvents.first['note'] as String? ?? '' : '';
      final latestText = latest.isNotEmpty ? ' Latest note: ${_shorten(latest, 80)}.' : '';
      return 'Mood for $name is $label (avg ${avg.toStringAsFixed(2)}).$latestText';
    }

    if (_containsAny(q, ['event', 'activity', 'recent', 'last', 'latest'])) {
      if (recentEvents.isEmpty) return 'No recent events found for $name.';
      final e = recentEvents.first;
      final ts = _safeDateLabel(e['timestamp'] as String?);
      final note = e['note'] as String? ?? '';
      return '[$ts] ${_shorten(note, 120)}';
    }

    if (_containsAny(q, ['importance', 'important', 'priority'])) {
      final avg = (profile['avgImportance'] as num?)?.toDouble() ?? 0.0;
      return 'Average importance for $name: ${avg.toStringAsFixed(1)} / 5, based on ${profile['totalEvents'] ?? 0} events.';
    }

    if (_containsAny(q, ['relationship', 'who is', 'who is this', 'what is the relationship', 'connection'])) {
      final nature = _inferRelationshipNature(relationships);
      final relNames = relationships
          .map((r) => r['otherEntityName'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      final sb = StringBuffer();
      sb.writeln('$name appears to be a $nature relationship.');
      if (relNames.isNotEmpty) {
        sb.writeln('Connected entities: ${relNames.take(4).join(', ')}.');
      }
      final last = _safeDateLabel(profile['lastEventAt'] as String?);
      if (last != 'Unknown date') {
        sb.writeln('Last activity: $last.');
      }
      return sb.toString().trim();
    }

    if (_containsAny(q, ['assign', 'fit', 'suitable', 'right for', 'good for', 'work on', 'qualify'])) {
      final relNames = relationships
          .map((r) => r['otherEntityName'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      if (relNames.isEmpty) {
        return 'No direct connections found between $name and other entities.';
      }
      return '$name is connected to: ${relNames.take(4).join(', ')}.';
    }

    if (_containsAny(q, ['summary', 'about', 'describe', 'what is', 'tell me about', 'say about', 'details'])) {
      return _buildDetailedProfileResponse(name, profile, intelligence, relationships, recentEvents);
    }

    final description = (profile['description'] as String? ?? '').trim();
    final totalEvents = profile['totalEvents'] as int? ?? 0;
    final firstAt = _safeDateLabel(profile['firstEventAt'] as String?);
    final pieces = <String>[];
    if (description.isNotEmpty) {
      pieces.add(description);
    }
    pieces.add('$totalEvents events recorded');
    if (firstAt != 'Unknown date') {
      pieces.add('first seen on $firstAt');
    }
    return pieces.join(' | ');
  }

  String _buildDetailedProfileResponse(
    String name,
    Map<String, dynamic> profile,
    Map<String, dynamic>? intelligence,
    List relationships,
    List recentEvents,
  ) {
    final description = (profile['description'] as String? ?? '').trim();
    final status = profile['status'] as String? ?? 'unknown';
    final totalEvents = profile['totalEvents'] as int? ?? 0;
    final totalDecisions = profile['totalDecisions'] as int? ?? 0;
    final avgMood = (profile['avgMoodScore'] as num?)?.toDouble() ?? 0.0;
    final avgImportance = (profile['avgImportance'] as num?)?.toDouble() ?? 0.0;
    final firstSeen = _safeDateLabel(profile['firstEventAt'] as String?);
    final lastActivity = _safeDateLabel(profile['lastEventAt'] as String?);
    final relationshipNature = _inferRelationshipNature(relationships);
    final sb = StringBuffer();

    sb.writeln('I found $name in your knowledge base.');
    if (description.isNotEmpty) {
      sb.writeln('');
      sb.writeln('Summary');
      sb.writeln('- $description');
    }

    sb.writeln('');
    sb.writeln('Profile');
    sb.writeln('- Status: $status');
    sb.writeln('- Relationship type: $relationshipNature');
    sb.writeln('- Total events: $totalEvents');
    sb.writeln('- Total decisions: $totalDecisions');
    sb.writeln('- Average mood: ${avgMood.toStringAsFixed(2)}');
    sb.writeln('- Average importance: ${avgImportance.toStringAsFixed(2)}');
    sb.writeln('- First seen: $firstSeen');
    sb.writeln('- Last activity: $lastActivity');
    if (intelligence != null) {
      sb.writeln('- Trend: ${intelligence['trend'] ?? 'Unknown'}');
      sb.writeln('- Risk level: ${intelligence['riskLevel'] ?? 'Unknown'}');
      final evidenceStrength = intelligence['evidenceStrength'] as num?;
      if (evidenceStrength != null) {
        sb.writeln('- Evidence strength: ${evidenceStrength.toStringAsFixed(2)}');
      }
    }

    if (relationships.isNotEmpty) {
      sb.writeln('');
      sb.writeln('Connections');
      for (final rel in relationships.take(5)) {
        final other = rel['otherEntityName'] as String? ?? '';
        final type = rel['relationshipType'] as String? ?? '';
        final strength = (rel['strength'] as num?)?.toDouble();
        if (other.isEmpty) continue;
        final strengthText = strength == null ? '' : ' (${strength.toStringAsFixed(2)})';
        sb.writeln('- $other: $type$strengthText');
      }
    }

    if (recentEvents.isNotEmpty) {
      sb.writeln('');
      sb.writeln('Recent activity');
      for (final item in recentEvents.take(4)) {
        final ts = _safeDateLabel(item['timestamp'] as String?);
        final note = item['note'] as String? ?? '';
        final title = item['title'] as String? ?? '';
        final text = note.isNotEmpty ? note : title;
        if (text.isEmpty) continue;
        sb.writeln('- [$ts] ${_shorten(text, 120)}');
      }
    }

    return sb.toString().trim();
  }

  String _buildCompatibilityResponse(String question, Map<String, dynamic> profile) {
    final name = profile['name'] as String? ?? 'this entity';
    final description = (profile['description'] as String? ?? '').trim();
    final relationships = (profile['relationships'] as List?) ?? const [];
    final recentEvents = (profile['recentEvents'] as List?) ?? const [];
    final intelligence = profile['intelligence'] as Map<String, dynamic>?;
    final target = _extractTargetPhrase(question);
    final score = _compatibilityScore(profile, target);
    final scorePct = (score * 100).round();
    final label = score >= 0.8
        ? 'strong fit'
        : score >= 0.6
            ? 'moderate fit'
            : score >= 0.4
                ? 'possible fit'
                : 'weak fit';
    final sb = StringBuffer();

    sb.writeln('I checked $name against "$target".');
    sb.writeln('Fit score: $scorePct/100 ($label).');
    sb.writeln('');

    if (description.isNotEmpty) {
      sb.writeln('Profile note');
      sb.writeln('- $description');
      sb.writeln('');
    }

    sb.writeln('Why this score');
    sb.writeln('- Relationship type: ${_inferRelationshipNature(relationships)}');
    sb.writeln('- Total events: ${profile['totalEvents'] ?? 0}');
    sb.writeln('- Average mood: ${((profile['avgMoodScore'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}');
    sb.writeln('- Average importance: ${((profile['avgImportance'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}');
    if (intelligence != null) {
      sb.writeln('- Trend: ${intelligence['trend'] ?? 'Unknown'}');
      sb.writeln('- Risk level: ${intelligence['riskLevel'] ?? 'Unknown'}');
    }
    sb.writeln('');

    if (_containsAny(target, ['partner', 'life partner'])) {
      sb.writeln('Partner check');
      sb.writeln('- This is a cautious compatibility read, not a hard verdict.');
      sb.writeln('- Look for trust, consistency, and repeated positive events before deciding.');
    } else {
      sb.writeln('Role or requirement check');
      sb.writeln('- This is based on the evidence in your records, not an outside resume or profile.');
    }

    if (recentEvents.isNotEmpty) {
      sb.writeln('');
      sb.writeln('Recent evidence');
      for (final item in recentEvents.take(3)) {
        final ts = _safeDateLabel(item['timestamp'] as String?);
        final note = item['note'] as String? ?? '';
        final text = note.isEmpty ? (item['title'] as String? ?? '') : note;
        if (text.isEmpty) continue;
        sb.writeln('- [$ts] ${_shorten(text, 90)}');
      }
    }

    return sb.toString().trim();
  }

  double _compatibilityScore(Map<String, dynamic> profile, String target) {
    final text = [
      profile['name'] as String? ?? '',
      profile['description'] as String? ?? '',
      profile['tags'] as String? ?? '',
      (profile['relationships'] as List? ?? const [])
          .map((r) => '${r['relationshipType'] ?? ''} ${r['description'] ?? ''}')
          .join(' '),
      (profile['recentEvents'] as List? ?? const [])
          .map((e) => e['note'] as String? ?? '')
          .join(' '),
    ].join(' ').toLowerCase();

    final targetTokens = _tokenize(target);
    if (targetTokens.isEmpty) {
      return 0.45;
    }

    final textTokens = _tokenize(text);
    final overlap = _overlapScore(targetTokens, textTokens);

    var score = 0.3 + overlap * 0.35;
    if (_containsAny(target, ['partner', 'life partner'])) {
      final mood = (profile['avgMoodScore'] as num?)?.toDouble() ?? 0.0;
      final relationshipNature = _inferRelationshipNature((profile['relationships'] as List?) ?? const []);
      if (relationshipNature == 'personal') score += 0.15;
      if (mood > 0.55) score += 0.1;
    } else {
      final importance = (profile['avgImportance'] as num?)?.toDouble() ?? 0.0;
      if (importance > 3.8) score += 0.1;
    }

    return score.clamp(0.0, 0.95);
  }

  String _buildComparisonResponse(
    String question,
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final nameA = a['name'] as String? ?? 'Entity A';
    final nameB = b['name'] as String? ?? 'Entity B';
    final intA = a['intelligence'] as Map<String, dynamic>?;
    final intB = b['intelligence'] as Map<String, dynamic>?;
    final relsA = (a['relationships'] as List?) ?? const [];
    final relsB = (b['relationships'] as List?) ?? const [];

    final sb = StringBuffer();
    sb.writeln('Comparing $nameA vs $nameB:');
    sb.writeln('');
    sb.writeln('Events: $nameA (${a['totalEvents'] ?? 0}) | $nameB (${b['totalEvents'] ?? 0})');
    sb.writeln('Avg mood: $nameA (${((a['avgMoodScore'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}) | $nameB (${((b['avgMoodScore'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)})');
    sb.writeln('Avg importance: $nameA (${((a['avgImportance'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}) | $nameB (${((b['avgImportance'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)})');

    if (intA != null && intB != null) {
      sb.writeln('Trend: $nameA (${intA['trend'] ?? 'Unknown'}) | $nameB (${intB['trend'] ?? 'Unknown'})');
      sb.writeln('Risk: $nameA (${intA['riskLevel'] ?? 'Unknown'}) | $nameB (${intB['riskLevel'] ?? 'Unknown'})');
    }

    final shared = _sharedRelationship(nameA, nameB, relsA, relsB);
    if (shared != null) {
      sb.writeln('Shared relationship: $shared');
    }

    return sb.toString().trim();
  }

  String? _sharedRelationship(
    String nameA,
    String nameB,
    List relsA,
    List relsB,
  ) {
    for (final rel in relsA) {
      if ((rel['otherEntityName'] as String? ?? '') == nameB) {
        final type = rel['relationshipType'] as String? ?? 'related_to';
        return '$nameA $type $nameB';
      }
    }
    for (final rel in relsB) {
      if ((rel['otherEntityName'] as String? ?? '') == nameA) {
        final type = rel['relationshipType'] as String? ?? 'related_to';
        return '$nameB $type $nameA';
      }
    }
    return null;
  }

  String _noMatchResponse(String question) {
    return 'I could not find a direct match for "$question" in your knowledge base. '
        'Try mentioning a specific name, role, or relationship.';
  }

  Future<Map<String, dynamic>> _buildEntityProfile(Entity entity) async {
    final stats = await _db.getStatisticsForEntity(entity.id);
    final relationships = await _db.getRelationshipsForEntity(entity.id);
    final allEvents = await _db.getEventsForEntity(entity.id);
    final allEntities = await _db.getAllEntities();
    final recentEvents = allEvents.take(5).toList();

    final relationshipSummaries = <Map<String, dynamic>>[];
    for (final rel in relationships.take(6)) {
      final otherId = rel.fromEntityId == entity.id ? rel.toEntityId : rel.fromEntityId;
      final other = _entityById(allEntities, otherId);
      relationshipSummaries.add({
        'otherEntityId': otherId,
        'otherEntityName': other?.name ?? otherId,
        'relationshipType': rel.relationshipType,
        'description': rel.description,
        'strength': rel.strength,
      });
    }

    final decisionEvents = allEvents.where((e) => e.isDecision).take(5).map((e) {
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
      'tags': entity.tags,
      'createdAt': entity.createdAt.toIso8601String(),
      'totalEvents': stats?.totalEvents ?? 0,
      'totalDecisions': stats?.totalDecisions ?? 0,
      'avgMoodScore': stats?.avgMoodScore ?? 0.0,
      'avgImportance': stats?.avgImportance ?? 0.0,
      'lastEventAt': stats?.lastEventAt?.toIso8601String(),
      'firstEventAt': allEvents.isNotEmpty ? allEvents.last.timestamp.toIso8601String() : null,
      'relationships': relationshipSummaries,
      'decisionEvents': decisionEvents,
      'intelligence': intelligence,
      'recentEvents': recentEvents.map((e) {
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

  _QuestionIntent _detectIntent(String query) {
    final q = query.toLowerCase();

    if (_containsAny(q, ['vs', ' vs ', 'compare', 'versus', 'difference between', 'both'])) {
      return _QuestionIntent.comparison;
    }
    if (_containsAny(q, [
      'qualify as',
      'good fit',
      'fit as',
      'suitable for',
      'compatible with',
      'good life partner',
      'life partner',
      'partner for me',
      'does she fit',
      'does he fit',
      'does it fit',
      'right for me',
      'works for me',
    ])) {
      return _QuestionIntent.compatibility;
    }
    if (_containsAny(q, ['risk', 'danger', 'safe', 'concern', 'worry', 'threat'])) {
      return _QuestionIntent.riskLevel;
    }
    if (_containsAny(q, [
      'relationship',
      'partner',
      'dating',
      'boyfriend',
      'girlfriend',
      'husband',
      'wife',
      'love',
      'crush',
      'compatible',
      'compatibility',
    ])) {
      return _QuestionIntent.relationship;
    }
    if (_containsAny(q, ['should i', 'should we', 'recommend', 'decision', 'choose', 'decide', 'worth', 'accept', 'reject', 'next step'])) {
      return _QuestionIntent.decision;
    }
    if (_containsAny(q, ['trend', 'trending', 'over time', 'this month', 'this week', 'last week', 'last month', 'history', 'progress', 'increase', 'decrease'])) {
      return _QuestionIntent.trend;
    }
    if (_containsAny(q, ['who is', 'tell me about', 'describe', 'what is', 'summary', 'details about', 'info on', 'information about'])) {
      return _QuestionIntent.profile;
    }
    return _QuestionIntent.general;
  }

  String _normalizeQuery(String query) {
    var cleaned = query.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    const phrases = [
      'say about',
      'tell me about',
      'show me',
      'what about',
      'who is',
      'who\'s',
      'whos',
      'describe',
      'explain',
      'give me details on',
      'give me info on',
      'more details',
      'details about',
      'information about',
    ];
    for (final phrase in phrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _extractFocusPhrase(String query) {
    var cleaned = _normalizeQuery(query);
    cleaned = cleaned.replaceAll(
      RegExp(r'^(?:my|the|a|an|this|that|our|your|new|some|any)\s+'),
      '',
    );
    return cleaned.trim();
  }

  String _extractTargetPhrase(String query) {
    var cleaned = _normalizeQuery(query);
    const phrases = [
      'qualify as',
      'good fit for',
      'fit as',
      'compatible with',
      'good life partner',
      'life partner',
      'partner for me',
      'does she fit',
      'does he fit',
      'does it fit',
      'right for me',
      'works for me',
      'for me',
      'for us',
      'to me',
    ];
    for (final phrase in phrases) {
      cleaned = cleaned.replaceAll(phrase, ' ');
    }
    cleaned = cleaned.replaceAll(
      RegExp(r'^(?:is|are|was|were|am|be|being|been|would|should|could|can|do|does|did|i think|i wonder)\s+'),
      '',
    );
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  bool _containsAny(String text, List<String> phrases) {
    final lower = text.toLowerCase();
    for (final phrase in phrases) {
      if (lower.contains(phrase.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_stopWords.contains(t))
        .toList();
  }

  int _tokenOverlapCount(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    return a.toSet().intersection(b.toSet()).length;
  }

  double _overlapScore(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final setA = a.toSet();
    final setB = b.toSet();
    final matches = setA.intersection(setB).length;
    return matches / setA.length;
  }

  static const Set<String> _stopWords = {
    'a',
    'an',
    'and',
    'are',
    'as',
    'at',
    'be',
    'been',
    'being',
    'can',
    'could',
    'did',
    'do',
    'does',
    'for',
    'from',
    'good',
    'fit',
    'fits',
    'how',
    'i',
    'is',
    'it',
    'like',
    'me',
    'more',
    'my',
    'of',
    'on',
    'or',
    'partner',
    'right',
    'say',
    'should',
    'some',
    'tell',
    'that',
    'the',
    'their',
    'them',
    'there',
    'this',
    'to',
    'too',
    'up',
    'us',
    'was',
    'we',
    'what',
    'when',
    'where',
    'who',
    'why',
    'with',
    'you',
    'your',
    'qualify',
    'compatible',
    'suitable',
    'works',
  };

  String _inferRelationshipNature(List relationships) {
    var personal = 0;
    var professional = 0;
    for (final rel in relationships) {
      final combined = '${rel['relationshipType'] ?? ''} ${rel['description'] ?? ''}'.toLowerCase();
      if (_containsAny(combined, ['friend', 'partner', 'spouse', 'dating', 'romantic', 'love', 'family'])) {
        personal += 2;
      }
      if (_containsAny(combined, ['manage', 'manager', 'coworker', 'colleague', 'project', 'team', 'work', 'client'])) {
        professional += 2;
      }
    }
    if (personal > professional) return 'personal';
    if (professional > personal) return 'professional';
    return 'mixed';
  }

  String _safeDateLabel(String? iso) {
    if (iso == null || iso.isEmpty) return 'Unknown date';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return 'Unknown date';
    final now = DateTime.now();
    if (dt.year < 1970 || dt.year > now.year + 5) return 'Unknown date';
    return formatDate(dt);
  }

  String _shorten(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  Entity? _entityById(List<Entity> entities, String id) {
    for (final entity in entities) {
      if (entity.id == id) {
        return entity;
      }
    }
    return null;
  }

  EvidencePackage _emptyEvidence(String query) {
    return EvidencePackage(
      eventIds: const [],
      entityIds: const [],
      patternIds: const [],
      statistics: const {},
      similarEventIds: const [],
      query: query,
    );
  }
}

class _ResolvedEntities {
  final List<Entity> entities;
  final bool isAmbiguous;
  final String? clarificationQuestion;

  const _ResolvedEntities({required this.entities})
      : isAmbiguous = false,
        clarificationQuestion = null;

  const _ResolvedEntities.ambiguous(this.clarificationQuestion)
      : entities = const [],
        isAmbiguous = true;
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
