import 'package:drift/drift.dart';

class Entities extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get customFields => text().withDefault(const Constant('{}'))(); // JSON
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  BoolColumn get isDecision => boolean().withDefault(const Constant(false))();
  // Decision fields (only used when isDecision = true)
  TextColumn get decisionOptions => text().nullable()(); // JSON array
  TextColumn get decisionReasoning => text().nullable()();
  IntColumn get decisionConfidence => integer().nullable()(); // 1-10
  TextColumn get decisionExpectedOutcome => text().nullable()();
  TextColumn get decisionActualOutcome => text().nullable()();
  DateTimeColumn get decisionReviewDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Events extends Table {
  TextColumn get id => text()();
  TextColumn get note => text()();
  TextColumn get linkedEntityIds => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get attachments => text().withDefault(const Constant('[]'))(); // JSON array of paths
  TextColumn get voiceNotePath => text().nullable()();
  TextColumn get mood => text().nullable()(); // happy, neutral, sad, stressed, excited
  IntColumn get importance => integer().withDefault(const Constant(3))(); // 1-5
  TextColumn get location => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get customFields => text().withDefault(const Constant('{}'))();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  BoolColumn get isDecision => boolean().withDefault(const Constant(false))();
  // Decision fields
  TextColumn get decisionOptions => text().nullable()();
  TextColumn get decisionReasoning => text().nullable()();
  IntColumn get decisionConfidence => integer().nullable()();
  TextColumn get decisionExpectedOutcome => text().nullable()();
  TextColumn get decisionActualOutcome => text().nullable()();
  DateTimeColumn get decisionReviewDate => dateTime().nullable()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Relationships extends Table {
  TextColumn get id => text()();
  TextColumn get fromEntityId => text()();
  TextColumn get toEntityId => text()();
  TextColumn get relationshipType => text()(); // e.g. "worked_with", "client_of", "friend"
  TextColumn get description => text().nullable()();
  RealColumn get strength => real().withDefault(const Constant(1.0))(); // 0.0 - 1.0
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Patterns extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get patternType => text()(); // association, sequential, time_series
  TextColumn get relatedEntityIds => text().withDefault(const Constant('[]'))();
  TextColumn get evidence => text().withDefault(const Constant('[]'))(); // JSON array of event IDs
  RealColumn get confidence => real().withDefault(const Constant(0.0))(); // 0.0 - 1.0
  IntColumn get occurrences => integer().withDefault(const Constant(0))();
  DateTimeColumn get firstSeen => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastSeen => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class EntityStatistics extends Table {
  TextColumn get entityId => text()();
  IntColumn get totalEvents => integer().withDefault(const Constant(0))();
  IntColumn get totalDecisions => integer().withDefault(const Constant(0))();
  RealColumn get avgMoodScore => real().withDefault(const Constant(0.0))();
  RealColumn get avgImportance => real().withDefault(const Constant(0.0))();
  TextColumn get moodDistribution => text().withDefault(const Constant('{}'))(); // JSON
  TextColumn get monthlyActivity => text().withDefault(const Constant('{}'))(); // JSON
  DateTimeColumn get lastEventAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {entityId};
}

class Embeddings extends Table {
  TextColumn get id => text()();
  TextColumn get sourceType => text()(); // 'event' or 'entity'
  TextColumn get sourceId => text()();
  TextColumn get embeddingJson => text()(); // JSON float array
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class AnalyticsCache extends Table {
  TextColumn get cacheKey => text()();
  TextColumn get data => text()(); // JSON
  DateTimeColumn get computedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get expiresAt => dateTime()();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
