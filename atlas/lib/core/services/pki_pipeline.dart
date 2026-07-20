import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import 'package:drift/drift.dart';

/// Personal Knowledge Index Pipeline
/// Runs after every event save to keep the system always learning.
class PKIPipeline {
  final AppDatabase _db;
  static const _uuid = Uuid();

  PKIPipeline(this._db);

  Future<void> process(String eventId) async {
    final event = await _db.getEventById(eventId);
    if (event == null) return;

    await _extractAndLinkEntities(event);
    await _detectRelationships(event);
    await _generateSimpleEmbedding(event);
    await _updateStatistics(event);
    await _detectPatternChanges(event);
    await _refreshConfidenceScores();
    await _invalidateAnalyticsCache();
  }

  // ── Step 1: Extract entities mentioned in note ────────────────────────────

  Future<void> _extractAndLinkEntities(Event event) async {
    // Simple heuristic: find @mentions and existing entity names in the note
    final allEntities = await _db.getAllEntities();
    final linkedIds = List<String>.from(jsonDecode(event.linkedEntityIds));

    for (final entity in allEntities) {
      if (linkedIds.contains(entity.id)) continue;
      final nameLower = entity.name.toLowerCase();
      final noteLower = event.note.toLowerCase();
      if (noteLower.contains(nameLower) && nameLower.length > 2) {
        linkedIds.add(entity.id);
      }
    }

    await _db.upsertEvent(EventsCompanion(
      id: Value(event.id),
      linkedEntityIds: Value(jsonEncode(linkedIds)),
    ));
  }

  // ── Step 2: Detect relationships between linked entities ──────────────────

  Future<void> _detectRelationships(Event event) async {
    final linkedIds = List<String>.from(jsonDecode(event.linkedEntityIds));
    if (linkedIds.length < 2) return;

    for (int i = 0; i < linkedIds.length; i++) {
      for (int j = i + 1; j < linkedIds.length; j++) {
        final fromId = linkedIds[i];
        final toId = linkedIds[j];

        // Check if relationship already exists
        final existing = await _db.getRelationshipsForEntity(fromId);
        final alreadyExists = existing.any(
          (r) => (r.fromEntityId == fromId && r.toEntityId == toId) ||
              (r.fromEntityId == toId && r.toEntityId == fromId),
        );

        if (!alreadyExists) {
          await _db.upsertRelationship(RelationshipsCompanion(
            id: Value(_uuid.v4()),
            fromEntityId: Value(fromId),
            toEntityId: Value(toId),
            relationshipType: Value('co_occurred'),
            strength: const Value(0.5),
          ));
        } else {
          // Strengthen existing relationship
          final rel = existing.firstWhere(
            (r) => (r.fromEntityId == fromId && r.toEntityId == toId) ||
                (r.fromEntityId == toId && r.toEntityId == fromId),
          );
          final newStrength = min(1.0, rel.strength + 0.05);
          await _db.upsertRelationship(RelationshipsCompanion(
            id: Value(rel.id),
            fromEntityId: Value(rel.fromEntityId),
            toEntityId: Value(rel.toEntityId),
            relationshipType: Value(rel.relationshipType),
            strength: Value(newStrength),
            updatedAt: Value(DateTime.now()),
          ));
        }
      }
    }
  }

  // ── Step 3: Generate simple TF-IDF style embedding ───────────────────────

  Future<void> _generateSimpleEmbedding(Event event) async {
    final vector = _textToVector(event.note);
    final existing = await _db.getEmbeddingForSource(event.id);
    await _db.upsertEmbedding(EmbeddingsCompanion(
      id: Value(existing?.id ?? _uuid.v4()),
      sourceType: const Value('event'),
      sourceId: Value(event.id),
      embeddingJson: Value(jsonEncode(vector)),
    ));
  }

  // ── Step 4: Update entity statistics ─────────────────────────────────────

