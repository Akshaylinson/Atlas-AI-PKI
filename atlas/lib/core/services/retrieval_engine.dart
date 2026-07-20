import 'dart:convert';
import 'dart:math';
import '../database/app_database.dart';
import '../models/models.dart';

class RetrievalEngine {
  final AppDatabase _db;

  RetrievalEngine(this._db);

  Future<EvidencePackage> retrieve(String query, {int limit = 20}) async {
    final keywordEvents = await _keywordSearch(query, limit: limit);
    final semanticEvents = await _semanticSearch(query, limit: limit);
    final graphEntities = await _graphSearch(query);
    final patternIds = await _patternSearch(query);

    // Merge and deduplicate event IDs
    final allEventIds = <String>{};
    allEventIds.addAll(keywordEvents.map((e) => e.id));
    allEventIds.addAll(semanticEvents.map((e) => e.id));

    // Collect entity IDs from linked events
    final entityIds = <String>{};
    for (final e in [...keywordEvents, ...semanticEvents]) {
      final ids = List<String>.from(jsonDecode(e.linkedEntityIds));
      entityIds.addAll(ids);
    }
    entityIds.addAll(graphEntities.map((e) => e.id));

    // Build statistics summary
    final stats = await _buildStatistics(entityIds.toList(), allEventIds.toList());

    return EvidencePackage(
      eventIds: allEventIds.take(limit).toList(),
      entityIds: entityIds.take(10).toList(),
      patternIds: patternIds,
      statistics: stats,
      similarEventIds: semanticEvents.map((e) => e.id).take(5).toList(),
      query: query,
    );
  }

  Future<List<Event>> _keywordSearch(String query, {int limit = 20}) async {
    return _db.searchEvents(query);
  }

  Future<List<Event>> _semanticSearch(String query, {int limit = 20}) async {
    final queryVector = _textToVector(query);
    final allEmbeddings = await _db.getAllEmbeddings();
    final allEvents = await _db.getAllEvents();
    final eventMap = {for (final e in allEvents) e.id: e};

    final scored = <MapEntry<String, double>>[];
    for (final emb in allEmbeddings) {
      if (emb.sourceType != 'event') continue;
      final vector = List<double>.from(jsonDecode(emb.embeddingJson));
      final similarity = _cosineSimilarity(queryVector, vector);
      if (similarity > 0.1) {
        scored.add(MapEntry(emb.sourceId, similarity));
      }
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored
        .take(limit)
        .map((e) => eventMap[e.key])
        .whereType<Event>()
        .toList();
  }

  Future<List<Entity>> _graphSearch(String query) async {
    return _db.searchEntities(query);
  }

  Future<List<String>> _patternSearch(String query) async {
    final allPatterns = await _db.getAllPatterns();
    return allPatterns
        .where((p) =>
            p.title.toLowerCase().contains(query.toLowerCase()) ||
            p.description.toLowerCase().contains(query.toLowerCase()))
        .map((p) => p.id)
        .toList();
  }

  Future<Map<String, dynamic>> _buildStatistics(
      List<String> entityIds, List<String> eventIds) async {
    final stats = <String, dynamic>{};
    stats['totalRelevantEvents'] = eventIds.length;
    stats['totalRelevantEntities'] = entityIds.length;

    for (final entityId in entityIds.take(3)) {
      final entityStats = await _db.getStatisticsForEntity(entityId);
      if (entityStats != null) {
        stats['entity_$entityId'] = {
          'totalEvents': entityStats.totalEvents,
          'totalDecisions': entityStats.totalDecisions,
          'avgMoodScore': entityStats.avgMoodScore,
          'avgImportance': entityStats.avgImportance,
        };
      }
    }

    return stats;
  }

  List<double> _textToVector(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+')).where((w) => w.length > 2).toList();
    final vector = List<double>.filled(128, 0.0);
    for (final word in words) {
      final hash = word.hashCode.abs() % 128;
      vector[hash] += 1.0;
    }
    final magnitude = sqrt(vector.map((v) => v * v).reduce((a, b) => a + b));
    if (magnitude > 0) {
      for (int i = 0; i < vector.length; i++) {
        vector[i] /= magnitude;
      }
    }
    return vector;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0.0;
    double dot = 0, magA = 0, magB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    final denom = sqrt(magA) * sqrt(magB);
    return denom == 0 ? 0.0 : dot / denom;
  }
}
