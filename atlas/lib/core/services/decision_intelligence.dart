import 'dart:convert';
import 'dart:math';
import '../database/app_database.dart';

class DecisionIntelligenceEngine {
  final AppDatabase _db;

  DecisionIntelligenceEngine(this._db);

  Future<DecisionEvidence> analyzeEntity(String entityId) async {
    final entity = await _db.getEntityById(entityId);
    if (entity == null) throw Exception('Entity not found');

    final events = await _db.getEventsForEntity(entityId);
    final stats = await _db.getStatisticsForEntity(entityId);
    final relationships = await _db.getRelationshipsForEntity(entityId);
    final allPatterns = await _db.getAllPatterns();

    final relatedPatterns = allPatterns
        .where((p) => p.relatedEntityIds.contains(entityId))
        .toList();

    // Calculate metrics
    final totalEvents = events.length;
    final decisionEvents = events.where((e) => e.isDecision).length;
    final moodScores = events
        .where((e) => e.mood != null)
        .map((e) => _moodScore(e.mood!))
        .toList();
    final avgMood = moodScores.isEmpty
        ? 0.5
        : moodScores.reduce((a, b) => a + b) / moodScores.length;

    // Trend: compare last 30 days vs previous 30 days
    final now = DateTime.now();
    final last30 = events.where((e) => e.timestamp.isAfter(now.subtract(const Duration(days: 30)))).length;
    final prev30 = events.where((e) =>
        e.timestamp.isAfter(now.subtract(const Duration(days: 60))) &&
        e.timestamp.isBefore(now.subtract(const Duration(days: 30)))).length;
    final trend = last30 > prev30 ? 'Increasing' : last30 < prev30 ? 'Decreasing' : 'Stable';

    // Evidence strength: based on event count and recency
    final evidenceStrength = min(1.0, totalEvents / 20.0) * 0.7 +
        (stats?.lastEventAt != null
            ? max(0.0, 1.0 - now.difference(stats!.lastEventAt!).inDays / 365.0) * 0.3
            : 0.0);

    // Risk level
    String riskLevel;
    if (evidenceStrength > 0.7 && avgMood > 0.6) {
      riskLevel = 'Low Risk';
    } else if (evidenceStrength > 0.4 || avgMood > 0.4) {
      riskLevel = 'Medium Risk';
    } else {
      riskLevel = 'High Risk';
    }

    // Similar entities (same relationship types)
    final similarEntityIds = relationships
        .map((r) => r.fromEntityId == entityId ? r.toEntityId : r.fromEntityId)
        .toSet()
        .toList();

    return DecisionEvidence(
      entityId: entityId,
      entityName: entity.name,
      totalEvents: totalEvents,
      decisionCount: decisionEvents,
      avgMoodScore: avgMood,
      avgImportance: stats?.avgImportance ?? 0.0,
      evidenceStrength: evidenceStrength,
      riskLevel: riskLevel,
      trend: trend,
      recentActivity: last30,
      relatedPatternCount: relatedPatterns.length,
      similarEntityIds: similarEntityIds,
      supportingEventIds: events.map((e) => e.id).take(10).toList(),
      moodDistribution: stats != null
          ? Map<String, int>.from(jsonDecode(stats.moodDistribution))
          : {},
    );
  }

  double _moodScore(String mood) {
    const scores = {
      'excited': 1.0, 'happy': 0.8, 'calm': 0.6, 'neutral': 0.5,
      'anxious': 0.35, 'stressed': 0.25, 'sad': 0.2, 'angry': 0.1,
    };
    return scores[mood] ?? 0.5;
  }
}

class DecisionEvidence {
  final String entityId;
  final String entityName;
  final int totalEvents;
  final int decisionCount;
  final double avgMoodScore;
  final double avgImportance;
  final double evidenceStrength;
  final String riskLevel;
  final String trend;
  final int recentActivity;
  final int relatedPatternCount;
  final List<String> similarEntityIds;
  final List<String> supportingEventIds;
  final Map<String, int> moodDistribution;

  const DecisionEvidence({
    required this.entityId,
    required this.entityName,
    required this.totalEvents,
    required this.decisionCount,
    required this.avgMoodScore,
    required this.avgImportance,
    required this.evidenceStrength,
    required this.riskLevel,
    required this.trend,
    required this.recentActivity,
    required this.relatedPatternCount,
    required this.similarEntityIds,
    required this.supportingEventIds,
    required this.moodDistribution,
  });
}
