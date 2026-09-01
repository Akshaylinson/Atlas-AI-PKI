import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import 'pki_pipeline.dart';

/// Creates a small, repeatable dataset for trying the automatic pattern engine.
class DemoDataService {
  static const _demoSettingKey = 'pattern_demo_data_loaded';
  static const _uuid = Uuid();

  Future<DemoDataResult> load(AppDatabase db, PKIPipeline pipeline) async {
    final alreadyLoaded = await db.getSetting(_demoSettingKey) == 'true';
    if (alreadyLoaded) {
      if ((await db.getAllPatterns()).isEmpty) {
        await _ensureDemoPatterns(db);
      }
      return const DemoDataResult(alreadyLoaded: true);
    }

    final entities = {
      'maya': _uuid.v4(),
      'noah': _uuid.v4(),
      'aurora': _uuid.v4(),
      'brightline': _uuid.v4(),
    };

    await db.batch((batch) {
      batch.insertAll(db.entities, [
        EntitiesCompanion(
          id: Value(entities['maya']!),
          name: const Value('Maya Chen'),
          description: const Value('Product lead and frequent collaborator'),
          tags: const Value('["work","product"]'),
          icon: const Value('MC'),
        ),
        EntitiesCompanion(
          id: Value(entities['noah']!),
          name: const Value('Noah Williams'),
          description: const Value('Engineering partner on Project Aurora'),
          tags: const Value('["work","engineering"]'),
          icon: const Value('NW'),
        ),
        EntitiesCompanion(
          id: Value(entities['aurora']!),
          name: const Value('Project Aurora'),
          description: const Value('The shared product launch initiative'),
          tags: const Value('["project","launch"]'),
          icon: const Value('PA'),
        ),
        EntitiesCompanion(
          id: Value(entities['brightline']!),
          name: const Value('Brightline Client'),
          description: const Value('Client connected to the Aurora launch'),
          tags: const Value('["client","business"]'),
          icon: const Value('BC'),
        ),
      ]);
    });

    final now = DateTime.now();
    const events = <EventSeed>[
      EventSeed(
          'Aurora kickoff',
          'Maya met Noah for the Project Aurora kickoff and they worked together on the launch plan.',
          ['maya', 'noah', 'aurora'],
          'excited'),
      EventSeed(
          'Architecture review',
          'Maya and Noah collaborated on the Aurora architecture and agreed on the first milestone.',
          ['maya', 'noah', 'aurora'],
          'happy'),
      EventSeed(
          'Client discovery',
          'Maya met the Brightline Client to discuss the Aurora requirements and project timeline.',
          ['maya', 'brightline', 'aurora'],
          'neutral'),
      EventSeed(
          'Engineering support',
          'Noah helped Maya and supported the Aurora release by reviewing the integration.',
          ['maya', 'noah', 'aurora'],
          'happy'),
      EventSeed(
          'Launch decision',
          'Maya and Noah decided with Brightline Client to approve the Aurora launch date.',
          ['maya', 'noah', 'brightline', 'aurora'],
          'excited',
          true),
      EventSeed(
          'Release check-in',
          'Maya called Noah after the Aurora release and they worked together on the follow-up.',
          ['maya', 'noah', 'aurora'],
          'calm'),
      EventSeed(
          'Client handoff',
          'Noah supported the Brightline Client and Maya during the final Aurora handoff.',
          ['maya', 'noah', 'brightline', 'aurora'],
          'happy'),
      EventSeed(
          'Retrospective',
          'Maya and Noah agreed that the collaboration improved the Aurora project outcome.',
          ['maya', 'noah', 'aurora'],
          'happy'),
    ];

    for (var index = 0; index < events.length; index++) {
      final seed = events[index];
      final eventId = _uuid.v4();
      await db.upsertEvent(EventsCompanion(
        id: Value(eventId),
        title: Value(seed.title),
        note: Value(seed.note),
        linkedEntityIds: Value(jsonEncode(
          seed.entities.map((key) => entities[key]!).toList(),
        )),
        mood: Value(seed.mood),
        importance: Value(seed.isDecision ? 5 : 4),
        isDecision: Value(seed.isDecision),
        tags: const Value('["demo","pattern-test"]'),
        timestamp: Value(now.subtract(Duration(days: events.length - index))),
      ));

      // Process in order so repeated co-occurrences strengthen one pattern.
      await pipeline.process(eventId);
    }

    // Keep the demo deterministic if a platform cannot open the pipeline isolate.
    await _ensureDemoPatterns(db);
    await db.setSetting(_demoSettingKey, 'true');
    return DemoDataResult(
      entityCount: entities.length,
      eventCount: events.length,
    );
  }

  Future<void> _ensureDemoPatterns(AppDatabase db) async {
    final demoEvents = (await db.getAllEvents())
        .where((event) => event.tags.contains('pattern-test'))
        .toList();
    final entities = await db.getAllEntities();
    final names = {for (final entity in entities) entity.id: entity.name};
    final patterns = await db.getAllPatterns();
    final relationships = await db.getAllRelationships();
    final pairEvents = <String, List<Event>>{};

    for (final event in demoEvents) {
      final ids = List<String>.from(jsonDecode(event.linkedEntityIds))..sort();
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          pairEvents.putIfAbsent('${ids[i]}_${ids[j]}', () => []).add(event);
        }
      }
    }

    for (final entry in pairEvents.entries) {
      if (entry.value.length < 2) continue;
      final ids = entry.key.split('_');
      final evidence = entry.value.map((event) => event.id).toList();
      final existing = patterns.where((pattern) {
        final related = List<String>.from(jsonDecode(pattern.relatedEntityIds))
          ..sort();
        return related.join('_') == entry.key;
      }).firstOrNull;
      final title =
          'Co-occurrence: ${names[ids[0]] ?? ids[0]} + ${names[ids[1]] ?? ids[1]}';

      await db.upsertPattern(PatternsCompanion(
        id: Value(existing?.id ?? _uuid.v4()),
        title: Value(title),
        description: const Value(
            'These entities repeatedly appear together in sample events.'),
        patternType: const Value('association'),
        relatedEntityIds: Value(jsonEncode(ids)),
        evidence: Value(jsonEncode(evidence)),
        confidence: Value((evidence.length / 10).clamp(0.0, 1.0).toDouble()),
        occurrences: Value(evidence.length),
        firstSeen: Value(entry.value.first.timestamp),
        lastSeen: Value(entry.value.last.timestamp),
        updatedAt: Value(DateTime.now()),
      ));

      final hasRelationship = relationships.any((relationship) =>
          (relationship.fromEntityId == ids[0] &&
              relationship.toEntityId == ids[1]) ||
          (relationship.fromEntityId == ids[1] &&
              relationship.toEntityId == ids[0]));
      if (!hasRelationship) {
        await db.upsertRelationship(RelationshipsCompanion(
          id: Value(_uuid.v4()),
          fromEntityId: Value(ids[0]),
          toEntityId: Value(ids[1]),
          relationshipType: const Value('works_with'),
          description: const Value('Repeated collaboration in sample events'),
          strength: Value((evidence.length / 5).clamp(0.0, 1.0).toDouble()),
        ));
      }
    }
  }
}

class EventSeed {
  final String title;
  final String note;
  final List<String> entities;
  final String mood;
  final bool isDecision;

  const EventSeed(this.title, this.note, this.entities, this.mood,
      [this.isDecision = false]);
}

class DemoDataResult {
  final int entityCount;
  final int eventCount;
  final bool alreadyLoaded;

  const DemoDataResult({
    this.entityCount = 0,
    this.eventCount = 0,
    this.alreadyLoaded = false,
  });
}
