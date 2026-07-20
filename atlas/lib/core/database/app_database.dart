import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Entities,
  Events,
  Relationships,
  Patterns,
  EntityStatistics,
  Embeddings,
  AnalyticsCache,
  AppSettings,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ── Entities ──────────────────────────────────────────────────────────────

  Future<List<Entity>> getAllEntities() =>
      (select(entities)..orderBy([(e) => OrderingTerm.desc(e.createdAt)])).get();

  Stream<List<Entity>> watchAllEntities() =>
      (select(entities)..orderBy([(e) => OrderingTerm.desc(e.createdAt)])).watch();

  Future<Entity?> getEntityById(String id) =>
      (select(entities)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<List<Entity>> searchEntities(String query) => (select(entities)
        ..where((e) =>
            e.name.like('%$query%') | e.description.like('%$query%') | e.tags.like('%$query%')))
      .get();

  Future<void> upsertEntity(EntitiesCompanion entity) =>
      into(entities).insertOnConflictUpdate(entity);

  Future<void> deleteEntity(String id) =>
      (delete(entities)..where((e) => e.id.equals(id))).go();

  Future<List<Entity>> getDecisionEntities() =>
      (select(entities)..where((e) => e.isDecision.equals(true))).get();

  // ── Events ────────────────────────────────────────────────────────────────

  Future<List<Event>> getAllEvents() =>
      (select(events)..orderBy([(e) => OrderingTerm.desc(e.timestamp)])).get();

  Stream<List<Event>> watchAllEvents() =>
      (select(events)..orderBy([(e) => OrderingTerm.desc(e.timestamp)])).watch();

  Future<List<Event>> getEventsForEntity(String entityId) => (select(events)
        ..where((e) => e.linkedEntityIds.like('%$entityId%'))
        ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
      .get();

  Stream<List<Event>> watchEventsForEntity(String entityId) => (select(events)
        ..where((e) => e.linkedEntityIds.like('%$entityId%'))
        ..orderBy([(e) => OrderingTerm.desc(e.timestamp)]))
      .watch();

  Future<List<Event>> searchEvents(String query) => (select(events)
        ..where((e) => e.note.like('%$query%') | e.tags.like('%$query%')))
      .get();

  Future<List<Event>> getEventsByDateRange(DateTime from, DateTime to) =>
      (select(events)..where((e) => e.timestamp.isBetweenValues(from, to))).get();

  Future<List<Event>> getDecisionEvents() =>
      (select(events)..where((e) => e.isDecision.equals(true))).get();

  Future<void> upsertEvent(EventsCompanion event) =>
      into(events).insertOnConflictUpdate(event);

  Future<void> deleteEvent(String id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();

  // ── Relationships ─────────────────────────────────────────────────────────

  Future<List<Relationship>> getRelationshipsForEntity(String entityId) =>
      (select(relationships)
            ..where((r) =>
                r.fromEntityId.equals(entityId) | r.toEntityId.equals(entityId)))
          .get();

  Stream<List<Relationship>> watchAllRelationships() => select(relationships).watch();

  Future<void> upsertRelationship(RelationshipsCompanion rel) =>
      into(relationships).insertOnConflictUpdate(rel);

  Future<void> deleteRelationship(String id) =>
      (delete(relationships)..where((r) => r.id.equals(id))).go();

  Future<List<Relationship>> getAllRelationships() => select(relationships).get();

  // ── Patterns ──────────────────────────────────────────────────────────────

  Future<List<Pattern>> getAllPatterns() =>
      (select(patterns)..orderBy([(p) => OrderingTerm.desc(p.confidence)])).get();

  Stream<List<Pattern>> watchAllPatterns() =>
      (select(patterns)..orderBy([(p) => OrderingTerm.desc(p.confidence)])).watch();

  Future<void> upsertPattern(PatternsCompanion pattern) =>
      into(patterns).insertOnConflictUpdate(pattern);

  // ── Statistics ────────────────────────────────────────────────────────────

  Future<EntityStatistic?> getStatisticsForEntity(String entityId) =>
      (select(entityStatistics)..where((s) => s.entityId.equals(entityId)))
          .getSingleOrNull();

  Future<void> upsertStatistics(EntityStatisticsCompanion stats) =>
      into(entityStatistics).insertOnConflictUpdate(stats);

  // ── Embeddings ────────────────────────────────────────────────────────────

  Future<List<Embedding>> getAllEmbeddings() => select(embeddings).get();

  Future<Embedding?> getEmbeddingForSource(String sourceId) =>
      (select(embeddings)..where((e) => e.sourceId.equals(sourceId))).getSingleOrNull();

  Future<void> upsertEmbedding(EmbeddingsCompanion emb) =>
      into(embeddings).insertOnConflictUpdate(emb);

  // ── Analytics Cache ───────────────────────────────────────────────────────

  Future<AnalyticsCacheData?> getCacheEntry(String key) =>
      (select(analyticsCache)..where((c) => c.cacheKey.equals(key))).getSingleOrNull();

  Future<void> setCacheEntry(AnalyticsCacheCompanion entry) =>
      into(analyticsCache).insertOnConflictUpdate(entry);

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<String?> getSetting(String key) async {
    final row = await (select(appSettings)..where((s) => s.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
      ));

  // ── Aggregate Queries ─────────────────────────────────────────────────────

  Future<int> getTotalEventCount() async {
    final count = countAll();
    final query = selectOnly(events)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<int> getTotalEntityCount() async {
    final count = countAll();
    final query = selectOnly(entities)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<Map<String, int>> getMoodDistribution() async {
    final allEvents = await getAllEvents();
    final dist = <String, int>{};
    for (final e in allEvents) {
      if (e.mood != null) dist[e.mood!] = (dist[e.mood!] ?? 0) + 1;
    }
    return dist;
  }

  Future<List<Event>> getRecentEvents({int limit = 20}) =>
      (select(events)
            ..orderBy([(e) => OrderingTerm.desc(e.timestamp)])
            ..limit(limit))
          .get();

  Future<Event?> getEventById(String id) =>
      (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'atlas.db'));
    return NativeDatabase.createInBackground(file);
  });
}
