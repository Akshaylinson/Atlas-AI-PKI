import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'tables.dart';
import '../models/models.dart';

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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
            'ALTER TABLE events ADD COLUMN title TEXT;');
      }
      if (from < 3) {
        await customStatement(
            'ALTER TABLE entities ADD COLUMN profile_image_path TEXT;');
      }
      if (from < 4) {
        await customStatement('''
          CREATE TABLE IF NOT EXISTS decision_matrices (
            id TEXT NOT NULL PRIMARY KEY,
            entity_id TEXT NOT NULL,
            question TEXT NOT NULL,
            criteria TEXT NOT NULL DEFAULT '[]',
            options TEXT NOT NULL DEFAULT '[]',
            result TEXT,
            confidence_score REAL,
            created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
          );
        ''');
      }
    },
    beforeOpen: (details) async {
      await _ensureDecisionMatricesTable();
      await _repairLegacyNullRows();
    },
  );

  Future<void> _ensureDecisionMatricesTable() async {
    await customStatement('''
      CREATE TABLE IF NOT EXISTS decision_matrices (
        id TEXT NOT NULL PRIMARY KEY,
        entity_id TEXT NOT NULL,
        question TEXT NOT NULL,
        criteria TEXT NOT NULL DEFAULT '[]',
        options TEXT NOT NULL DEFAULT '[]',
        result TEXT,
        confidence_score REAL,
        created_at INTEGER NOT NULL DEFAULT (strftime('%s','now') * 1000)
      );
    ''');
  }

  Future<void> _repairLegacyNullRows() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await customStatement("""
      UPDATE entities
      SET tags = COALESCE(tags, '[]'),
          custom_fields = COALESCE(custom_fields, '{}'),
          status = COALESCE(status, 'active'),
          is_decision = COALESCE(is_decision, 0),
          created_at = COALESCE(created_at, $nowMs),
          updated_at = COALESCE(updated_at, $nowMs)
      WHERE tags IS NULL
         OR custom_fields IS NULL
         OR status IS NULL
         OR is_decision IS NULL
         OR created_at IS NULL
         OR updated_at IS NULL;
    """);

    await customStatement("""
      UPDATE events
      SET note = COALESCE(note, ''),
          linked_entity_ids = COALESCE(linked_entity_ids, '[]'),
          attachments = COALESCE(attachments, '[]'),
          importance = COALESCE(importance, 3),
          custom_fields = COALESCE(custom_fields, '{}'),
          tags = COALESCE(tags, '[]'),
          is_decision = COALESCE(is_decision, 0),
          timestamp = COALESCE(timestamp, $nowMs),
          created_at = COALESCE(created_at, $nowMs)
      WHERE note IS NULL
         OR linked_entity_ids IS NULL
         OR attachments IS NULL
         OR importance IS NULL
         OR custom_fields IS NULL
         OR tags IS NULL
         OR is_decision IS NULL
         OR timestamp IS NULL
         OR created_at IS NULL;
    """);
  }

  // ── Entities ──────────────────────────────────────────────────────────────

  Future<List<Entity>> getAllEntities() =>
      (select(entities)..orderBy([(e) => OrderingTerm.desc(e.createdAt)])).get();

  Stream<List<Entity>> watchAllEntities() =>
      (select(entities)..orderBy([(e) => OrderingTerm.desc(e.createdAt)])).watch();

  Future<Entity?> getEntityById(String id) =>
      (select(entities)..where((e) => e.id.equals(id))).getSingleOrNull();

  Stream<Entity?> watchEntityById(String id) =>
      (select(entities)..where((e) => e.id.equals(id))).watchSingleOrNull();

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
        ..where((e) => e.note.like('%$query%') | e.tags.like('%$query%') | e.title.like('%$query%')))
      .get();

  Future<List<Event>> getEventsByDateRange(DateTime from, DateTime to) =>
      (select(events)..where((e) => e.timestamp.isBetweenValues(from, to))).get();

  Future<List<Event>> getDecisionEvents() =>
      (select(events)..where((e) => e.isDecision.equals(true))).get();

  Future<void> upsertEvent(EventsCompanion event) =>
      into(events).insertOnConflictUpdate(event);

  Future<void> deleteEvent(String id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();

  Future<List<DecisionMatrix>> getMatricesForEntity(String entityId) async {
    final rows = await customSelect(
      '''
      SELECT id, entity_id, question, criteria, options, result, confidence_score, created_at
      FROM decision_matrices
      WHERE entity_id = ?
      ORDER BY created_at DESC
      ''',
      variables: [Variable.withString(entityId)],
    ).get();
    return rows.map(_matrixFromRow).toList();
  }

  Stream<List<DecisionMatrix>> watchMatricesForEntity(String entityId) {
    return customSelect(
      '''
      SELECT id, entity_id, question, criteria, options, result, confidence_score, created_at
      FROM decision_matrices
      WHERE entity_id = ?
      ORDER BY created_at DESC
      ''',
      variables: [Variable.withString(entityId)],
    ).watch().map((rows) => rows.map(_matrixFromRow).toList());
  }

  Stream<List<DecisionMatrix>> watchAllMatrices() {
    return customSelect(
      '''
      SELECT id, entity_id, question, criteria, options, result, confidence_score, created_at
      FROM decision_matrices
      ORDER BY created_at DESC
      ''',
    ).watch().map((rows) => rows.map(_matrixFromRow).toList());
  }

  Future<List<DecisionMatrix>> getAllMatrices() async {
    final rows = await customSelect(
      '''
      SELECT id, entity_id, question, criteria, options, result, confidence_score, created_at
      FROM decision_matrices
      ORDER BY created_at DESC
      ''',
    ).get();
    return rows.map(_matrixFromRow).toList();
  }

  Future<void> upsertMatrix(DecisionMatrix matrix) => customStatement('''
    INSERT INTO decision_matrices (
      id, entity_id, question, criteria, options, result, confidence_score, created_at
    ) VALUES (
      '${_escapeSql(matrix.id)}',
      '${_escapeSql(matrix.entityId)}',
      '${_escapeSql(matrix.question)}',
      '${_escapeSql(matrix.criteria)}',
      '${_escapeSql(matrix.options)}',
      ${matrix.result == null ? 'NULL' : "'${_escapeSql(matrix.result!)}'"},
      ${matrix.confidenceScore == null ? 'NULL' : matrix.confidenceScore},
      ${matrix.createdAt.millisecondsSinceEpoch}
    )
    ON CONFLICT(id) DO UPDATE SET
      entity_id = excluded.entity_id,
      question = excluded.question,
      criteria = excluded.criteria,
      options = excluded.options,
      result = excluded.result,
      confidence_score = excluded.confidence_score,
      created_at = excluded.created_at;
  ''');

  Future<void> deleteMatrix(String id) =>
      customStatement("DELETE FROM decision_matrices WHERE id = '${_escapeSql(id)}'");

  DecisionMatrix _matrixFromRow(QueryRow row) {
    return DecisionMatrix(
      id: row.read<String>('id'),
      entityId: row.read<String>('entity_id'),
      question: row.read<String>('question'),
      criteria: row.read<String>('criteria'),
      options: row.read<String>('options'),
      result: row.read<String?>('result'),
      confidenceScore: row.read<double?>('confidence_score'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('created_at')),
    );
  }

  String _escapeSql(String value) => value.replaceAll("'", "''");

  // -- Relationships ---------------------------------------------------------
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
    // Use active Atlas package dir if set, otherwise fall back to documents dir
    final prefs = await SharedPreferences.getInstance();
    final packageDir = prefs.getString('atlas_package_dir');
    final String dbPath;
    if (packageDir != null && Directory(packageDir).existsSync()) {
      dbPath = p.join(packageDir, 'atlas.db');
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      dbPath = p.join(docsDir.path, 'atlas.db');
    }
    return NativeDatabase.createInBackground(File(dbPath));
  });
}