  Future<void> _updateStatistics(Event event) async {
    final linkedIds = List<String>.from(jsonDecode(event.linkedEntityIds));
    for (final entityId in linkedIds) {
      final existing = await _db.getStatisticsForEntity(entityId);
      final allEntityEvents = await _db.getEventsForEntity(entityId);

      int totalEvents = allEntityEvents.length;
      int totalDecisions = allEntityEvents.where((e) => e.isDecision).length;

      final moodScores = allEntityEvents
          .where((e) => e.mood != null)
          .map((e) => _moodScore(e.mood!))
          .toList();
      final avgMood = moodScores.isEmpty
          ? 0.0
          : moodScores.reduce((a, b) => a + b) / moodScores.length;

      final importances = allEntityEvents.map((e) => e.importance.toDouble()).toList();
      final avgImportance = importances.isEmpty
          ? 0.0
          : importances.reduce((a, b) => a + b) / importances.length;

      // Mood distribution
      final moodDist = <String, int>{};
      for (final e in allEntityEvents) {
        if (e.mood != null) moodDist[e.mood!] = (moodDist[e.mood!] ?? 0) + 1;
      }

      // Monthly activity
      final monthlyActivity = <String, int>{};
      for (final e in allEntityEvents) {
        final key = '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}';
        monthlyActivity[key] = (monthlyActivity[key] ?? 0) + 1;
      }

      await _db.upsertStatistics(EntityStatisticsCompanion(
        entityId: Value(entityId),
        totalEvents: Value(totalEvents),
        totalDecisions: Value(totalDecisions),
        avgMoodScore: Value(avgMood),
        avgImportance: Value(avgImportance),
        moodDistribution: Value(jsonEncode(moodDist)),
        monthlyActivity: Value(jsonEncode(monthlyActivity)),
        lastEventAt: Value(event.timestamp),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  // ── Step 5: Detect pattern changes ───────────────────────────────────────

  Future<void> _detectPatternChanges(Event event) async {
    final linkedIds = List<String>.from(jsonDecode(event.linkedEntityIds));
    if (linkedIds.isEmpty) return;

    // Association pattern: entities that frequently co-occur
    if (linkedIds.length >= 2) {
      final patternKey = (List<String>.from(linkedIds)..sort()).join('_');
      final allPatterns = await _db.getAllPatterns();
      final existing = allPatterns.where((p) => p.title.contains(patternKey)).firstOrNull;

      if (existing != null) {
        final evidence = List<String>.from(jsonDecode(existing.evidence));
        if (!evidence.contains(event.id)) evidence.add(event.id);
        final newConfidence = min(1.0, existing.occurrences / 10.0);
        await _db.upsertPattern(PatternsCompanion(
          id: Value(existing.id),
          title: Value(existing.title),
          description: Value(existing.description),
          patternType: Value(existing.patternType),
          relatedEntityIds: Value(existing.relatedEntityIds),
          evidence: Value(jsonEncode(evidence)),
          confidence: Value(newConfidence),
          occurrences: Value(existing.occurrences + 1),
          lastSeen: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      } else {
        await _db.upsertPattern(PatternsCompanion(
          id: Value(_uuid.v4()),
          title: Value('Co-occurrence: $patternKey'),
          description: Value('Entities frequently appear together in events'),
          patternType: const Value('association'),
          relatedEntityIds: Value(jsonEncode(linkedIds)),
          evidence: Value(jsonEncode([event.id])),
          confidence: const Value(0.1),
          occurrences: const Value(1),
          firstSeen: Value(DateTime.now()),
          lastSeen: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ));
      }
    }

    // Mood pattern: detect mood trends
    if (event.mood != null) {
      await _detectMoodPattern(event);
    }
  }

  Future<void> _detectMoodPattern(Event event) async {
    final recentEvents = await _db.getRecentEvents(limit: 10);
    final moods = recentEvents.where((e) => e.mood != null).map((e) => e.mood!).toList();
    if (moods.length < 5) return;

    final scores = moods.map(_moodScore).toList();
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    final trend = scores.last > avg ? 'improving' : 'declining';

    final allPatterns = await _db.getAllPatterns();
    final existing = allPatterns.where((p) => p.patternType == 'mood_trend').firstOrNull;

    if (existing != null) {
      await _db.upsertPattern(PatternsCompanion(
        id: Value(existing.id),
        title: Value('Mood Trend: ${trend.toUpperCase()}'),
        description: Value('Recent mood is $trend (avg score: ${avg.toStringAsFixed(2)})'),
        patternType: const Value('mood_trend'),
        relatedEntityIds: Value(existing.relatedEntityIds),
        evidence: Value(existing.evidence),
        confidence: Value(min(1.0, moods.length / 20.0)),
        occurrences: Value(existing.occurrences + 1),
        lastSeen: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    } else {
      await _db.upsertPattern(PatternsCompanion(
        id: Value(const Uuid().v4()),
        title: Value('Mood Trend: ${trend.toUpperCase()}'),
        description: Value('Recent mood is $trend (avg score: ${avg.toStringAsFixed(2)})'),
        patternType: const Value('mood_trend'),
        relatedEntityIds: const Value('[]'),
        evidence: const Value('[]'),
        confidence: const Value(0.3),
        occurrences: const Value(1),
        firstSeen: Value(DateTime.now()),
        lastSeen: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  // ── Step 6: Refresh confidence scores ────────────────────────────────────

  Future<void> _refreshConfidenceScores() async {
    final allPatterns = await _db.getAllPatterns();
    final now = DateTime.now();

    for (final pattern in allPatterns) {
      // Decay confidence based on recency
      final daysSinceLastSeen = now.difference(pattern.lastSeen).inDays;
      final decayFactor = exp(-daysSinceLastSeen / 90.0); // 90-day half-life
      final evidenceCount = (jsonDecode(pattern.evidence) as List).length;
      final newConfidence = min(1.0, (evidenceCount / 10.0) * decayFactor);

      await _db.upsertPattern(PatternsCompanion(
        id: Value(pattern.id),
        title: Value(pattern.title),
        description: Value(pattern.description),
        patternType: Value(pattern.patternType),
        relatedEntityIds: Value(pattern.relatedEntityIds),
        evidence: Value(pattern.evidence),
        confidence: Value(newConfidence),
        occurrences: Value(pattern.occurrences),
        firstSeen: Value(pattern.firstSeen),
        lastSeen: Value(pattern.lastSeen),
        updatedAt: Value(now),
      ));
    }
  }

  // ── Step 7: Invalidate stale cache ───────────────────────────────────────

  Future<void> _invalidateAnalyticsCache() async {
    // Cache entries expire after 1 hour by default; just let them expire naturally
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _moodScore(String mood) {
    const scores = {
      'excited': 1.0,
      'happy': 0.8,
      'calm': 0.6,
      'neutral': 0.5,
      'anxious': 0.35,
      'stressed': 0.25,
      'sad': 0.2,
      'angry': 0.1,
    };
    return scores[mood] ?? 0.5;
  }

  /// Simple bag-of-words vector (128-dim) for semantic similarity
  List<double> _textToVector(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toList();
    final vector = List<double>.filled(128, 0.0);
    for (final word in words) {
      final hash = word.hashCode.abs() % 128;
      vector[hash] += 1.0;
    }
    // Normalize
    final magnitude = sqrt(vector.map((v) => v * v).reduce((a, b) => a + b));
    if (magnitude > 0) {
      for (int i = 0; i < vector.length; i++) {
        vector[i] /= magnitude;
      }
    }
    return vector;
  }
}

// ── Event retrieval helper ────────────────────────────────────────────────────

extension AppDatabasePKI on AppDatabase {
  Future<Event?> getEventById(String id) =>
      (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();
}
