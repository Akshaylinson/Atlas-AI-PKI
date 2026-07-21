// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EntitiesTable extends Entities with TableInfo<$EntitiesTable, Entity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _customFieldsMeta =
      const VerificationMeta('customFields');
  @override
  late final GeneratedColumn<String> customFields = GeneratedColumn<String>(
      'custom_fields', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
      'color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
      'icon', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('active'));
  static const VerificationMeta _isDecisionMeta =
      const VerificationMeta('isDecision');
  @override
  late final GeneratedColumn<bool> isDecision = GeneratedColumn<bool>(
      'is_decision', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_decision" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _decisionOptionsMeta =
      const VerificationMeta('decisionOptions');
  @override
  late final GeneratedColumn<String> decisionOptions = GeneratedColumn<String>(
      'decision_options', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionReasoningMeta =
      const VerificationMeta('decisionReasoning');
  @override
  late final GeneratedColumn<String> decisionReasoning =
      GeneratedColumn<String>('decision_reasoning', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionConfidenceMeta =
      const VerificationMeta('decisionConfidence');
  @override
  late final GeneratedColumn<int> decisionConfidence = GeneratedColumn<int>(
      'decision_confidence', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _decisionExpectedOutcomeMeta =
      const VerificationMeta('decisionExpectedOutcome');
  @override
  late final GeneratedColumn<String> decisionExpectedOutcome =
      GeneratedColumn<String>('decision_expected_outcome', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionActualOutcomeMeta =
      const VerificationMeta('decisionActualOutcome');
  @override
  late final GeneratedColumn<String> decisionActualOutcome =
      GeneratedColumn<String>('decision_actual_outcome', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionReviewDateMeta =
      const VerificationMeta('decisionReviewDate');
  @override
  late final GeneratedColumn<DateTime> decisionReviewDate =
      GeneratedColumn<DateTime>('decision_review_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        description,
        tags,
        customFields,
        color,
        icon,
        status,
        isDecision,
        decisionOptions,
        decisionReasoning,
        decisionConfidence,
        decisionExpectedOutcome,
        decisionActualOutcome,
        decisionReviewDate,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entities';
  @override
  VerificationContext validateIntegrity(Insertable<Entity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('custom_fields')) {
      context.handle(
          _customFieldsMeta,
          customFields.isAcceptableOrUnknown(
              data['custom_fields']!, _customFieldsMeta));
    }
    if (data.containsKey('color')) {
      context.handle(
          _colorMeta, color.isAcceptableOrUnknown(data['color']!, _colorMeta));
    }
    if (data.containsKey('icon')) {
      context.handle(
          _iconMeta, icon.isAcceptableOrUnknown(data['icon']!, _iconMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('is_decision')) {
      context.handle(
          _isDecisionMeta,
          isDecision.isAcceptableOrUnknown(
              data['is_decision']!, _isDecisionMeta));
    }
    if (data.containsKey('decision_options')) {
      context.handle(
          _decisionOptionsMeta,
          decisionOptions.isAcceptableOrUnknown(
              data['decision_options']!, _decisionOptionsMeta));
    }
    if (data.containsKey('decision_reasoning')) {
      context.handle(
          _decisionReasoningMeta,
          decisionReasoning.isAcceptableOrUnknown(
              data['decision_reasoning']!, _decisionReasoningMeta));
    }
    if (data.containsKey('decision_confidence')) {
      context.handle(
          _decisionConfidenceMeta,
          decisionConfidence.isAcceptableOrUnknown(
              data['decision_confidence']!, _decisionConfidenceMeta));
    }
    if (data.containsKey('decision_expected_outcome')) {
      context.handle(
          _decisionExpectedOutcomeMeta,
          decisionExpectedOutcome.isAcceptableOrUnknown(
              data['decision_expected_outcome']!,
              _decisionExpectedOutcomeMeta));
    }
    if (data.containsKey('decision_actual_outcome')) {
      context.handle(
          _decisionActualOutcomeMeta,
          decisionActualOutcome.isAcceptableOrUnknown(
              data['decision_actual_outcome']!, _decisionActualOutcomeMeta));
    }
    if (data.containsKey('decision_review_date')) {
      context.handle(
          _decisionReviewDateMeta,
          decisionReviewDate.isAcceptableOrUnknown(
              data['decision_review_date']!, _decisionReviewDateMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Entity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Entity(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      customFields: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_fields'])!,
      color: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}color']),
      icon: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      isDecision: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_decision'])!,
      decisionOptions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}decision_options']),
      decisionReasoning: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}decision_reasoning']),
      decisionConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}decision_confidence']),
      decisionExpectedOutcome: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}decision_expected_outcome']),
      decisionActualOutcome: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}decision_actual_outcome']),
      decisionReviewDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}decision_review_date']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EntitiesTable createAlias(String alias) {
    return $EntitiesTable(attachedDatabase, alias);
  }
}

class Entity extends DataClass implements Insertable<Entity> {
  final String id;
  final String name;
  final String? description;
  final String tags;
  final String customFields;
  final String? color;
  final String? icon;
  final String status;
  final bool isDecision;
  final String? decisionOptions;
  final String? decisionReasoning;
  final int? decisionConfidence;
  final String? decisionExpectedOutcome;
  final String? decisionActualOutcome;
  final DateTime? decisionReviewDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Entity(
      {required this.id,
      required this.name,
      this.description,
      required this.tags,
      required this.customFields,
      this.color,
      this.icon,
      required this.status,
      required this.isDecision,
      this.decisionOptions,
      this.decisionReasoning,
      this.decisionConfidence,
      this.decisionExpectedOutcome,
      this.decisionActualOutcome,
      this.decisionReviewDate,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['tags'] = Variable<String>(tags);
    map['custom_fields'] = Variable<String>(customFields);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['status'] = Variable<String>(status);
    map['is_decision'] = Variable<bool>(isDecision);
    if (!nullToAbsent || decisionOptions != null) {
      map['decision_options'] = Variable<String>(decisionOptions);
    }
    if (!nullToAbsent || decisionReasoning != null) {
      map['decision_reasoning'] = Variable<String>(decisionReasoning);
    }
    if (!nullToAbsent || decisionConfidence != null) {
      map['decision_confidence'] = Variable<int>(decisionConfidence);
    }
    if (!nullToAbsent || decisionExpectedOutcome != null) {
      map['decision_expected_outcome'] =
          Variable<String>(decisionExpectedOutcome);
    }
    if (!nullToAbsent || decisionActualOutcome != null) {
      map['decision_actual_outcome'] = Variable<String>(decisionActualOutcome);
    }
    if (!nullToAbsent || decisionReviewDate != null) {
      map['decision_review_date'] = Variable<DateTime>(decisionReviewDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntitiesCompanion toCompanion(bool nullToAbsent) {
    return EntitiesCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      tags: Value(tags),
      customFields: Value(customFields),
      color:
          color == null && nullToAbsent ? const Value.absent() : Value(color),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      status: Value(status),
      isDecision: Value(isDecision),
      decisionOptions: decisionOptions == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionOptions),
      decisionReasoning: decisionReasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionReasoning),
      decisionConfidence: decisionConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionConfidence),
      decisionExpectedOutcome: decisionExpectedOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionExpectedOutcome),
      decisionActualOutcome: decisionActualOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionActualOutcome),
      decisionReviewDate: decisionReviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionReviewDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Entity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Entity(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      tags: serializer.fromJson<String>(json['tags']),
      customFields: serializer.fromJson<String>(json['customFields']),
      color: serializer.fromJson<String?>(json['color']),
      icon: serializer.fromJson<String?>(json['icon']),
      status: serializer.fromJson<String>(json['status']),
      isDecision: serializer.fromJson<bool>(json['isDecision']),
      decisionOptions: serializer.fromJson<String?>(json['decisionOptions']),
      decisionReasoning:
          serializer.fromJson<String?>(json['decisionReasoning']),
      decisionConfidence: serializer.fromJson<int?>(json['decisionConfidence']),
      decisionExpectedOutcome:
          serializer.fromJson<String?>(json['decisionExpectedOutcome']),
      decisionActualOutcome:
          serializer.fromJson<String?>(json['decisionActualOutcome']),
      decisionReviewDate:
          serializer.fromJson<DateTime?>(json['decisionReviewDate']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'tags': serializer.toJson<String>(tags),
      'customFields': serializer.toJson<String>(customFields),
      'color': serializer.toJson<String?>(color),
      'icon': serializer.toJson<String?>(icon),
      'status': serializer.toJson<String>(status),
      'isDecision': serializer.toJson<bool>(isDecision),
      'decisionOptions': serializer.toJson<String?>(decisionOptions),
      'decisionReasoning': serializer.toJson<String?>(decisionReasoning),
      'decisionConfidence': serializer.toJson<int?>(decisionConfidence),
      'decisionExpectedOutcome':
          serializer.toJson<String?>(decisionExpectedOutcome),
      'decisionActualOutcome':
          serializer.toJson<String?>(decisionActualOutcome),
      'decisionReviewDate': serializer.toJson<DateTime?>(decisionReviewDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Entity copyWith(
          {String? id,
          String? name,
          Value<String?> description = const Value.absent(),
          String? tags,
          String? customFields,
          Value<String?> color = const Value.absent(),
          Value<String?> icon = const Value.absent(),
          String? status,
          bool? isDecision,
          Value<String?> decisionOptions = const Value.absent(),
          Value<String?> decisionReasoning = const Value.absent(),
          Value<int?> decisionConfidence = const Value.absent(),
          Value<String?> decisionExpectedOutcome = const Value.absent(),
          Value<String?> decisionActualOutcome = const Value.absent(),
          Value<DateTime?> decisionReviewDate = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Entity(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description.present ? description.value : this.description,
        tags: tags ?? this.tags,
        customFields: customFields ?? this.customFields,
        color: color.present ? color.value : this.color,
        icon: icon.present ? icon.value : this.icon,
        status: status ?? this.status,
        isDecision: isDecision ?? this.isDecision,
        decisionOptions: decisionOptions.present
            ? decisionOptions.value
            : this.decisionOptions,
        decisionReasoning: decisionReasoning.present
            ? decisionReasoning.value
            : this.decisionReasoning,
        decisionConfidence: decisionConfidence.present
            ? decisionConfidence.value
            : this.decisionConfidence,
        decisionExpectedOutcome: decisionExpectedOutcome.present
            ? decisionExpectedOutcome.value
            : this.decisionExpectedOutcome,
        decisionActualOutcome: decisionActualOutcome.present
            ? decisionActualOutcome.value
            : this.decisionActualOutcome,
        decisionReviewDate: decisionReviewDate.present
            ? decisionReviewDate.value
            : this.decisionReviewDate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Entity copyWithCompanion(EntitiesCompanion data) {
    return Entity(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description:
          data.description.present ? data.description.value : this.description,
      tags: data.tags.present ? data.tags.value : this.tags,
      customFields: data.customFields.present
          ? data.customFields.value
          : this.customFields,
      color: data.color.present ? data.color.value : this.color,
      icon: data.icon.present ? data.icon.value : this.icon,
      status: data.status.present ? data.status.value : this.status,
      isDecision:
          data.isDecision.present ? data.isDecision.value : this.isDecision,
      decisionOptions: data.decisionOptions.present
          ? data.decisionOptions.value
          : this.decisionOptions,
      decisionReasoning: data.decisionReasoning.present
          ? data.decisionReasoning.value
          : this.decisionReasoning,
      decisionConfidence: data.decisionConfidence.present
          ? data.decisionConfidence.value
          : this.decisionConfidence,
      decisionExpectedOutcome: data.decisionExpectedOutcome.present
          ? data.decisionExpectedOutcome.value
          : this.decisionExpectedOutcome,
      decisionActualOutcome: data.decisionActualOutcome.present
          ? data.decisionActualOutcome.value
          : this.decisionActualOutcome,
      decisionReviewDate: data.decisionReviewDate.present
          ? data.decisionReviewDate.value
          : this.decisionReviewDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Entity(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('tags: $tags, ')
          ..write('customFields: $customFields, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('status: $status, ')
          ..write('isDecision: $isDecision, ')
          ..write('decisionOptions: $decisionOptions, ')
          ..write('decisionReasoning: $decisionReasoning, ')
          ..write('decisionConfidence: $decisionConfidence, ')
          ..write('decisionExpectedOutcome: $decisionExpectedOutcome, ')
          ..write('decisionActualOutcome: $decisionActualOutcome, ')
          ..write('decisionReviewDate: $decisionReviewDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      description,
      tags,
      customFields,
      color,
      icon,
      status,
      isDecision,
      decisionOptions,
      decisionReasoning,
      decisionConfidence,
      decisionExpectedOutcome,
      decisionActualOutcome,
      decisionReviewDate,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Entity &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.tags == this.tags &&
          other.customFields == this.customFields &&
          other.color == this.color &&
          other.icon == this.icon &&
          other.status == this.status &&
          other.isDecision == this.isDecision &&
          other.decisionOptions == this.decisionOptions &&
          other.decisionReasoning == this.decisionReasoning &&
          other.decisionConfidence == this.decisionConfidence &&
          other.decisionExpectedOutcome == this.decisionExpectedOutcome &&
          other.decisionActualOutcome == this.decisionActualOutcome &&
          other.decisionReviewDate == this.decisionReviewDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EntitiesCompanion extends UpdateCompanion<Entity> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> tags;
  final Value<String> customFields;
  final Value<String?> color;
  final Value<String?> icon;
  final Value<String> status;
  final Value<bool> isDecision;
  final Value<String?> decisionOptions;
  final Value<String?> decisionReasoning;
  final Value<int?> decisionConfidence;
  final Value<String?> decisionExpectedOutcome;
  final Value<String?> decisionActualOutcome;
  final Value<DateTime?> decisionReviewDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EntitiesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.tags = const Value.absent(),
    this.customFields = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.status = const Value.absent(),
    this.isDecision = const Value.absent(),
    this.decisionOptions = const Value.absent(),
    this.decisionReasoning = const Value.absent(),
    this.decisionConfidence = const Value.absent(),
    this.decisionExpectedOutcome = const Value.absent(),
    this.decisionActualOutcome = const Value.absent(),
    this.decisionReviewDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitiesCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.tags = const Value.absent(),
    this.customFields = const Value.absent(),
    this.color = const Value.absent(),
    this.icon = const Value.absent(),
    this.status = const Value.absent(),
    this.isDecision = const Value.absent(),
    this.decisionOptions = const Value.absent(),
    this.decisionReasoning = const Value.absent(),
    this.decisionConfidence = const Value.absent(),
    this.decisionExpectedOutcome = const Value.absent(),
    this.decisionActualOutcome = const Value.absent(),
    this.decisionReviewDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name);
  static Insertable<Entity> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? tags,
    Expression<String>? customFields,
    Expression<String>? color,
    Expression<String>? icon,
    Expression<String>? status,
    Expression<bool>? isDecision,
    Expression<String>? decisionOptions,
    Expression<String>? decisionReasoning,
    Expression<int>? decisionConfidence,
    Expression<String>? decisionExpectedOutcome,
    Expression<String>? decisionActualOutcome,
    Expression<DateTime>? decisionReviewDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (tags != null) 'tags': tags,
      if (customFields != null) 'custom_fields': customFields,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (status != null) 'status': status,
      if (isDecision != null) 'is_decision': isDecision,
      if (decisionOptions != null) 'decision_options': decisionOptions,
      if (decisionReasoning != null) 'decision_reasoning': decisionReasoning,
      if (decisionConfidence != null) 'decision_confidence': decisionConfidence,
      if (decisionExpectedOutcome != null)
        'decision_expected_outcome': decisionExpectedOutcome,
      if (decisionActualOutcome != null)
        'decision_actual_outcome': decisionActualOutcome,
      if (decisionReviewDate != null)
        'decision_review_date': decisionReviewDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitiesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? description,
      Value<String>? tags,
      Value<String>? customFields,
      Value<String?>? color,
      Value<String?>? icon,
      Value<String>? status,
      Value<bool>? isDecision,
      Value<String?>? decisionOptions,
      Value<String?>? decisionReasoning,
      Value<int?>? decisionConfidence,
      Value<String?>? decisionExpectedOutcome,
      Value<String?>? decisionActualOutcome,
      Value<DateTime?>? decisionReviewDate,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return EntitiesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      customFields: customFields ?? this.customFields,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      isDecision: isDecision ?? this.isDecision,
      decisionOptions: decisionOptions ?? this.decisionOptions,
      decisionReasoning: decisionReasoning ?? this.decisionReasoning,
      decisionConfidence: decisionConfidence ?? this.decisionConfidence,
      decisionExpectedOutcome:
          decisionExpectedOutcome ?? this.decisionExpectedOutcome,
      decisionActualOutcome:
          decisionActualOutcome ?? this.decisionActualOutcome,
      decisionReviewDate: decisionReviewDate ?? this.decisionReviewDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (customFields.present) {
      map['custom_fields'] = Variable<String>(customFields.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (isDecision.present) {
      map['is_decision'] = Variable<bool>(isDecision.value);
    }
    if (decisionOptions.present) {
      map['decision_options'] = Variable<String>(decisionOptions.value);
    }
    if (decisionReasoning.present) {
      map['decision_reasoning'] = Variable<String>(decisionReasoning.value);
    }
    if (decisionConfidence.present) {
      map['decision_confidence'] = Variable<int>(decisionConfidence.value);
    }
    if (decisionExpectedOutcome.present) {
      map['decision_expected_outcome'] =
          Variable<String>(decisionExpectedOutcome.value);
    }
    if (decisionActualOutcome.present) {
      map['decision_actual_outcome'] =
          Variable<String>(decisionActualOutcome.value);
    }
    if (decisionReviewDate.present) {
      map['decision_review_date'] =
          Variable<DateTime>(decisionReviewDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitiesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('tags: $tags, ')
          ..write('customFields: $customFields, ')
          ..write('color: $color, ')
          ..write('icon: $icon, ')
          ..write('status: $status, ')
          ..write('isDecision: $isDecision, ')
          ..write('decisionOptions: $decisionOptions, ')
          ..write('decisionReasoning: $decisionReasoning, ')
          ..write('decisionConfidence: $decisionConfidence, ')
          ..write('decisionExpectedOutcome: $decisionExpectedOutcome, ')
          ..write('decisionActualOutcome: $decisionActualOutcome, ')
          ..write('decisionReviewDate: $decisionReviewDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, Event> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _linkedEntityIdsMeta =
      const VerificationMeta('linkedEntityIds');
  @override
  late final GeneratedColumn<String> linkedEntityIds = GeneratedColumn<String>(
      'linked_entity_ids', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _attachmentsMeta =
      const VerificationMeta('attachments');
  @override
  late final GeneratedColumn<String> attachments = GeneratedColumn<String>(
      'attachments', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _voiceNotePathMeta =
      const VerificationMeta('voiceNotePath');
  @override
  late final GeneratedColumn<String> voiceNotePath = GeneratedColumn<String>(
      'voice_note_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
      'mood', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _importanceMeta =
      const VerificationMeta('importance');
  @override
  late final GeneratedColumn<int> importance = GeneratedColumn<int>(
      'importance', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(3));
  static const VerificationMeta _locationMeta =
      const VerificationMeta('location');
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
      'location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _durationMinutesMeta =
      const VerificationMeta('durationMinutes');
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
      'duration_minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _customFieldsMeta =
      const VerificationMeta('customFields');
  @override
  late final GeneratedColumn<String> customFields = GeneratedColumn<String>(
      'custom_fields', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
      'tags', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isDecisionMeta =
      const VerificationMeta('isDecision');
  @override
  late final GeneratedColumn<bool> isDecision = GeneratedColumn<bool>(
      'is_decision', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_decision" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _decisionOptionsMeta =
      const VerificationMeta('decisionOptions');
  @override
  late final GeneratedColumn<String> decisionOptions = GeneratedColumn<String>(
      'decision_options', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionReasoningMeta =
      const VerificationMeta('decisionReasoning');
  @override
  late final GeneratedColumn<String> decisionReasoning =
      GeneratedColumn<String>('decision_reasoning', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionConfidenceMeta =
      const VerificationMeta('decisionConfidence');
  @override
  late final GeneratedColumn<int> decisionConfidence = GeneratedColumn<int>(
      'decision_confidence', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _decisionExpectedOutcomeMeta =
      const VerificationMeta('decisionExpectedOutcome');
  @override
  late final GeneratedColumn<String> decisionExpectedOutcome =
      GeneratedColumn<String>('decision_expected_outcome', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionActualOutcomeMeta =
      const VerificationMeta('decisionActualOutcome');
  @override
  late final GeneratedColumn<String> decisionActualOutcome =
      GeneratedColumn<String>('decision_actual_outcome', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _decisionReviewDateMeta =
      const VerificationMeta('decisionReviewDate');
  @override
  late final GeneratedColumn<DateTime> decisionReviewDate =
      GeneratedColumn<DateTime>('decision_review_date', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        note,
        linkedEntityIds,
        attachments,
        voiceNotePath,
        mood,
        importance,
        location,
        latitude,
        longitude,
        durationMinutes,
        customFields,
        tags,
        isDecision,
        decisionOptions,
        decisionReasoning,
        decisionConfidence,
        decisionExpectedOutcome,
        decisionActualOutcome,
        decisionReviewDate,
        timestamp,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(Insertable<Event> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('linked_entity_ids')) {
      context.handle(
          _linkedEntityIdsMeta,
          linkedEntityIds.isAcceptableOrUnknown(
              data['linked_entity_ids']!, _linkedEntityIdsMeta));
    }
    if (data.containsKey('attachments')) {
      context.handle(
          _attachmentsMeta,
          attachments.isAcceptableOrUnknown(
              data['attachments']!, _attachmentsMeta));
    }
    if (data.containsKey('voice_note_path')) {
      context.handle(
          _voiceNotePathMeta,
          voiceNotePath.isAcceptableOrUnknown(
              data['voice_note_path']!, _voiceNotePathMeta));
    }
    if (data.containsKey('mood')) {
      context.handle(
          _moodMeta, mood.isAcceptableOrUnknown(data['mood']!, _moodMeta));
    }
    if (data.containsKey('importance')) {
      context.handle(
          _importanceMeta,
          importance.isAcceptableOrUnknown(
              data['importance']!, _importanceMeta));
    }
    if (data.containsKey('location')) {
      context.handle(_locationMeta,
          location.isAcceptableOrUnknown(data['location']!, _locationMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
          _durationMinutesMeta,
          durationMinutes.isAcceptableOrUnknown(
              data['duration_minutes']!, _durationMinutesMeta));
    }
    if (data.containsKey('custom_fields')) {
      context.handle(
          _customFieldsMeta,
          customFields.isAcceptableOrUnknown(
              data['custom_fields']!, _customFieldsMeta));
    }
    if (data.containsKey('tags')) {
      context.handle(
          _tagsMeta, tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta));
    }
    if (data.containsKey('is_decision')) {
      context.handle(
          _isDecisionMeta,
          isDecision.isAcceptableOrUnknown(
              data['is_decision']!, _isDecisionMeta));
    }
    if (data.containsKey('decision_options')) {
      context.handle(
          _decisionOptionsMeta,
          decisionOptions.isAcceptableOrUnknown(
              data['decision_options']!, _decisionOptionsMeta));
    }
    if (data.containsKey('decision_reasoning')) {
      context.handle(
          _decisionReasoningMeta,
          decisionReasoning.isAcceptableOrUnknown(
              data['decision_reasoning']!, _decisionReasoningMeta));
    }
    if (data.containsKey('decision_confidence')) {
      context.handle(
          _decisionConfidenceMeta,
          decisionConfidence.isAcceptableOrUnknown(
              data['decision_confidence']!, _decisionConfidenceMeta));
    }
    if (data.containsKey('decision_expected_outcome')) {
      context.handle(
          _decisionExpectedOutcomeMeta,
          decisionExpectedOutcome.isAcceptableOrUnknown(
              data['decision_expected_outcome']!,
              _decisionExpectedOutcomeMeta));
    }
    if (data.containsKey('decision_actual_outcome')) {
      context.handle(
          _decisionActualOutcomeMeta,
          decisionActualOutcome.isAcceptableOrUnknown(
              data['decision_actual_outcome']!, _decisionActualOutcomeMeta));
    }
    if (data.containsKey('decision_review_date')) {
      context.handle(
          _decisionReviewDateMeta,
          decisionReviewDate.isAcceptableOrUnknown(
              data['decision_review_date']!, _decisionReviewDateMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Event map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Event(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title']),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      linkedEntityIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}linked_entity_ids'])!,
      attachments: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}attachments'])!,
      voiceNotePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}voice_note_path']),
      mood: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mood']),
      importance: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}importance'])!,
      location: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}location']),
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude']),
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude']),
      durationMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_minutes']),
      customFields: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}custom_fields'])!,
      tags: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!,
      isDecision: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_decision'])!,
      decisionOptions: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}decision_options']),
      decisionReasoning: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}decision_reasoning']),
      decisionConfidence: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}decision_confidence']),
      decisionExpectedOutcome: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}decision_expected_outcome']),
      decisionActualOutcome: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}decision_actual_outcome']),
      decisionReviewDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime,
          data['${effectivePrefix}decision_review_date']),
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class Event extends DataClass implements Insertable<Event> {
  final String id;
  final String? title;
  final String note;
  final String linkedEntityIds;
  final String attachments;
  final String? voiceNotePath;
  final String? mood;
  final int importance;
  final String? location;
  final double? latitude;
  final double? longitude;
  final int? durationMinutes;
  final String customFields;
  final String tags;
  final bool isDecision;
  final String? decisionOptions;
  final String? decisionReasoning;
  final int? decisionConfidence;
  final String? decisionExpectedOutcome;
  final String? decisionActualOutcome;
  final DateTime? decisionReviewDate;
  final DateTime timestamp;
  final DateTime createdAt;
  const Event(
      {required this.id,
      this.title,
      required this.note,
      required this.linkedEntityIds,
      required this.attachments,
      this.voiceNotePath,
      this.mood,
      required this.importance,
      this.location,
      this.latitude,
      this.longitude,
      this.durationMinutes,
      required this.customFields,
      required this.tags,
      required this.isDecision,
      this.decisionOptions,
      this.decisionReasoning,
      this.decisionConfidence,
      this.decisionExpectedOutcome,
      this.decisionActualOutcome,
      this.decisionReviewDate,
      required this.timestamp,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['note'] = Variable<String>(note);
    map['linked_entity_ids'] = Variable<String>(linkedEntityIds);
    map['attachments'] = Variable<String>(attachments);
    if (!nullToAbsent || voiceNotePath != null) {
      map['voice_note_path'] = Variable<String>(voiceNotePath);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['importance'] = Variable<int>(importance);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || durationMinutes != null) {
      map['duration_minutes'] = Variable<int>(durationMinutes);
    }
    map['custom_fields'] = Variable<String>(customFields);
    map['tags'] = Variable<String>(tags);
    map['is_decision'] = Variable<bool>(isDecision);
    if (!nullToAbsent || decisionOptions != null) {
      map['decision_options'] = Variable<String>(decisionOptions);
    }
    if (!nullToAbsent || decisionReasoning != null) {
      map['decision_reasoning'] = Variable<String>(decisionReasoning);
    }
    if (!nullToAbsent || decisionConfidence != null) {
      map['decision_confidence'] = Variable<int>(decisionConfidence);
    }
    if (!nullToAbsent || decisionExpectedOutcome != null) {
      map['decision_expected_outcome'] =
          Variable<String>(decisionExpectedOutcome);
    }
    if (!nullToAbsent || decisionActualOutcome != null) {
      map['decision_actual_outcome'] = Variable<String>(decisionActualOutcome);
    }
    if (!nullToAbsent || decisionReviewDate != null) {
      map['decision_review_date'] = Variable<DateTime>(decisionReviewDate);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      id: Value(id),
      title:
          title == null && nullToAbsent ? const Value.absent() : Value(title),
      note: Value(note),
      linkedEntityIds: Value(linkedEntityIds),
      attachments: Value(attachments),
      voiceNotePath: voiceNotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceNotePath),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      importance: Value(importance),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      durationMinutes: durationMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMinutes),
      customFields: Value(customFields),
      tags: Value(tags),
      isDecision: Value(isDecision),
      decisionOptions: decisionOptions == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionOptions),
      decisionReasoning: decisionReasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionReasoning),
      decisionConfidence: decisionConfidence == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionConfidence),
      decisionExpectedOutcome: decisionExpectedOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionExpectedOutcome),
      decisionActualOutcome: decisionActualOutcome == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionActualOutcome),
      decisionReviewDate: decisionReviewDate == null && nullToAbsent
          ? const Value.absent()
          : Value(decisionReviewDate),
      timestamp: Value(timestamp),
      createdAt: Value(createdAt),
    );
  }

  factory Event.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Event(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String?>(json['title']),
      note: serializer.fromJson<String>(json['note']),
      linkedEntityIds: serializer.fromJson<String>(json['linkedEntityIds']),
      attachments: serializer.fromJson<String>(json['attachments']),
      voiceNotePath: serializer.fromJson<String?>(json['voiceNotePath']),
      mood: serializer.fromJson<String?>(json['mood']),
      importance: serializer.fromJson<int>(json['importance']),
      location: serializer.fromJson<String?>(json['location']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      durationMinutes: serializer.fromJson<int?>(json['durationMinutes']),
      customFields: serializer.fromJson<String>(json['customFields']),
      tags: serializer.fromJson<String>(json['tags']),
      isDecision: serializer.fromJson<bool>(json['isDecision']),
      decisionOptions: serializer.fromJson<String?>(json['decisionOptions']),
      decisionReasoning:
          serializer.fromJson<String?>(json['decisionReasoning']),
      decisionConfidence: serializer.fromJson<int?>(json['decisionConfidence']),
      decisionExpectedOutcome:
          serializer.fromJson<String?>(json['decisionExpectedOutcome']),
      decisionActualOutcome:
          serializer.fromJson<String?>(json['decisionActualOutcome']),
      decisionReviewDate:
          serializer.fromJson<DateTime?>(json['decisionReviewDate']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String?>(title),
      'note': serializer.toJson<String>(note),
      'linkedEntityIds': serializer.toJson<String>(linkedEntityIds),
      'attachments': serializer.toJson<String>(attachments),
      'voiceNotePath': serializer.toJson<String?>(voiceNotePath),
      'mood': serializer.toJson<String?>(mood),
      'importance': serializer.toJson<int>(importance),
      'location': serializer.toJson<String?>(location),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'durationMinutes': serializer.toJson<int?>(durationMinutes),
      'customFields': serializer.toJson<String>(customFields),
      'tags': serializer.toJson<String>(tags),
      'isDecision': serializer.toJson<bool>(isDecision),
      'decisionOptions': serializer.toJson<String?>(decisionOptions),
      'decisionReasoning': serializer.toJson<String?>(decisionReasoning),
      'decisionConfidence': serializer.toJson<int?>(decisionConfidence),
      'decisionExpectedOutcome':
          serializer.toJson<String?>(decisionExpectedOutcome),
      'decisionActualOutcome':
          serializer.toJson<String?>(decisionActualOutcome),
      'decisionReviewDate': serializer.toJson<DateTime?>(decisionReviewDate),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Event copyWith(
          {String? id,
          Value<String?> title = const Value.absent(),
          String? note,
          String? linkedEntityIds,
          String? attachments,
          Value<String?> voiceNotePath = const Value.absent(),
          Value<String?> mood = const Value.absent(),
          int? importance,
          Value<String?> location = const Value.absent(),
          Value<double?> latitude = const Value.absent(),
          Value<double?> longitude = const Value.absent(),
          Value<int?> durationMinutes = const Value.absent(),
          String? customFields,
          String? tags,
          bool? isDecision,
          Value<String?> decisionOptions = const Value.absent(),
          Value<String?> decisionReasoning = const Value.absent(),
          Value<int?> decisionConfidence = const Value.absent(),
          Value<String?> decisionExpectedOutcome = const Value.absent(),
          Value<String?> decisionActualOutcome = const Value.absent(),
          Value<DateTime?> decisionReviewDate = const Value.absent(),
          DateTime? timestamp,
          DateTime? createdAt}) =>
      Event(
        id: id ?? this.id,
        title: title.present ? title.value : this.title,
        note: note ?? this.note,
        linkedEntityIds: linkedEntityIds ?? this.linkedEntityIds,
        attachments: attachments ?? this.attachments,
        voiceNotePath:
            voiceNotePath.present ? voiceNotePath.value : this.voiceNotePath,
        mood: mood.present ? mood.value : this.mood,
        importance: importance ?? this.importance,
        location: location.present ? location.value : this.location,
        latitude: latitude.present ? latitude.value : this.latitude,
        longitude: longitude.present ? longitude.value : this.longitude,
        durationMinutes: durationMinutes.present
            ? durationMinutes.value
            : this.durationMinutes,
        customFields: customFields ?? this.customFields,
        tags: tags ?? this.tags,
        isDecision: isDecision ?? this.isDecision,
        decisionOptions: decisionOptions.present
            ? decisionOptions.value
            : this.decisionOptions,
        decisionReasoning: decisionReasoning.present
            ? decisionReasoning.value
            : this.decisionReasoning,
        decisionConfidence: decisionConfidence.present
            ? decisionConfidence.value
            : this.decisionConfidence,
        decisionExpectedOutcome: decisionExpectedOutcome.present
            ? decisionExpectedOutcome.value
            : this.decisionExpectedOutcome,
        decisionActualOutcome: decisionActualOutcome.present
            ? decisionActualOutcome.value
            : this.decisionActualOutcome,
        decisionReviewDate: decisionReviewDate.present
            ? decisionReviewDate.value
            : this.decisionReviewDate,
        timestamp: timestamp ?? this.timestamp,
        createdAt: createdAt ?? this.createdAt,
      );
  Event copyWithCompanion(EventsCompanion data) {
    return Event(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      linkedEntityIds: data.linkedEntityIds.present
          ? data.linkedEntityIds.value
          : this.linkedEntityIds,
      attachments:
          data.attachments.present ? data.attachments.value : this.attachments,
      voiceNotePath: data.voiceNotePath.present
          ? data.voiceNotePath.value
          : this.voiceNotePath,
      mood: data.mood.present ? data.mood.value : this.mood,
      importance:
          data.importance.present ? data.importance.value : this.importance,
      location: data.location.present ? data.location.value : this.location,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      customFields: data.customFields.present
          ? data.customFields.value
          : this.customFields,
      tags: data.tags.present ? data.tags.value : this.tags,
      isDecision:
          data.isDecision.present ? data.isDecision.value : this.isDecision,
      decisionOptions: data.decisionOptions.present
          ? data.decisionOptions.value
          : this.decisionOptions,
      decisionReasoning: data.decisionReasoning.present
          ? data.decisionReasoning.value
          : this.decisionReasoning,
      decisionConfidence: data.decisionConfidence.present
          ? data.decisionConfidence.value
          : this.decisionConfidence,
      decisionExpectedOutcome: data.decisionExpectedOutcome.present
          ? data.decisionExpectedOutcome.value
          : this.decisionExpectedOutcome,
      decisionActualOutcome: data.decisionActualOutcome.present
          ? data.decisionActualOutcome.value
          : this.decisionActualOutcome,
      decisionReviewDate: data.decisionReviewDate.present
          ? data.decisionReviewDate.value
          : this.decisionReviewDate,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Event(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('linkedEntityIds: $linkedEntityIds, ')
          ..write('attachments: $attachments, ')
          ..write('voiceNotePath: $voiceNotePath, ')
          ..write('mood: $mood, ')
          ..write('importance: $importance, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('customFields: $customFields, ')
          ..write('tags: $tags, ')
          ..write('isDecision: $isDecision, ')
          ..write('decisionOptions: $decisionOptions, ')
          ..write('decisionReasoning: $decisionReasoning, ')
          ..write('decisionConfidence: $decisionConfidence, ')
          ..write('decisionExpectedOutcome: $decisionExpectedOutcome, ')
          ..write('decisionActualOutcome: $decisionActualOutcome, ')
          ..write('decisionReviewDate: $decisionReviewDate, ')
          ..write('timestamp: $timestamp, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        note,
        linkedEntityIds,
        attachments,
        voiceNotePath,
        mood,
        importance,
        location,
        latitude,
        longitude,
        durationMinutes,
        customFields,
        tags,
        isDecision,
        decisionOptions,
        decisionReasoning,
        decisionConfidence,
        decisionExpectedOutcome,
        decisionActualOutcome,
        decisionReviewDate,
        timestamp,
        createdAt
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Event &&
          other.id == this.id &&
          other.title == this.title &&
          other.note == this.note &&
          other.linkedEntityIds == this.linkedEntityIds &&
          other.attachments == this.attachments &&
          other.voiceNotePath == this.voiceNotePath &&
          other.mood == this.mood &&
          other.importance == this.importance &&
          other.location == this.location &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.durationMinutes == this.durationMinutes &&
          other.customFields == this.customFields &&
          other.tags == this.tags &&
          other.isDecision == this.isDecision &&
          other.decisionOptions == this.decisionOptions &&
          other.decisionReasoning == this.decisionReasoning &&
          other.decisionConfidence == this.decisionConfidence &&
          other.decisionExpectedOutcome == this.decisionExpectedOutcome &&
          other.decisionActualOutcome == this.decisionActualOutcome &&
          other.decisionReviewDate == this.decisionReviewDate &&
          other.timestamp == this.timestamp &&
          other.createdAt == this.createdAt);
}

class EventsCompanion extends UpdateCompanion<Event> {
  final Value<String> id;
  final Value<String?> title;
  final Value<String> note;
  final Value<String> linkedEntityIds;
  final Value<String> attachments;
  final Value<String?> voiceNotePath;
  final Value<String?> mood;
  final Value<int> importance;
  final Value<String?> location;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int?> durationMinutes;
  final Value<String> customFields;
  final Value<String> tags;
  final Value<bool> isDecision;
  final Value<String?> decisionOptions;
  final Value<String?> decisionReasoning;
  final Value<int?> decisionConfidence;
  final Value<String?> decisionExpectedOutcome;
  final Value<String?> decisionActualOutcome;
  final Value<DateTime?> decisionReviewDate;
  final Value<DateTime> timestamp;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.linkedEntityIds = const Value.absent(),
    this.attachments = const Value.absent(),
    this.voiceNotePath = const Value.absent(),
    this.mood = const Value.absent(),
    this.importance = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.customFields = const Value.absent(),
    this.tags = const Value.absent(),
    this.isDecision = const Value.absent(),
    this.decisionOptions = const Value.absent(),
    this.decisionReasoning = const Value.absent(),
    this.decisionConfidence = const Value.absent(),
    this.decisionExpectedOutcome = const Value.absent(),
    this.decisionActualOutcome = const Value.absent(),
    this.decisionReviewDate = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String id,
    this.title = const Value.absent(),
    required String note,
    this.linkedEntityIds = const Value.absent(),
    this.attachments = const Value.absent(),
    this.voiceNotePath = const Value.absent(),
    this.mood = const Value.absent(),
    this.importance = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.customFields = const Value.absent(),
    this.tags = const Value.absent(),
    this.isDecision = const Value.absent(),
    this.decisionOptions = const Value.absent(),
    this.decisionReasoning = const Value.absent(),
    this.decisionConfidence = const Value.absent(),
    this.decisionExpectedOutcome = const Value.absent(),
    this.decisionActualOutcome = const Value.absent(),
    this.decisionReviewDate = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        note = Value(note);
  static Insertable<Event> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? linkedEntityIds,
    Expression<String>? attachments,
    Expression<String>? voiceNotePath,
    Expression<String>? mood,
    Expression<int>? importance,
    Expression<String>? location,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? durationMinutes,
    Expression<String>? customFields,
    Expression<String>? tags,
    Expression<bool>? isDecision,
    Expression<String>? decisionOptions,
    Expression<String>? decisionReasoning,
    Expression<int>? decisionConfidence,
    Expression<String>? decisionExpectedOutcome,
    Expression<String>? decisionActualOutcome,
    Expression<DateTime>? decisionReviewDate,
    Expression<DateTime>? timestamp,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (linkedEntityIds != null) 'linked_entity_ids': linkedEntityIds,
      if (attachments != null) 'attachments': attachments,
      if (voiceNotePath != null) 'voice_note_path': voiceNotePath,
      if (mood != null) 'mood': mood,
      if (importance != null) 'importance': importance,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (customFields != null) 'custom_fields': customFields,
      if (tags != null) 'tags': tags,
      if (isDecision != null) 'is_decision': isDecision,
      if (decisionOptions != null) 'decision_options': decisionOptions,
      if (decisionReasoning != null) 'decision_reasoning': decisionReasoning,
      if (decisionConfidence != null) 'decision_confidence': decisionConfidence,
      if (decisionExpectedOutcome != null)
        'decision_expected_outcome': decisionExpectedOutcome,
      if (decisionActualOutcome != null)
        'decision_actual_outcome': decisionActualOutcome,
      if (decisionReviewDate != null)
        'decision_review_date': decisionReviewDate,
      if (timestamp != null) 'timestamp': timestamp,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith(
      {Value<String>? id,
      Value<String?>? title,
      Value<String>? note,
      Value<String>? linkedEntityIds,
      Value<String>? attachments,
      Value<String?>? voiceNotePath,
      Value<String?>? mood,
      Value<int>? importance,
      Value<String?>? location,
      Value<double?>? latitude,
      Value<double?>? longitude,
      Value<int?>? durationMinutes,
      Value<String>? customFields,
      Value<String>? tags,
      Value<bool>? isDecision,
      Value<String?>? decisionOptions,
      Value<String?>? decisionReasoning,
      Value<int?>? decisionConfidence,
      Value<String?>? decisionExpectedOutcome,
      Value<String?>? decisionActualOutcome,
      Value<DateTime?>? decisionReviewDate,
      Value<DateTime>? timestamp,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return EventsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      linkedEntityIds: linkedEntityIds ?? this.linkedEntityIds,
      attachments: attachments ?? this.attachments,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      mood: mood ?? this.mood,
      importance: importance ?? this.importance,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      customFields: customFields ?? this.customFields,
      tags: tags ?? this.tags,
      isDecision: isDecision ?? this.isDecision,
      decisionOptions: decisionOptions ?? this.decisionOptions,
      decisionReasoning: decisionReasoning ?? this.decisionReasoning,
      decisionConfidence: decisionConfidence ?? this.decisionConfidence,
      decisionExpectedOutcome:
          decisionExpectedOutcome ?? this.decisionExpectedOutcome,
      decisionActualOutcome:
          decisionActualOutcome ?? this.decisionActualOutcome,
      decisionReviewDate: decisionReviewDate ?? this.decisionReviewDate,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (linkedEntityIds.present) {
      map['linked_entity_ids'] = Variable<String>(linkedEntityIds.value);
    }
    if (attachments.present) {
      map['attachments'] = Variable<String>(attachments.value);
    }
    if (voiceNotePath.present) {
      map['voice_note_path'] = Variable<String>(voiceNotePath.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (importance.present) {
      map['importance'] = Variable<int>(importance.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (customFields.present) {
      map['custom_fields'] = Variable<String>(customFields.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (isDecision.present) {
      map['is_decision'] = Variable<bool>(isDecision.value);
    }
    if (decisionOptions.present) {
      map['decision_options'] = Variable<String>(decisionOptions.value);
    }
    if (decisionReasoning.present) {
      map['decision_reasoning'] = Variable<String>(decisionReasoning.value);
    }
    if (decisionConfidence.present) {
      map['decision_confidence'] = Variable<int>(decisionConfidence.value);
    }
    if (decisionExpectedOutcome.present) {
      map['decision_expected_outcome'] =
          Variable<String>(decisionExpectedOutcome.value);
    }
    if (decisionActualOutcome.present) {
      map['decision_actual_outcome'] =
          Variable<String>(decisionActualOutcome.value);
    }
    if (decisionReviewDate.present) {
      map['decision_review_date'] =
          Variable<DateTime>(decisionReviewDate.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('linkedEntityIds: $linkedEntityIds, ')
          ..write('attachments: $attachments, ')
          ..write('voiceNotePath: $voiceNotePath, ')
          ..write('mood: $mood, ')
          ..write('importance: $importance, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('customFields: $customFields, ')
          ..write('tags: $tags, ')
          ..write('isDecision: $isDecision, ')
          ..write('decisionOptions: $decisionOptions, ')
          ..write('decisionReasoning: $decisionReasoning, ')
          ..write('decisionConfidence: $decisionConfidence, ')
          ..write('decisionExpectedOutcome: $decisionExpectedOutcome, ')
          ..write('decisionActualOutcome: $decisionActualOutcome, ')
          ..write('decisionReviewDate: $decisionReviewDate, ')
          ..write('timestamp: $timestamp, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelationshipsTable extends Relationships
    with TableInfo<$RelationshipsTable, Relationship> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelationshipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fromEntityIdMeta =
      const VerificationMeta('fromEntityId');
  @override
  late final GeneratedColumn<String> fromEntityId = GeneratedColumn<String>(
      'from_entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _toEntityIdMeta =
      const VerificationMeta('toEntityId');
  @override
  late final GeneratedColumn<String> toEntityId = GeneratedColumn<String>(
      'to_entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relationshipTypeMeta =
      const VerificationMeta('relationshipType');
  @override
  late final GeneratedColumn<String> relationshipType = GeneratedColumn<String>(
      'relationship_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _strengthMeta =
      const VerificationMeta('strength');
  @override
  late final GeneratedColumn<double> strength = GeneratedColumn<double>(
      'strength', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(1.0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        fromEntityId,
        toEntityId,
        relationshipType,
        description,
        strength,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'relationships';
  @override
  VerificationContext validateIntegrity(Insertable<Relationship> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('from_entity_id')) {
      context.handle(
          _fromEntityIdMeta,
          fromEntityId.isAcceptableOrUnknown(
              data['from_entity_id']!, _fromEntityIdMeta));
    } else if (isInserting) {
      context.missing(_fromEntityIdMeta);
    }
    if (data.containsKey('to_entity_id')) {
      context.handle(
          _toEntityIdMeta,
          toEntityId.isAcceptableOrUnknown(
              data['to_entity_id']!, _toEntityIdMeta));
    } else if (isInserting) {
      context.missing(_toEntityIdMeta);
    }
    if (data.containsKey('relationship_type')) {
      context.handle(
          _relationshipTypeMeta,
          relationshipType.isAcceptableOrUnknown(
              data['relationship_type']!, _relationshipTypeMeta));
    } else if (isInserting) {
      context.missing(_relationshipTypeMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('strength')) {
      context.handle(_strengthMeta,
          strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Relationship map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Relationship(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      fromEntityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}from_entity_id'])!,
      toEntityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}to_entity_id'])!,
      relationshipType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}relationship_type'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      strength: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}strength'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $RelationshipsTable createAlias(String alias) {
    return $RelationshipsTable(attachedDatabase, alias);
  }
}

class Relationship extends DataClass implements Insertable<Relationship> {
  final String id;
  final String fromEntityId;
  final String toEntityId;
  final String relationshipType;
  final String? description;
  final double strength;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Relationship(
      {required this.id,
      required this.fromEntityId,
      required this.toEntityId,
      required this.relationshipType,
      this.description,
      required this.strength,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['from_entity_id'] = Variable<String>(fromEntityId);
    map['to_entity_id'] = Variable<String>(toEntityId);
    map['relationship_type'] = Variable<String>(relationshipType);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['strength'] = Variable<double>(strength);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RelationshipsCompanion toCompanion(bool nullToAbsent) {
    return RelationshipsCompanion(
      id: Value(id),
      fromEntityId: Value(fromEntityId),
      toEntityId: Value(toEntityId),
      relationshipType: Value(relationshipType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      strength: Value(strength),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Relationship.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Relationship(
      id: serializer.fromJson<String>(json['id']),
      fromEntityId: serializer.fromJson<String>(json['fromEntityId']),
      toEntityId: serializer.fromJson<String>(json['toEntityId']),
      relationshipType: serializer.fromJson<String>(json['relationshipType']),
      description: serializer.fromJson<String?>(json['description']),
      strength: serializer.fromJson<double>(json['strength']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'fromEntityId': serializer.toJson<String>(fromEntityId),
      'toEntityId': serializer.toJson<String>(toEntityId),
      'relationshipType': serializer.toJson<String>(relationshipType),
      'description': serializer.toJson<String?>(description),
      'strength': serializer.toJson<double>(strength),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Relationship copyWith(
          {String? id,
          String? fromEntityId,
          String? toEntityId,
          String? relationshipType,
          Value<String?> description = const Value.absent(),
          double? strength,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Relationship(
        id: id ?? this.id,
        fromEntityId: fromEntityId ?? this.fromEntityId,
        toEntityId: toEntityId ?? this.toEntityId,
        relationshipType: relationshipType ?? this.relationshipType,
        description: description.present ? description.value : this.description,
        strength: strength ?? this.strength,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Relationship copyWithCompanion(RelationshipsCompanion data) {
    return Relationship(
      id: data.id.present ? data.id.value : this.id,
      fromEntityId: data.fromEntityId.present
          ? data.fromEntityId.value
          : this.fromEntityId,
      toEntityId:
          data.toEntityId.present ? data.toEntityId.value : this.toEntityId,
      relationshipType: data.relationshipType.present
          ? data.relationshipType.value
          : this.relationshipType,
      description:
          data.description.present ? data.description.value : this.description,
      strength: data.strength.present ? data.strength.value : this.strength,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Relationship(')
          ..write('id: $id, ')
          ..write('fromEntityId: $fromEntityId, ')
          ..write('toEntityId: $toEntityId, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('description: $description, ')
          ..write('strength: $strength, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromEntityId, toEntityId,
      relationshipType, description, strength, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Relationship &&
          other.id == this.id &&
          other.fromEntityId == this.fromEntityId &&
          other.toEntityId == this.toEntityId &&
          other.relationshipType == this.relationshipType &&
          other.description == this.description &&
          other.strength == this.strength &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RelationshipsCompanion extends UpdateCompanion<Relationship> {
  final Value<String> id;
  final Value<String> fromEntityId;
  final Value<String> toEntityId;
  final Value<String> relationshipType;
  final Value<String?> description;
  final Value<double> strength;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const RelationshipsCompanion({
    this.id = const Value.absent(),
    this.fromEntityId = const Value.absent(),
    this.toEntityId = const Value.absent(),
    this.relationshipType = const Value.absent(),
    this.description = const Value.absent(),
    this.strength = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelationshipsCompanion.insert({
    required String id,
    required String fromEntityId,
    required String toEntityId,
    required String relationshipType,
    this.description = const Value.absent(),
    this.strength = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        fromEntityId = Value(fromEntityId),
        toEntityId = Value(toEntityId),
        relationshipType = Value(relationshipType);
  static Insertable<Relationship> custom({
    Expression<String>? id,
    Expression<String>? fromEntityId,
    Expression<String>? toEntityId,
    Expression<String>? relationshipType,
    Expression<String>? description,
    Expression<double>? strength,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromEntityId != null) 'from_entity_id': fromEntityId,
      if (toEntityId != null) 'to_entity_id': toEntityId,
      if (relationshipType != null) 'relationship_type': relationshipType,
      if (description != null) 'description': description,
      if (strength != null) 'strength': strength,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelationshipsCompanion copyWith(
      {Value<String>? id,
      Value<String>? fromEntityId,
      Value<String>? toEntityId,
      Value<String>? relationshipType,
      Value<String?>? description,
      Value<double>? strength,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return RelationshipsCompanion(
      id: id ?? this.id,
      fromEntityId: fromEntityId ?? this.fromEntityId,
      toEntityId: toEntityId ?? this.toEntityId,
      relationshipType: relationshipType ?? this.relationshipType,
      description: description ?? this.description,
      strength: strength ?? this.strength,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (fromEntityId.present) {
      map['from_entity_id'] = Variable<String>(fromEntityId.value);
    }
    if (toEntityId.present) {
      map['to_entity_id'] = Variable<String>(toEntityId.value);
    }
    if (relationshipType.present) {
      map['relationship_type'] = Variable<String>(relationshipType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (strength.present) {
      map['strength'] = Variable<double>(strength.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelationshipsCompanion(')
          ..write('id: $id, ')
          ..write('fromEntityId: $fromEntityId, ')
          ..write('toEntityId: $toEntityId, ')
          ..write('relationshipType: $relationshipType, ')
          ..write('description: $description, ')
          ..write('strength: $strength, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternsTable extends Patterns with TableInfo<$PatternsTable, Pattern> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _patternTypeMeta =
      const VerificationMeta('patternType');
  @override
  late final GeneratedColumn<String> patternType = GeneratedColumn<String>(
      'pattern_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _relatedEntityIdsMeta =
      const VerificationMeta('relatedEntityIds');
  @override
  late final GeneratedColumn<String> relatedEntityIds = GeneratedColumn<String>(
      'related_entity_ids', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _evidenceMeta =
      const VerificationMeta('evidence');
  @override
  late final GeneratedColumn<String> evidence = GeneratedColumn<String>(
      'evidence', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _confidenceMeta =
      const VerificationMeta('confidence');
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
      'confidence', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _occurrencesMeta =
      const VerificationMeta('occurrences');
  @override
  late final GeneratedColumn<int> occurrences = GeneratedColumn<int>(
      'occurrences', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _firstSeenMeta =
      const VerificationMeta('firstSeen');
  @override
  late final GeneratedColumn<DateTime> firstSeen = GeneratedColumn<DateTime>(
      'first_seen', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
      'last_seen', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        description,
        patternType,
        relatedEntityIds,
        evidence,
        confidence,
        occurrences,
        firstSeen,
        lastSeen,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'patterns';
  @override
  VerificationContext validateIntegrity(Insertable<Pattern> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('pattern_type')) {
      context.handle(
          _patternTypeMeta,
          patternType.isAcceptableOrUnknown(
              data['pattern_type']!, _patternTypeMeta));
    } else if (isInserting) {
      context.missing(_patternTypeMeta);
    }
    if (data.containsKey('related_entity_ids')) {
      context.handle(
          _relatedEntityIdsMeta,
          relatedEntityIds.isAcceptableOrUnknown(
              data['related_entity_ids']!, _relatedEntityIdsMeta));
    }
    if (data.containsKey('evidence')) {
      context.handle(_evidenceMeta,
          evidence.isAcceptableOrUnknown(data['evidence']!, _evidenceMeta));
    }
    if (data.containsKey('confidence')) {
      context.handle(
          _confidenceMeta,
          confidence.isAcceptableOrUnknown(
              data['confidence']!, _confidenceMeta));
    }
    if (data.containsKey('occurrences')) {
      context.handle(
          _occurrencesMeta,
          occurrences.isAcceptableOrUnknown(
              data['occurrences']!, _occurrencesMeta));
    }
    if (data.containsKey('first_seen')) {
      context.handle(_firstSeenMeta,
          firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta));
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Pattern map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Pattern(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description'])!,
      patternType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}pattern_type'])!,
      relatedEntityIds: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}related_entity_ids'])!,
      evidence: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}evidence'])!,
      confidence: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}confidence'])!,
      occurrences: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}occurrences'])!,
      firstSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}first_seen'])!,
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PatternsTable createAlias(String alias) {
    return $PatternsTable(attachedDatabase, alias);
  }
}

class Pattern extends DataClass implements Insertable<Pattern> {
  final String id;
  final String title;
  final String description;
  final String patternType;
  final String relatedEntityIds;
  final String evidence;
  final double confidence;
  final int occurrences;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final DateTime updatedAt;
  const Pattern(
      {required this.id,
      required this.title,
      required this.description,
      required this.patternType,
      required this.relatedEntityIds,
      required this.evidence,
      required this.confidence,
      required this.occurrences,
      required this.firstSeen,
      required this.lastSeen,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['pattern_type'] = Variable<String>(patternType);
    map['related_entity_ids'] = Variable<String>(relatedEntityIds);
    map['evidence'] = Variable<String>(evidence);
    map['confidence'] = Variable<double>(confidence);
    map['occurrences'] = Variable<int>(occurrences);
    map['first_seen'] = Variable<DateTime>(firstSeen);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PatternsCompanion toCompanion(bool nullToAbsent) {
    return PatternsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      patternType: Value(patternType),
      relatedEntityIds: Value(relatedEntityIds),
      evidence: Value(evidence),
      confidence: Value(confidence),
      occurrences: Value(occurrences),
      firstSeen: Value(firstSeen),
      lastSeen: Value(lastSeen),
      updatedAt: Value(updatedAt),
    );
  }

  factory Pattern.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Pattern(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      patternType: serializer.fromJson<String>(json['patternType']),
      relatedEntityIds: serializer.fromJson<String>(json['relatedEntityIds']),
      evidence: serializer.fromJson<String>(json['evidence']),
      confidence: serializer.fromJson<double>(json['confidence']),
      occurrences: serializer.fromJson<int>(json['occurrences']),
      firstSeen: serializer.fromJson<DateTime>(json['firstSeen']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'patternType': serializer.toJson<String>(patternType),
      'relatedEntityIds': serializer.toJson<String>(relatedEntityIds),
      'evidence': serializer.toJson<String>(evidence),
      'confidence': serializer.toJson<double>(confidence),
      'occurrences': serializer.toJson<int>(occurrences),
      'firstSeen': serializer.toJson<DateTime>(firstSeen),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Pattern copyWith(
          {String? id,
          String? title,
          String? description,
          String? patternType,
          String? relatedEntityIds,
          String? evidence,
          double? confidence,
          int? occurrences,
          DateTime? firstSeen,
          DateTime? lastSeen,
          DateTime? updatedAt}) =>
      Pattern(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        patternType: patternType ?? this.patternType,
        relatedEntityIds: relatedEntityIds ?? this.relatedEntityIds,
        evidence: evidence ?? this.evidence,
        confidence: confidence ?? this.confidence,
        occurrences: occurrences ?? this.occurrences,
        firstSeen: firstSeen ?? this.firstSeen,
        lastSeen: lastSeen ?? this.lastSeen,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Pattern copyWithCompanion(PatternsCompanion data) {
    return Pattern(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description:
          data.description.present ? data.description.value : this.description,
      patternType:
          data.patternType.present ? data.patternType.value : this.patternType,
      relatedEntityIds: data.relatedEntityIds.present
          ? data.relatedEntityIds.value
          : this.relatedEntityIds,
      evidence: data.evidence.present ? data.evidence.value : this.evidence,
      confidence:
          data.confidence.present ? data.confidence.value : this.confidence,
      occurrences:
          data.occurrences.present ? data.occurrences.value : this.occurrences,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Pattern(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('patternType: $patternType, ')
          ..write('relatedEntityIds: $relatedEntityIds, ')
          ..write('evidence: $evidence, ')
          ..write('confidence: $confidence, ')
          ..write('occurrences: $occurrences, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      title,
      description,
      patternType,
      relatedEntityIds,
      evidence,
      confidence,
      occurrences,
      firstSeen,
      lastSeen,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Pattern &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.patternType == this.patternType &&
          other.relatedEntityIds == this.relatedEntityIds &&
          other.evidence == this.evidence &&
          other.confidence == this.confidence &&
          other.occurrences == this.occurrences &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen &&
          other.updatedAt == this.updatedAt);
}

class PatternsCompanion extends UpdateCompanion<Pattern> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> patternType;
  final Value<String> relatedEntityIds;
  final Value<String> evidence;
  final Value<double> confidence;
  final Value<int> occurrences;
  final Value<DateTime> firstSeen;
  final Value<DateTime> lastSeen;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PatternsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.patternType = const Value.absent(),
    this.relatedEntityIds = const Value.absent(),
    this.evidence = const Value.absent(),
    this.confidence = const Value.absent(),
    this.occurrences = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternsCompanion.insert({
    required String id,
    required String title,
    required String description,
    required String patternType,
    this.relatedEntityIds = const Value.absent(),
    this.evidence = const Value.absent(),
    this.confidence = const Value.absent(),
    this.occurrences = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        description = Value(description),
        patternType = Value(patternType);
  static Insertable<Pattern> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? patternType,
    Expression<String>? relatedEntityIds,
    Expression<String>? evidence,
    Expression<double>? confidence,
    Expression<int>? occurrences,
    Expression<DateTime>? firstSeen,
    Expression<DateTime>? lastSeen,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (patternType != null) 'pattern_type': patternType,
      if (relatedEntityIds != null) 'related_entity_ids': relatedEntityIds,
      if (evidence != null) 'evidence': evidence,
      if (confidence != null) 'confidence': confidence,
      if (occurrences != null) 'occurrences': occurrences,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternsCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? description,
      Value<String>? patternType,
      Value<String>? relatedEntityIds,
      Value<String>? evidence,
      Value<double>? confidence,
      Value<int>? occurrences,
      Value<DateTime>? firstSeen,
      Value<DateTime>? lastSeen,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return PatternsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      patternType: patternType ?? this.patternType,
      relatedEntityIds: relatedEntityIds ?? this.relatedEntityIds,
      evidence: evidence ?? this.evidence,
      confidence: confidence ?? this.confidence,
      occurrences: occurrences ?? this.occurrences,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (patternType.present) {
      map['pattern_type'] = Variable<String>(patternType.value);
    }
    if (relatedEntityIds.present) {
      map['related_entity_ids'] = Variable<String>(relatedEntityIds.value);
    }
    if (evidence.present) {
      map['evidence'] = Variable<String>(evidence.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (occurrences.present) {
      map['occurrences'] = Variable<int>(occurrences.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<DateTime>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('patternType: $patternType, ')
          ..write('relatedEntityIds: $relatedEntityIds, ')
          ..write('evidence: $evidence, ')
          ..write('confidence: $confidence, ')
          ..write('occurrences: $occurrences, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EntityStatisticsTable extends EntityStatistics
    with TableInfo<$EntityStatisticsTable, EntityStatistic> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntityStatisticsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalEventsMeta =
      const VerificationMeta('totalEvents');
  @override
  late final GeneratedColumn<int> totalEvents = GeneratedColumn<int>(
      'total_events', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalDecisionsMeta =
      const VerificationMeta('totalDecisions');
  @override
  late final GeneratedColumn<int> totalDecisions = GeneratedColumn<int>(
      'total_decisions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _avgMoodScoreMeta =
      const VerificationMeta('avgMoodScore');
  @override
  late final GeneratedColumn<double> avgMoodScore = GeneratedColumn<double>(
      'avg_mood_score', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _avgImportanceMeta =
      const VerificationMeta('avgImportance');
  @override
  late final GeneratedColumn<double> avgImportance = GeneratedColumn<double>(
      'avg_importance', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _moodDistributionMeta =
      const VerificationMeta('moodDistribution');
  @override
  late final GeneratedColumn<String> moodDistribution = GeneratedColumn<String>(
      'mood_distribution', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _monthlyActivityMeta =
      const VerificationMeta('monthlyActivity');
  @override
  late final GeneratedColumn<String> monthlyActivity = GeneratedColumn<String>(
      'monthly_activity', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _lastEventAtMeta =
      const VerificationMeta('lastEventAt');
  @override
  late final GeneratedColumn<DateTime> lastEventAt = GeneratedColumn<DateTime>(
      'last_event_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        entityId,
        totalEvents,
        totalDecisions,
        avgMoodScore,
        avgImportance,
        moodDistribution,
        monthlyActivity,
        lastEventAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entity_statistics';
  @override
  VerificationContext validateIntegrity(Insertable<EntityStatistic> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('total_events')) {
      context.handle(
          _totalEventsMeta,
          totalEvents.isAcceptableOrUnknown(
              data['total_events']!, _totalEventsMeta));
    }
    if (data.containsKey('total_decisions')) {
      context.handle(
          _totalDecisionsMeta,
          totalDecisions.isAcceptableOrUnknown(
              data['total_decisions']!, _totalDecisionsMeta));
    }
    if (data.containsKey('avg_mood_score')) {
      context.handle(
          _avgMoodScoreMeta,
          avgMoodScore.isAcceptableOrUnknown(
              data['avg_mood_score']!, _avgMoodScoreMeta));
    }
    if (data.containsKey('avg_importance')) {
      context.handle(
          _avgImportanceMeta,
          avgImportance.isAcceptableOrUnknown(
              data['avg_importance']!, _avgImportanceMeta));
    }
    if (data.containsKey('mood_distribution')) {
      context.handle(
          _moodDistributionMeta,
          moodDistribution.isAcceptableOrUnknown(
              data['mood_distribution']!, _moodDistributionMeta));
    }
    if (data.containsKey('monthly_activity')) {
      context.handle(
          _monthlyActivityMeta,
          monthlyActivity.isAcceptableOrUnknown(
              data['monthly_activity']!, _monthlyActivityMeta));
    }
    if (data.containsKey('last_event_at')) {
      context.handle(
          _lastEventAtMeta,
          lastEventAt.isAcceptableOrUnknown(
              data['last_event_at']!, _lastEventAtMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId};
  @override
  EntityStatistic map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityStatistic(
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      totalEvents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_events'])!,
      totalDecisions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_decisions'])!,
      avgMoodScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_mood_score'])!,
      avgImportance: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}avg_importance'])!,
      moodDistribution: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}mood_distribution'])!,
      monthlyActivity: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}monthly_activity'])!,
      lastEventAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_event_at']),
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EntityStatisticsTable createAlias(String alias) {
    return $EntityStatisticsTable(attachedDatabase, alias);
  }
}

class EntityStatistic extends DataClass implements Insertable<EntityStatistic> {
  final String entityId;
  final int totalEvents;
  final int totalDecisions;
  final double avgMoodScore;
  final double avgImportance;
  final String moodDistribution;
  final String monthlyActivity;
  final DateTime? lastEventAt;
  final DateTime updatedAt;
  const EntityStatistic(
      {required this.entityId,
      required this.totalEvents,
      required this.totalDecisions,
      required this.avgMoodScore,
      required this.avgImportance,
      required this.moodDistribution,
      required this.monthlyActivity,
      this.lastEventAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['total_events'] = Variable<int>(totalEvents);
    map['total_decisions'] = Variable<int>(totalDecisions);
    map['avg_mood_score'] = Variable<double>(avgMoodScore);
    map['avg_importance'] = Variable<double>(avgImportance);
    map['mood_distribution'] = Variable<String>(moodDistribution);
    map['monthly_activity'] = Variable<String>(monthlyActivity);
    if (!nullToAbsent || lastEventAt != null) {
      map['last_event_at'] = Variable<DateTime>(lastEventAt);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EntityStatisticsCompanion toCompanion(bool nullToAbsent) {
    return EntityStatisticsCompanion(
      entityId: Value(entityId),
      totalEvents: Value(totalEvents),
      totalDecisions: Value(totalDecisions),
      avgMoodScore: Value(avgMoodScore),
      avgImportance: Value(avgImportance),
      moodDistribution: Value(moodDistribution),
      monthlyActivity: Value(monthlyActivity),
      lastEventAt: lastEventAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastEventAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EntityStatistic.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityStatistic(
      entityId: serializer.fromJson<String>(json['entityId']),
      totalEvents: serializer.fromJson<int>(json['totalEvents']),
      totalDecisions: serializer.fromJson<int>(json['totalDecisions']),
      avgMoodScore: serializer.fromJson<double>(json['avgMoodScore']),
      avgImportance: serializer.fromJson<double>(json['avgImportance']),
      moodDistribution: serializer.fromJson<String>(json['moodDistribution']),
      monthlyActivity: serializer.fromJson<String>(json['monthlyActivity']),
      lastEventAt: serializer.fromJson<DateTime?>(json['lastEventAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityId': serializer.toJson<String>(entityId),
      'totalEvents': serializer.toJson<int>(totalEvents),
      'totalDecisions': serializer.toJson<int>(totalDecisions),
      'avgMoodScore': serializer.toJson<double>(avgMoodScore),
      'avgImportance': serializer.toJson<double>(avgImportance),
      'moodDistribution': serializer.toJson<String>(moodDistribution),
      'monthlyActivity': serializer.toJson<String>(monthlyActivity),
      'lastEventAt': serializer.toJson<DateTime?>(lastEventAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EntityStatistic copyWith(
          {String? entityId,
          int? totalEvents,
          int? totalDecisions,
          double? avgMoodScore,
          double? avgImportance,
          String? moodDistribution,
          String? monthlyActivity,
          Value<DateTime?> lastEventAt = const Value.absent(),
          DateTime? updatedAt}) =>
      EntityStatistic(
        entityId: entityId ?? this.entityId,
        totalEvents: totalEvents ?? this.totalEvents,
        totalDecisions: totalDecisions ?? this.totalDecisions,
        avgMoodScore: avgMoodScore ?? this.avgMoodScore,
        avgImportance: avgImportance ?? this.avgImportance,
        moodDistribution: moodDistribution ?? this.moodDistribution,
        monthlyActivity: monthlyActivity ?? this.monthlyActivity,
        lastEventAt: lastEventAt.present ? lastEventAt.value : this.lastEventAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EntityStatistic copyWithCompanion(EntityStatisticsCompanion data) {
    return EntityStatistic(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      totalEvents:
          data.totalEvents.present ? data.totalEvents.value : this.totalEvents,
      totalDecisions: data.totalDecisions.present
          ? data.totalDecisions.value
          : this.totalDecisions,
      avgMoodScore: data.avgMoodScore.present
          ? data.avgMoodScore.value
          : this.avgMoodScore,
      avgImportance: data.avgImportance.present
          ? data.avgImportance.value
          : this.avgImportance,
      moodDistribution: data.moodDistribution.present
          ? data.moodDistribution.value
          : this.moodDistribution,
      monthlyActivity: data.monthlyActivity.present
          ? data.monthlyActivity.value
          : this.monthlyActivity,
      lastEventAt:
          data.lastEventAt.present ? data.lastEventAt.value : this.lastEventAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityStatistic(')
          ..write('entityId: $entityId, ')
          ..write('totalEvents: $totalEvents, ')
          ..write('totalDecisions: $totalDecisions, ')
          ..write('avgMoodScore: $avgMoodScore, ')
          ..write('avgImportance: $avgImportance, ')
          ..write('moodDistribution: $moodDistribution, ')
          ..write('monthlyActivity: $monthlyActivity, ')
          ..write('lastEventAt: $lastEventAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      entityId,
      totalEvents,
      totalDecisions,
      avgMoodScore,
      avgImportance,
      moodDistribution,
      monthlyActivity,
      lastEventAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityStatistic &&
          other.entityId == this.entityId &&
          other.totalEvents == this.totalEvents &&
          other.totalDecisions == this.totalDecisions &&
          other.avgMoodScore == this.avgMoodScore &&
          other.avgImportance == this.avgImportance &&
          other.moodDistribution == this.moodDistribution &&
          other.monthlyActivity == this.monthlyActivity &&
          other.lastEventAt == this.lastEventAt &&
          other.updatedAt == this.updatedAt);
}

class EntityStatisticsCompanion extends UpdateCompanion<EntityStatistic> {
  final Value<String> entityId;
  final Value<int> totalEvents;
  final Value<int> totalDecisions;
  final Value<double> avgMoodScore;
  final Value<double> avgImportance;
  final Value<String> moodDistribution;
  final Value<String> monthlyActivity;
  final Value<DateTime?> lastEventAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EntityStatisticsCompanion({
    this.entityId = const Value.absent(),
    this.totalEvents = const Value.absent(),
    this.totalDecisions = const Value.absent(),
    this.avgMoodScore = const Value.absent(),
    this.avgImportance = const Value.absent(),
    this.moodDistribution = const Value.absent(),
    this.monthlyActivity = const Value.absent(),
    this.lastEventAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntityStatisticsCompanion.insert({
    required String entityId,
    this.totalEvents = const Value.absent(),
    this.totalDecisions = const Value.absent(),
    this.avgMoodScore = const Value.absent(),
    this.avgImportance = const Value.absent(),
    this.moodDistribution = const Value.absent(),
    this.monthlyActivity = const Value.absent(),
    this.lastEventAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId);
  static Insertable<EntityStatistic> custom({
    Expression<String>? entityId,
    Expression<int>? totalEvents,
    Expression<int>? totalDecisions,
    Expression<double>? avgMoodScore,
    Expression<double>? avgImportance,
    Expression<String>? moodDistribution,
    Expression<String>? monthlyActivity,
    Expression<DateTime>? lastEventAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (totalEvents != null) 'total_events': totalEvents,
      if (totalDecisions != null) 'total_decisions': totalDecisions,
      if (avgMoodScore != null) 'avg_mood_score': avgMoodScore,
      if (avgImportance != null) 'avg_importance': avgImportance,
      if (moodDistribution != null) 'mood_distribution': moodDistribution,
      if (monthlyActivity != null) 'monthly_activity': monthlyActivity,
      if (lastEventAt != null) 'last_event_at': lastEventAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntityStatisticsCompanion copyWith(
      {Value<String>? entityId,
      Value<int>? totalEvents,
      Value<int>? totalDecisions,
      Value<double>? avgMoodScore,
      Value<double>? avgImportance,
      Value<String>? moodDistribution,
      Value<String>? monthlyActivity,
      Value<DateTime?>? lastEventAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return EntityStatisticsCompanion(
      entityId: entityId ?? this.entityId,
      totalEvents: totalEvents ?? this.totalEvents,
      totalDecisions: totalDecisions ?? this.totalDecisions,
      avgMoodScore: avgMoodScore ?? this.avgMoodScore,
      avgImportance: avgImportance ?? this.avgImportance,
      moodDistribution: moodDistribution ?? this.moodDistribution,
      monthlyActivity: monthlyActivity ?? this.monthlyActivity,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (totalEvents.present) {
      map['total_events'] = Variable<int>(totalEvents.value);
    }
    if (totalDecisions.present) {
      map['total_decisions'] = Variable<int>(totalDecisions.value);
    }
    if (avgMoodScore.present) {
      map['avg_mood_score'] = Variable<double>(avgMoodScore.value);
    }
    if (avgImportance.present) {
      map['avg_importance'] = Variable<double>(avgImportance.value);
    }
    if (moodDistribution.present) {
      map['mood_distribution'] = Variable<String>(moodDistribution.value);
    }
    if (monthlyActivity.present) {
      map['monthly_activity'] = Variable<String>(monthlyActivity.value);
    }
    if (lastEventAt.present) {
      map['last_event_at'] = Variable<DateTime>(lastEventAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntityStatisticsCompanion(')
          ..write('entityId: $entityId, ')
          ..write('totalEvents: $totalEvents, ')
          ..write('totalDecisions: $totalDecisions, ')
          ..write('avgMoodScore: $avgMoodScore, ')
          ..write('avgImportance: $avgImportance, ')
          ..write('moodDistribution: $moodDistribution, ')
          ..write('monthlyActivity: $monthlyActivity, ')
          ..write('lastEventAt: $lastEventAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmbeddingsTable extends Embeddings
    with TableInfo<$EmbeddingsTable, Embedding> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmbeddingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sourceIdMeta =
      const VerificationMeta('sourceId');
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
      'source_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _embeddingJsonMeta =
      const VerificationMeta('embeddingJson');
  @override
  late final GeneratedColumn<String> embeddingJson = GeneratedColumn<String>(
      'embedding_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, sourceType, sourceId, embeddingJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'embeddings';
  @override
  VerificationContext validateIntegrity(Insertable<Embedding> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(_sourceIdMeta,
          sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta));
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('embedding_json')) {
      context.handle(
          _embeddingJsonMeta,
          embeddingJson.isAcceptableOrUnknown(
              data['embedding_json']!, _embeddingJsonMeta));
    } else if (isInserting) {
      context.missing(_embeddingJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Embedding map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Embedding(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      sourceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_id'])!,
      embeddingJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}embedding_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $EmbeddingsTable createAlias(String alias) {
    return $EmbeddingsTable(attachedDatabase, alias);
  }
}

class Embedding extends DataClass implements Insertable<Embedding> {
  final String id;
  final String sourceType;
  final String sourceId;
  final String embeddingJson;
  final DateTime createdAt;
  const Embedding(
      {required this.id,
      required this.sourceType,
      required this.sourceId,
      required this.embeddingJson,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_type'] = Variable<String>(sourceType);
    map['source_id'] = Variable<String>(sourceId);
    map['embedding_json'] = Variable<String>(embeddingJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  EmbeddingsCompanion toCompanion(bool nullToAbsent) {
    return EmbeddingsCompanion(
      id: Value(id),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      embeddingJson: Value(embeddingJson),
      createdAt: Value(createdAt),
    );
  }

  factory Embedding.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Embedding(
      id: serializer.fromJson<String>(json['id']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceId: serializer.fromJson<String>(json['sourceId']),
      embeddingJson: serializer.fromJson<String>(json['embeddingJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceId': serializer.toJson<String>(sourceId),
      'embeddingJson': serializer.toJson<String>(embeddingJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Embedding copyWith(
          {String? id,
          String? sourceType,
          String? sourceId,
          String? embeddingJson,
          DateTime? createdAt}) =>
      Embedding(
        id: id ?? this.id,
        sourceType: sourceType ?? this.sourceType,
        sourceId: sourceId ?? this.sourceId,
        embeddingJson: embeddingJson ?? this.embeddingJson,
        createdAt: createdAt ?? this.createdAt,
      );
  Embedding copyWithCompanion(EmbeddingsCompanion data) {
    return Embedding(
      id: data.id.present ? data.id.value : this.id,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      embeddingJson: data.embeddingJson.present
          ? data.embeddingJson.value
          : this.embeddingJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Embedding(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('embeddingJson: $embeddingJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, sourceType, sourceId, embeddingJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Embedding &&
          other.id == this.id &&
          other.sourceType == this.sourceType &&
          other.sourceId == this.sourceId &&
          other.embeddingJson == this.embeddingJson &&
          other.createdAt == this.createdAt);
}

class EmbeddingsCompanion extends UpdateCompanion<Embedding> {
  final Value<String> id;
  final Value<String> sourceType;
  final Value<String> sourceId;
  final Value<String> embeddingJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const EmbeddingsCompanion({
    this.id = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.embeddingJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmbeddingsCompanion.insert({
    required String id,
    required String sourceType,
    required String sourceId,
    required String embeddingJson,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        sourceType = Value(sourceType),
        sourceId = Value(sourceId),
        embeddingJson = Value(embeddingJson);
  static Insertable<Embedding> custom({
    Expression<String>? id,
    Expression<String>? sourceType,
    Expression<String>? sourceId,
    Expression<String>? embeddingJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceId != null) 'source_id': sourceId,
      if (embeddingJson != null) 'embedding_json': embeddingJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmbeddingsCompanion copyWith(
      {Value<String>? id,
      Value<String>? sourceType,
      Value<String>? sourceId,
      Value<String>? embeddingJson,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return EmbeddingsCompanion(
      id: id ?? this.id,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      embeddingJson: embeddingJson ?? this.embeddingJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (embeddingJson.present) {
      map['embedding_json'] = Variable<String>(embeddingJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmbeddingsCompanion(')
          ..write('id: $id, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceId: $sourceId, ')
          ..write('embeddingJson: $embeddingJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalyticsCacheTable extends AnalyticsCache
    with TableInfo<$AnalyticsCacheTable, AnalyticsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalyticsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _computedAtMeta =
      const VerificationMeta('computedAt');
  @override
  late final GeneratedColumn<DateTime> computedAt = GeneratedColumn<DateTime>(
      'computed_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [cacheKey, data, computedAt, expiresAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analytics_cache';
  @override
  VerificationContext validateIntegrity(Insertable<AnalyticsCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
          _computedAtMeta,
          computedAt.isAcceptableOrUnknown(
              data['computed_at']!, _computedAtMeta));
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    } else if (isInserting) {
      context.missing(_expiresAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  AnalyticsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalyticsCacheData(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      computedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}computed_at'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at'])!,
    );
  }

  @override
  $AnalyticsCacheTable createAlias(String alias) {
    return $AnalyticsCacheTable(attachedDatabase, alias);
  }
}

class AnalyticsCacheData extends DataClass
    implements Insertable<AnalyticsCacheData> {
  final String cacheKey;
  final String data;
  final DateTime computedAt;
  final DateTime expiresAt;
  const AnalyticsCacheData(
      {required this.cacheKey,
      required this.data,
      required this.computedAt,
      required this.expiresAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['data'] = Variable<String>(data);
    map['computed_at'] = Variable<DateTime>(computedAt);
    map['expires_at'] = Variable<DateTime>(expiresAt);
    return map;
  }

  AnalyticsCacheCompanion toCompanion(bool nullToAbsent) {
    return AnalyticsCacheCompanion(
      cacheKey: Value(cacheKey),
      data: Value(data),
      computedAt: Value(computedAt),
      expiresAt: Value(expiresAt),
    );
  }

  factory AnalyticsCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalyticsCacheData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      data: serializer.fromJson<String>(json['data']),
      computedAt: serializer.fromJson<DateTime>(json['computedAt']),
      expiresAt: serializer.fromJson<DateTime>(json['expiresAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'data': serializer.toJson<String>(data),
      'computedAt': serializer.toJson<DateTime>(computedAt),
      'expiresAt': serializer.toJson<DateTime>(expiresAt),
    };
  }

  AnalyticsCacheData copyWith(
          {String? cacheKey,
          String? data,
          DateTime? computedAt,
          DateTime? expiresAt}) =>
      AnalyticsCacheData(
        cacheKey: cacheKey ?? this.cacheKey,
        data: data ?? this.data,
        computedAt: computedAt ?? this.computedAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );
  AnalyticsCacheData copyWithCompanion(AnalyticsCacheCompanion data) {
    return AnalyticsCacheData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      data: data.data.present ? data.data.value : this.data,
      computedAt:
          data.computedAt.present ? data.computedAt.value : this.computedAt,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsCacheData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('computedAt: $computedAt, ')
          ..write('expiresAt: $expiresAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, data, computedAt, expiresAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalyticsCacheData &&
          other.cacheKey == this.cacheKey &&
          other.data == this.data &&
          other.computedAt == this.computedAt &&
          other.expiresAt == this.expiresAt);
}

class AnalyticsCacheCompanion extends UpdateCompanion<AnalyticsCacheData> {
  final Value<String> cacheKey;
  final Value<String> data;
  final Value<DateTime> computedAt;
  final Value<DateTime> expiresAt;
  final Value<int> rowid;
  const AnalyticsCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.data = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalyticsCacheCompanion.insert({
    required String cacheKey,
    required String data,
    this.computedAt = const Value.absent(),
    required DateTime expiresAt,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        data = Value(data),
        expiresAt = Value(expiresAt);
  static Insertable<AnalyticsCacheData> custom({
    Expression<String>? cacheKey,
    Expression<String>? data,
    Expression<DateTime>? computedAt,
    Expression<DateTime>? expiresAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (data != null) 'data': data,
      if (computedAt != null) 'computed_at': computedAt,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalyticsCacheCompanion copyWith(
      {Value<String>? cacheKey,
      Value<String>? data,
      Value<DateTime>? computedAt,
      Value<DateTime>? expiresAt,
      Value<int>? rowid}) {
    return AnalyticsCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      data: data ?? this.data,
      computedAt: computedAt ?? this.computedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<DateTime>(computedAt.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('data: $data, ')
          ..write('computedAt: $computedAt, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(Insertable<AppSetting> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory AppSetting.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) => AppSetting(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EntitiesTable entities = $EntitiesTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $RelationshipsTable relationships = $RelationshipsTable(this);
  late final $PatternsTable patterns = $PatternsTable(this);
  late final $EntityStatisticsTable entityStatistics =
      $EntityStatisticsTable(this);
  late final $EmbeddingsTable embeddings = $EmbeddingsTable(this);
  late final $AnalyticsCacheTable analyticsCache = $AnalyticsCacheTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        entities,
        events,
        relationships,
        patterns,
        entityStatistics,
        embeddings,
        analyticsCache,
        appSettings
      ];
}

typedef $$EntitiesTableCreateCompanionBuilder = EntitiesCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<String> tags,
  Value<String> customFields,
  Value<String?> color,
  Value<String?> icon,
  Value<String> status,
  Value<bool> isDecision,
  Value<String?> decisionOptions,
  Value<String?> decisionReasoning,
  Value<int?> decisionConfidence,
  Value<String?> decisionExpectedOutcome,
  Value<String?> decisionActualOutcome,
  Value<DateTime?> decisionReviewDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$EntitiesTableUpdateCompanionBuilder = EntitiesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String> tags,
  Value<String> customFields,
  Value<String?> color,
  Value<String?> icon,
  Value<String> status,
  Value<bool> isDecision,
  Value<String?> decisionOptions,
  Value<String?> decisionReasoning,
  Value<int?> decisionConfidence,
  Value<String?> decisionExpectedOutcome,
  Value<String?> decisionActualOutcome,
  Value<DateTime?> decisionReviewDate,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$EntitiesTableFilterComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customFields => $composableBuilder(
      column: $table.customFields, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDecision => $composableBuilder(
      column: $table.isDecision, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionOptions => $composableBuilder(
      column: $table.decisionOptions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionReasoning => $composableBuilder(
      column: $table.decisionReasoning,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get decisionConfidence => $composableBuilder(
      column: $table.decisionConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionExpectedOutcome => $composableBuilder(
      column: $table.decisionExpectedOutcome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionActualOutcome => $composableBuilder(
      column: $table.decisionActualOutcome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get decisionReviewDate => $composableBuilder(
      column: $table.decisionReviewDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EntitiesTableOrderingComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customFields => $composableBuilder(
      column: $table.customFields,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get color => $composableBuilder(
      column: $table.color, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get icon => $composableBuilder(
      column: $table.icon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDecision => $composableBuilder(
      column: $table.isDecision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionOptions => $composableBuilder(
      column: $table.decisionOptions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionReasoning => $composableBuilder(
      column: $table.decisionReasoning,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get decisionConfidence => $composableBuilder(
      column: $table.decisionConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionExpectedOutcome => $composableBuilder(
      column: $table.decisionExpectedOutcome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionActualOutcome => $composableBuilder(
      column: $table.decisionActualOutcome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get decisionReviewDate => $composableBuilder(
      column: $table.decisionReviewDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EntitiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntitiesTable> {
  $$EntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<String> get customFields => $composableBuilder(
      column: $table.customFields, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<bool> get isDecision => $composableBuilder(
      column: $table.isDecision, builder: (column) => column);

  GeneratedColumn<String> get decisionOptions => $composableBuilder(
      column: $table.decisionOptions, builder: (column) => column);

  GeneratedColumn<String> get decisionReasoning => $composableBuilder(
      column: $table.decisionReasoning, builder: (column) => column);

  GeneratedColumn<int> get decisionConfidence => $composableBuilder(
      column: $table.decisionConfidence, builder: (column) => column);

  GeneratedColumn<String> get decisionExpectedOutcome => $composableBuilder(
      column: $table.decisionExpectedOutcome, builder: (column) => column);

  GeneratedColumn<String> get decisionActualOutcome => $composableBuilder(
      column: $table.decisionActualOutcome, builder: (column) => column);

  GeneratedColumn<DateTime> get decisionReviewDate => $composableBuilder(
      column: $table.decisionReviewDate, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EntitiesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntitiesTable,
    Entity,
    $$EntitiesTableFilterComposer,
    $$EntitiesTableOrderingComposer,
    $$EntitiesTableAnnotationComposer,
    $$EntitiesTableCreateCompanionBuilder,
    $$EntitiesTableUpdateCompanionBuilder,
    (Entity, BaseReferences<_$AppDatabase, $EntitiesTable, Entity>),
    Entity,
    PrefetchHooks Function()> {
  $$EntitiesTableTableManager(_$AppDatabase db, $EntitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> customFields = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isDecision = const Value.absent(),
            Value<String?> decisionOptions = const Value.absent(),
            Value<String?> decisionReasoning = const Value.absent(),
            Value<int?> decisionConfidence = const Value.absent(),
            Value<String?> decisionExpectedOutcome = const Value.absent(),
            Value<String?> decisionActualOutcome = const Value.absent(),
            Value<DateTime?> decisionReviewDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntitiesCompanion(
            id: id,
            name: name,
            description: description,
            tags: tags,
            customFields: customFields,
            color: color,
            icon: icon,
            status: status,
            isDecision: isDecision,
            decisionOptions: decisionOptions,
            decisionReasoning: decisionReasoning,
            decisionConfidence: decisionConfidence,
            decisionExpectedOutcome: decisionExpectedOutcome,
            decisionActualOutcome: decisionActualOutcome,
            decisionReviewDate: decisionReviewDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> description = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<String> customFields = const Value.absent(),
            Value<String?> color = const Value.absent(),
            Value<String?> icon = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<bool> isDecision = const Value.absent(),
            Value<String?> decisionOptions = const Value.absent(),
            Value<String?> decisionReasoning = const Value.absent(),
            Value<int?> decisionConfidence = const Value.absent(),
            Value<String?> decisionExpectedOutcome = const Value.absent(),
            Value<String?> decisionActualOutcome = const Value.absent(),
            Value<DateTime?> decisionReviewDate = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntitiesCompanion.insert(
            id: id,
            name: name,
            description: description,
            tags: tags,
            customFields: customFields,
            color: color,
            icon: icon,
            status: status,
            isDecision: isDecision,
            decisionOptions: decisionOptions,
            decisionReasoning: decisionReasoning,
            decisionConfidence: decisionConfidence,
            decisionExpectedOutcome: decisionExpectedOutcome,
            decisionActualOutcome: decisionActualOutcome,
            decisionReviewDate: decisionReviewDate,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EntitiesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntitiesTable,
    Entity,
    $$EntitiesTableFilterComposer,
    $$EntitiesTableOrderingComposer,
    $$EntitiesTableAnnotationComposer,
    $$EntitiesTableCreateCompanionBuilder,
    $$EntitiesTableUpdateCompanionBuilder,
    (Entity, BaseReferences<_$AppDatabase, $EntitiesTable, Entity>),
    Entity,
    PrefetchHooks Function()>;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String id,
  Value<String?> title,
  required String note,
  Value<String> linkedEntityIds,
  Value<String> attachments,
  Value<String?> voiceNotePath,
  Value<String?> mood,
  Value<int> importance,
  Value<String?> location,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<int?> durationMinutes,
  Value<String> customFields,
  Value<String> tags,
  Value<bool> isDecision,
  Value<String?> decisionOptions,
  Value<String?> decisionReasoning,
  Value<int?> decisionConfidence,
  Value<String?> decisionExpectedOutcome,
  Value<String?> decisionActualOutcome,
  Value<DateTime?> decisionReviewDate,
  Value<DateTime> timestamp,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> id,
  Value<String?> title,
  Value<String> note,
  Value<String> linkedEntityIds,
  Value<String> attachments,
  Value<String?> voiceNotePath,
  Value<String?> mood,
  Value<int> importance,
  Value<String?> location,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<int?> durationMinutes,
  Value<String> customFields,
  Value<String> tags,
  Value<bool> isDecision,
  Value<String?> decisionOptions,
  Value<String?> decisionReasoning,
  Value<int?> decisionConfidence,
  Value<String?> decisionExpectedOutcome,
  Value<String?> decisionActualOutcome,
  Value<DateTime?> decisionReviewDate,
  Value<DateTime> timestamp,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$EventsTableFilterComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get linkedEntityIds => $composableBuilder(
      column: $table.linkedEntityIds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attachments => $composableBuilder(
      column: $table.attachments, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get voiceNotePath => $composableBuilder(
      column: $table.voiceNotePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customFields => $composableBuilder(
      column: $table.customFields, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isDecision => $composableBuilder(
      column: $table.isDecision, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionOptions => $composableBuilder(
      column: $table.decisionOptions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionReasoning => $composableBuilder(
      column: $table.decisionReasoning,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get decisionConfidence => $composableBuilder(
      column: $table.decisionConfidence,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionExpectedOutcome => $composableBuilder(
      column: $table.decisionExpectedOutcome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get decisionActualOutcome => $composableBuilder(
      column: $table.decisionActualOutcome,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get decisionReviewDate => $composableBuilder(
      column: $table.decisionReviewDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$EventsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get linkedEntityIds => $composableBuilder(
      column: $table.linkedEntityIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attachments => $composableBuilder(
      column: $table.attachments, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get voiceNotePath => $composableBuilder(
      column: $table.voiceNotePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mood => $composableBuilder(
      column: $table.mood, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get location => $composableBuilder(
      column: $table.location, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customFields => $composableBuilder(
      column: $table.customFields,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isDecision => $composableBuilder(
      column: $table.isDecision, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionOptions => $composableBuilder(
      column: $table.decisionOptions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionReasoning => $composableBuilder(
      column: $table.decisionReasoning,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get decisionConfidence => $composableBuilder(
      column: $table.decisionConfidence,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionExpectedOutcome => $composableBuilder(
      column: $table.decisionExpectedOutcome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get decisionActualOutcome => $composableBuilder(
      column: $table.decisionActualOutcome,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get decisionReviewDate => $composableBuilder(
      column: $table.decisionReviewDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
      column: $table.timestamp, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get linkedEntityIds => $composableBuilder(
      column: $table.linkedEntityIds, builder: (column) => column);

  GeneratedColumn<String> get attachments => $composableBuilder(
      column: $table.attachments, builder: (column) => column);

  GeneratedColumn<String> get voiceNotePath => $composableBuilder(
      column: $table.voiceNotePath, builder: (column) => column);

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get importance => $composableBuilder(
      column: $table.importance, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
      column: $table.durationMinutes, builder: (column) => column);

  GeneratedColumn<String> get customFields => $composableBuilder(
      column: $table.customFields, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get isDecision => $composableBuilder(
      column: $table.isDecision, builder: (column) => column);

  GeneratedColumn<String> get decisionOptions => $composableBuilder(
      column: $table.decisionOptions, builder: (column) => column);

  GeneratedColumn<String> get decisionReasoning => $composableBuilder(
      column: $table.decisionReasoning, builder: (column) => column);

  GeneratedColumn<int> get decisionConfidence => $composableBuilder(
      column: $table.decisionConfidence, builder: (column) => column);

  GeneratedColumn<String> get decisionExpectedOutcome => $composableBuilder(
      column: $table.decisionExpectedOutcome, builder: (column) => column);

  GeneratedColumn<String> get decisionActualOutcome => $composableBuilder(
      column: $table.decisionActualOutcome, builder: (column) => column);

  GeneratedColumn<DateTime> get decisionReviewDate => $composableBuilder(
      column: $table.decisionReviewDate, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
    Event,
    PrefetchHooks Function()> {
  $$EventsTableTableManager(_$AppDatabase db, $EventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> title = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String> linkedEntityIds = const Value.absent(),
            Value<String> attachments = const Value.absent(),
            Value<String?> voiceNotePath = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<int> importance = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<String> customFields = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<bool> isDecision = const Value.absent(),
            Value<String?> decisionOptions = const Value.absent(),
            Value<String?> decisionReasoning = const Value.absent(),
            Value<int?> decisionConfidence = const Value.absent(),
            Value<String?> decisionExpectedOutcome = const Value.absent(),
            Value<String?> decisionActualOutcome = const Value.absent(),
            Value<DateTime?> decisionReviewDate = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion(
            id: id,
            title: title,
            note: note,
            linkedEntityIds: linkedEntityIds,
            attachments: attachments,
            voiceNotePath: voiceNotePath,
            mood: mood,
            importance: importance,
            location: location,
            latitude: latitude,
            longitude: longitude,
            durationMinutes: durationMinutes,
            customFields: customFields,
            tags: tags,
            isDecision: isDecision,
            decisionOptions: decisionOptions,
            decisionReasoning: decisionReasoning,
            decisionConfidence: decisionConfidence,
            decisionExpectedOutcome: decisionExpectedOutcome,
            decisionActualOutcome: decisionActualOutcome,
            decisionReviewDate: decisionReviewDate,
            timestamp: timestamp,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> title = const Value.absent(),
            required String note,
            Value<String> linkedEntityIds = const Value.absent(),
            Value<String> attachments = const Value.absent(),
            Value<String?> voiceNotePath = const Value.absent(),
            Value<String?> mood = const Value.absent(),
            Value<int> importance = const Value.absent(),
            Value<String?> location = const Value.absent(),
            Value<double?> latitude = const Value.absent(),
            Value<double?> longitude = const Value.absent(),
            Value<int?> durationMinutes = const Value.absent(),
            Value<String> customFields = const Value.absent(),
            Value<String> tags = const Value.absent(),
            Value<bool> isDecision = const Value.absent(),
            Value<String?> decisionOptions = const Value.absent(),
            Value<String?> decisionReasoning = const Value.absent(),
            Value<int?> decisionConfidence = const Value.absent(),
            Value<String?> decisionExpectedOutcome = const Value.absent(),
            Value<String?> decisionActualOutcome = const Value.absent(),
            Value<DateTime?> decisionReviewDate = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EventsCompanion.insert(
            id: id,
            title: title,
            note: note,
            linkedEntityIds: linkedEntityIds,
            attachments: attachments,
            voiceNotePath: voiceNotePath,
            mood: mood,
            importance: importance,
            location: location,
            latitude: latitude,
            longitude: longitude,
            durationMinutes: durationMinutes,
            customFields: customFields,
            tags: tags,
            isDecision: isDecision,
            decisionOptions: decisionOptions,
            decisionReasoning: decisionReasoning,
            decisionConfidence: decisionConfidence,
            decisionExpectedOutcome: decisionExpectedOutcome,
            decisionActualOutcome: decisionActualOutcome,
            decisionReviewDate: decisionReviewDate,
            timestamp: timestamp,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EventsTable,
    Event,
    $$EventsTableFilterComposer,
    $$EventsTableOrderingComposer,
    $$EventsTableAnnotationComposer,
    $$EventsTableCreateCompanionBuilder,
    $$EventsTableUpdateCompanionBuilder,
    (Event, BaseReferences<_$AppDatabase, $EventsTable, Event>),
    Event,
    PrefetchHooks Function()>;
typedef $$RelationshipsTableCreateCompanionBuilder = RelationshipsCompanion
    Function({
  required String id,
  required String fromEntityId,
  required String toEntityId,
  required String relationshipType,
  Value<String?> description,
  Value<double> strength,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$RelationshipsTableUpdateCompanionBuilder = RelationshipsCompanion
    Function({
  Value<String> id,
  Value<String> fromEntityId,
  Value<String> toEntityId,
  Value<String> relationshipType,
  Value<String?> description,
  Value<double> strength,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$RelationshipsTableFilterComposer
    extends Composer<_$AppDatabase, $RelationshipsTable> {
  $$RelationshipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fromEntityId => $composableBuilder(
      column: $table.fromEntityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get toEntityId => $composableBuilder(
      column: $table.toEntityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relationshipType => $composableBuilder(
      column: $table.relationshipType,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get strength => $composableBuilder(
      column: $table.strength, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$RelationshipsTableOrderingComposer
    extends Composer<_$AppDatabase, $RelationshipsTable> {
  $$RelationshipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fromEntityId => $composableBuilder(
      column: $table.fromEntityId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get toEntityId => $composableBuilder(
      column: $table.toEntityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relationshipType => $composableBuilder(
      column: $table.relationshipType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get strength => $composableBuilder(
      column: $table.strength, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$RelationshipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RelationshipsTable> {
  $$RelationshipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fromEntityId => $composableBuilder(
      column: $table.fromEntityId, builder: (column) => column);

  GeneratedColumn<String> get toEntityId => $composableBuilder(
      column: $table.toEntityId, builder: (column) => column);

  GeneratedColumn<String> get relationshipType => $composableBuilder(
      column: $table.relationshipType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<double> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$RelationshipsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $RelationshipsTable,
    Relationship,
    $$RelationshipsTableFilterComposer,
    $$RelationshipsTableOrderingComposer,
    $$RelationshipsTableAnnotationComposer,
    $$RelationshipsTableCreateCompanionBuilder,
    $$RelationshipsTableUpdateCompanionBuilder,
    (
      Relationship,
      BaseReferences<_$AppDatabase, $RelationshipsTable, Relationship>
    ),
    Relationship,
    PrefetchHooks Function()> {
  $$RelationshipsTableTableManager(_$AppDatabase db, $RelationshipsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelationshipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RelationshipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RelationshipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> fromEntityId = const Value.absent(),
            Value<String> toEntityId = const Value.absent(),
            Value<String> relationshipType = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<double> strength = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RelationshipsCompanion(
            id: id,
            fromEntityId: fromEntityId,
            toEntityId: toEntityId,
            relationshipType: relationshipType,
            description: description,
            strength: strength,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String fromEntityId,
            required String toEntityId,
            required String relationshipType,
            Value<String?> description = const Value.absent(),
            Value<double> strength = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              RelationshipsCompanion.insert(
            id: id,
            fromEntityId: fromEntityId,
            toEntityId: toEntityId,
            relationshipType: relationshipType,
            description: description,
            strength: strength,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$RelationshipsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $RelationshipsTable,
    Relationship,
    $$RelationshipsTableFilterComposer,
    $$RelationshipsTableOrderingComposer,
    $$RelationshipsTableAnnotationComposer,
    $$RelationshipsTableCreateCompanionBuilder,
    $$RelationshipsTableUpdateCompanionBuilder,
    (
      Relationship,
      BaseReferences<_$AppDatabase, $RelationshipsTable, Relationship>
    ),
    Relationship,
    PrefetchHooks Function()>;
typedef $$PatternsTableCreateCompanionBuilder = PatternsCompanion Function({
  required String id,
  required String title,
  required String description,
  required String patternType,
  Value<String> relatedEntityIds,
  Value<String> evidence,
  Value<double> confidence,
  Value<int> occurrences,
  Value<DateTime> firstSeen,
  Value<DateTime> lastSeen,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$PatternsTableUpdateCompanionBuilder = PatternsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> description,
  Value<String> patternType,
  Value<String> relatedEntityIds,
  Value<String> evidence,
  Value<double> confidence,
  Value<int> occurrences,
  Value<DateTime> firstSeen,
  Value<DateTime> lastSeen,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PatternsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get patternType => $composableBuilder(
      column: $table.patternType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get relatedEntityIds => $composableBuilder(
      column: $table.relatedEntityIds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get occurrences => $composableBuilder(
      column: $table.occurrences, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstSeen => $composableBuilder(
      column: $table.firstSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PatternsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get patternType => $composableBuilder(
      column: $table.patternType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get relatedEntityIds => $composableBuilder(
      column: $table.relatedEntityIds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get evidence => $composableBuilder(
      column: $table.evidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get occurrences => $composableBuilder(
      column: $table.occurrences, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstSeen => $composableBuilder(
      column: $table.firstSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PatternsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternsTable> {
  $$PatternsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get patternType => $composableBuilder(
      column: $table.patternType, builder: (column) => column);

  GeneratedColumn<String> get relatedEntityIds => $composableBuilder(
      column: $table.relatedEntityIds, builder: (column) => column);

  GeneratedColumn<String> get evidence =>
      $composableBuilder(column: $table.evidence, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
      column: $table.confidence, builder: (column) => column);

  GeneratedColumn<int> get occurrences => $composableBuilder(
      column: $table.occurrences, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PatternsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PatternsTable,
    Pattern,
    $$PatternsTableFilterComposer,
    $$PatternsTableOrderingComposer,
    $$PatternsTableAnnotationComposer,
    $$PatternsTableCreateCompanionBuilder,
    $$PatternsTableUpdateCompanionBuilder,
    (Pattern, BaseReferences<_$AppDatabase, $PatternsTable, Pattern>),
    Pattern,
    PrefetchHooks Function()> {
  $$PatternsTableTableManager(_$AppDatabase db, $PatternsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> description = const Value.absent(),
            Value<String> patternType = const Value.absent(),
            Value<String> relatedEntityIds = const Value.absent(),
            Value<String> evidence = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<int> occurrences = const Value.absent(),
            Value<DateTime> firstSeen = const Value.absent(),
            Value<DateTime> lastSeen = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatternsCompanion(
            id: id,
            title: title,
            description: description,
            patternType: patternType,
            relatedEntityIds: relatedEntityIds,
            evidence: evidence,
            confidence: confidence,
            occurrences: occurrences,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String description,
            required String patternType,
            Value<String> relatedEntityIds = const Value.absent(),
            Value<String> evidence = const Value.absent(),
            Value<double> confidence = const Value.absent(),
            Value<int> occurrences = const Value.absent(),
            Value<DateTime> firstSeen = const Value.absent(),
            Value<DateTime> lastSeen = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PatternsCompanion.insert(
            id: id,
            title: title,
            description: description,
            patternType: patternType,
            relatedEntityIds: relatedEntityIds,
            evidence: evidence,
            confidence: confidence,
            occurrences: occurrences,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PatternsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PatternsTable,
    Pattern,
    $$PatternsTableFilterComposer,
    $$PatternsTableOrderingComposer,
    $$PatternsTableAnnotationComposer,
    $$PatternsTableCreateCompanionBuilder,
    $$PatternsTableUpdateCompanionBuilder,
    (Pattern, BaseReferences<_$AppDatabase, $PatternsTable, Pattern>),
    Pattern,
    PrefetchHooks Function()>;
typedef $$EntityStatisticsTableCreateCompanionBuilder
    = EntityStatisticsCompanion Function({
  required String entityId,
  Value<int> totalEvents,
  Value<int> totalDecisions,
  Value<double> avgMoodScore,
  Value<double> avgImportance,
  Value<String> moodDistribution,
  Value<String> monthlyActivity,
  Value<DateTime?> lastEventAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});
typedef $$EntityStatisticsTableUpdateCompanionBuilder
    = EntityStatisticsCompanion Function({
  Value<String> entityId,
  Value<int> totalEvents,
  Value<int> totalDecisions,
  Value<double> avgMoodScore,
  Value<double> avgImportance,
  Value<String> moodDistribution,
  Value<String> monthlyActivity,
  Value<DateTime?> lastEventAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$EntityStatisticsTableFilterComposer
    extends Composer<_$AppDatabase, $EntityStatisticsTable> {
  $$EntityStatisticsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalEvents => $composableBuilder(
      column: $table.totalEvents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalDecisions => $composableBuilder(
      column: $table.totalDecisions,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgMoodScore => $composableBuilder(
      column: $table.avgMoodScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get avgImportance => $composableBuilder(
      column: $table.avgImportance, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moodDistribution => $composableBuilder(
      column: $table.moodDistribution,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get monthlyActivity => $composableBuilder(
      column: $table.monthlyActivity,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastEventAt => $composableBuilder(
      column: $table.lastEventAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EntityStatisticsTableOrderingComposer
    extends Composer<_$AppDatabase, $EntityStatisticsTable> {
  $$EntityStatisticsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalEvents => $composableBuilder(
      column: $table.totalEvents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalDecisions => $composableBuilder(
      column: $table.totalDecisions,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgMoodScore => $composableBuilder(
      column: $table.avgMoodScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get avgImportance => $composableBuilder(
      column: $table.avgImportance,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moodDistribution => $composableBuilder(
      column: $table.moodDistribution,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get monthlyActivity => $composableBuilder(
      column: $table.monthlyActivity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastEventAt => $composableBuilder(
      column: $table.lastEventAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EntityStatisticsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EntityStatisticsTable> {
  $$EntityStatisticsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<int> get totalEvents => $composableBuilder(
      column: $table.totalEvents, builder: (column) => column);

  GeneratedColumn<int> get totalDecisions => $composableBuilder(
      column: $table.totalDecisions, builder: (column) => column);

  GeneratedColumn<double> get avgMoodScore => $composableBuilder(
      column: $table.avgMoodScore, builder: (column) => column);

  GeneratedColumn<double> get avgImportance => $composableBuilder(
      column: $table.avgImportance, builder: (column) => column);

  GeneratedColumn<String> get moodDistribution => $composableBuilder(
      column: $table.moodDistribution, builder: (column) => column);

  GeneratedColumn<String> get monthlyActivity => $composableBuilder(
      column: $table.monthlyActivity, builder: (column) => column);

  GeneratedColumn<DateTime> get lastEventAt => $composableBuilder(
      column: $table.lastEventAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EntityStatisticsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EntityStatisticsTable,
    EntityStatistic,
    $$EntityStatisticsTableFilterComposer,
    $$EntityStatisticsTableOrderingComposer,
    $$EntityStatisticsTableAnnotationComposer,
    $$EntityStatisticsTableCreateCompanionBuilder,
    $$EntityStatisticsTableUpdateCompanionBuilder,
    (
      EntityStatistic,
      BaseReferences<_$AppDatabase, $EntityStatisticsTable, EntityStatistic>
    ),
    EntityStatistic,
    PrefetchHooks Function()> {
  $$EntityStatisticsTableTableManager(
      _$AppDatabase db, $EntityStatisticsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntityStatisticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntityStatisticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntityStatisticsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> entityId = const Value.absent(),
            Value<int> totalEvents = const Value.absent(),
            Value<int> totalDecisions = const Value.absent(),
            Value<double> avgMoodScore = const Value.absent(),
            Value<double> avgImportance = const Value.absent(),
            Value<String> moodDistribution = const Value.absent(),
            Value<String> monthlyActivity = const Value.absent(),
            Value<DateTime?> lastEventAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntityStatisticsCompanion(
            entityId: entityId,
            totalEvents: totalEvents,
            totalDecisions: totalDecisions,
            avgMoodScore: avgMoodScore,
            avgImportance: avgImportance,
            moodDistribution: moodDistribution,
            monthlyActivity: monthlyActivity,
            lastEventAt: lastEventAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String entityId,
            Value<int> totalEvents = const Value.absent(),
            Value<int> totalDecisions = const Value.absent(),
            Value<double> avgMoodScore = const Value.absent(),
            Value<double> avgImportance = const Value.absent(),
            Value<String> moodDistribution = const Value.absent(),
            Value<String> monthlyActivity = const Value.absent(),
            Value<DateTime?> lastEventAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EntityStatisticsCompanion.insert(
            entityId: entityId,
            totalEvents: totalEvents,
            totalDecisions: totalDecisions,
            avgMoodScore: avgMoodScore,
            avgImportance: avgImportance,
            moodDistribution: moodDistribution,
            monthlyActivity: monthlyActivity,
            lastEventAt: lastEventAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EntityStatisticsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EntityStatisticsTable,
    EntityStatistic,
    $$EntityStatisticsTableFilterComposer,
    $$EntityStatisticsTableOrderingComposer,
    $$EntityStatisticsTableAnnotationComposer,
    $$EntityStatisticsTableCreateCompanionBuilder,
    $$EntityStatisticsTableUpdateCompanionBuilder,
    (
      EntityStatistic,
      BaseReferences<_$AppDatabase, $EntityStatisticsTable, EntityStatistic>
    ),
    EntityStatistic,
    PrefetchHooks Function()>;
typedef $$EmbeddingsTableCreateCompanionBuilder = EmbeddingsCompanion Function({
  required String id,
  required String sourceType,
  required String sourceId,
  required String embeddingJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});
typedef $$EmbeddingsTableUpdateCompanionBuilder = EmbeddingsCompanion Function({
  Value<String> id,
  Value<String> sourceType,
  Value<String> sourceId,
  Value<String> embeddingJson,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$EmbeddingsTableFilterComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get embeddingJson => $composableBuilder(
      column: $table.embeddingJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$EmbeddingsTableOrderingComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceId => $composableBuilder(
      column: $table.sourceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get embeddingJson => $composableBuilder(
      column: $table.embeddingJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$EmbeddingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmbeddingsTable> {
  $$EmbeddingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<String> get embeddingJson => $composableBuilder(
      column: $table.embeddingJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$EmbeddingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmbeddingsTable,
    Embedding,
    $$EmbeddingsTableFilterComposer,
    $$EmbeddingsTableOrderingComposer,
    $$EmbeddingsTableAnnotationComposer,
    $$EmbeddingsTableCreateCompanionBuilder,
    $$EmbeddingsTableUpdateCompanionBuilder,
    (Embedding, BaseReferences<_$AppDatabase, $EmbeddingsTable, Embedding>),
    Embedding,
    PrefetchHooks Function()> {
  $$EmbeddingsTableTableManager(_$AppDatabase db, $EmbeddingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmbeddingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmbeddingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmbeddingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<String> sourceId = const Value.absent(),
            Value<String> embeddingJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmbeddingsCompanion(
            id: id,
            sourceType: sourceType,
            sourceId: sourceId,
            embeddingJson: embeddingJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String sourceType,
            required String sourceId,
            required String embeddingJson,
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmbeddingsCompanion.insert(
            id: id,
            sourceType: sourceType,
            sourceId: sourceId,
            embeddingJson: embeddingJson,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmbeddingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmbeddingsTable,
    Embedding,
    $$EmbeddingsTableFilterComposer,
    $$EmbeddingsTableOrderingComposer,
    $$EmbeddingsTableAnnotationComposer,
    $$EmbeddingsTableCreateCompanionBuilder,
    $$EmbeddingsTableUpdateCompanionBuilder,
    (Embedding, BaseReferences<_$AppDatabase, $EmbeddingsTable, Embedding>),
    Embedding,
    PrefetchHooks Function()>;
typedef $$AnalyticsCacheTableCreateCompanionBuilder = AnalyticsCacheCompanion
    Function({
  required String cacheKey,
  required String data,
  Value<DateTime> computedAt,
  required DateTime expiresAt,
  Value<int> rowid,
});
typedef $$AnalyticsCacheTableUpdateCompanionBuilder = AnalyticsCacheCompanion
    Function({
  Value<String> cacheKey,
  Value<String> data,
  Value<DateTime> computedAt,
  Value<DateTime> expiresAt,
  Value<int> rowid,
});

class $$AnalyticsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $AnalyticsCacheTable> {
  $$AnalyticsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));
}

class $$AnalyticsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalyticsCacheTable> {
  $$AnalyticsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get cacheKey => $composableBuilder(
      column: $table.cacheKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));
}

class $$AnalyticsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalyticsCacheTable> {
  $$AnalyticsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get cacheKey =>
      $composableBuilder(column: $table.cacheKey, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);
}

class $$AnalyticsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnalyticsCacheTable,
    AnalyticsCacheData,
    $$AnalyticsCacheTableFilterComposer,
    $$AnalyticsCacheTableOrderingComposer,
    $$AnalyticsCacheTableAnnotationComposer,
    $$AnalyticsCacheTableCreateCompanionBuilder,
    $$AnalyticsCacheTableUpdateCompanionBuilder,
    (
      AnalyticsCacheData,
      BaseReferences<_$AppDatabase, $AnalyticsCacheTable, AnalyticsCacheData>
    ),
    AnalyticsCacheData,
    PrefetchHooks Function()> {
  $$AnalyticsCacheTableTableManager(
      _$AppDatabase db, $AnalyticsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalyticsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalyticsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnalyticsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<DateTime> computedAt = const Value.absent(),
            Value<DateTime> expiresAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalyticsCacheCompanion(
            cacheKey: cacheKey,
            data: data,
            computedAt: computedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String data,
            Value<DateTime> computedAt = const Value.absent(),
            required DateTime expiresAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              AnalyticsCacheCompanion.insert(
            cacheKey: cacheKey,
            data: data,
            computedAt: computedAt,
            expiresAt: expiresAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AnalyticsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AnalyticsCacheTable,
    AnalyticsCacheData,
    $$AnalyticsCacheTableFilterComposer,
    $$AnalyticsCacheTableOrderingComposer,
    $$AnalyticsCacheTableAnnotationComposer,
    $$AnalyticsCacheTableCreateCompanionBuilder,
    $$AnalyticsCacheTableUpdateCompanionBuilder,
    (
      AnalyticsCacheData,
      BaseReferences<_$AppDatabase, $AnalyticsCacheTable, AnalyticsCacheData>
    ),
    AnalyticsCacheData,
    PrefetchHooks Function()>;
typedef $$AppSettingsTableCreateCompanionBuilder = AppSettingsCompanion
    Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$AppSettingsTableUpdateCompanionBuilder = AppSettingsCompanion
    Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
      column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()> {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              AppSettingsCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$AppSettingsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $AppSettingsTable,
    AppSetting,
    $$AppSettingsTableFilterComposer,
    $$AppSettingsTableOrderingComposer,
    $$AppSettingsTableAnnotationComposer,
    $$AppSettingsTableCreateCompanionBuilder,
    $$AppSettingsTableUpdateCompanionBuilder,
    (AppSetting, BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>),
    AppSetting,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db, _db.entities);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$RelationshipsTableTableManager get relationships =>
      $$RelationshipsTableTableManager(_db, _db.relationships);
  $$PatternsTableTableManager get patterns =>
      $$PatternsTableTableManager(_db, _db.patterns);
  $$EntityStatisticsTableTableManager get entityStatistics =>
      $$EntityStatisticsTableTableManager(_db, _db.entityStatistics);
  $$EmbeddingsTableTableManager get embeddings =>
      $$EmbeddingsTableTableManager(_db, _db.embeddings);
  $$AnalyticsCacheTableTableManager get analyticsCache =>
      $$AnalyticsCacheTableTableManager(_db, _db.analyticsCache);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
