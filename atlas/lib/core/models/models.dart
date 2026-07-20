import 'dart:convert';

// ── Attachment Model ──────────────────────────────────────────────────────────

enum AttachmentType { image, video, audio, pdf, document, other }

class Attachment {
  final String id;
  final String path;
  final AttachmentType type;
  final String? name;
  final int? sizeBytes;

  const Attachment({
    required this.id,
    required this.path,
    required this.type,
    this.name,
    this.sizeBytes,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'],
        path: json['path'],
        type: AttachmentType.values.byName(json['type'] ?? 'other'),
        name: json['name'],
        sizeBytes: json['sizeBytes'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'type': type.name,
        'name': name,
        'sizeBytes': sizeBytes,
      };

  static List<Attachment> listFromJson(String json) {
    final list = jsonDecode(json) as List;
    return list.map((e) => Attachment.fromJson(e)).toList();
  }

  static String listToJson(List<Attachment> attachments) =>
      jsonEncode(attachments.map((a) => a.toJson()).toList());
}

// ── Custom Field ──────────────────────────────────────────────────────────────

class CustomField {
  final String key;
  final String value;
  final String type; // text, number, date, boolean, url

  const CustomField({required this.key, required this.value, required this.type});

  factory CustomField.fromJson(Map<String, dynamic> json) =>
      CustomField(key: json['key'], value: json['value'], type: json['type'] ?? 'text');

  Map<String, dynamic> toJson() => {'key': key, 'value': value, 'type': type};
}

// ── Mood ──────────────────────────────────────────────────────────────────────

enum Mood { happy, excited, neutral, stressed, sad, angry, anxious, calm }

extension MoodExtension on Mood {
  String get emoji {
    switch (this) {
      case Mood.happy: return '😊';
      case Mood.excited: return '🤩';
      case Mood.neutral: return '😐';
      case Mood.stressed: return '😰';
      case Mood.sad: return '😢';
      case Mood.angry: return '😠';
      case Mood.anxious: return '😟';
      case Mood.calm: return '😌';
    }
  }

  double get score {
    switch (this) {
      case Mood.excited: return 1.0;
      case Mood.happy: return 0.8;
      case Mood.calm: return 0.6;
      case Mood.neutral: return 0.5;
      case Mood.anxious: return 0.35;
      case Mood.stressed: return 0.25;
      case Mood.sad: return 0.2;
      case Mood.angry: return 0.1;
    }
  }
}

// ── Analytics DSL ─────────────────────────────────────────────────────────────

class AnalyticsPlan {
  final String intent; // count, trend, compare, distribution, timeline
  final String? entityId;
  final String? metric; // events, mood, importance, decisions
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? groupBy; // day, week, month, entity
  final int? limit;

  const AnalyticsPlan({
    required this.intent,
    this.entityId,
    this.metric,
    this.fromDate,
    this.toDate,
    this.groupBy,
    this.limit,
  });

  factory AnalyticsPlan.fromJson(Map<String, dynamic> json) => AnalyticsPlan(
        intent: json['intent'] ?? 'count',
        entityId: json['entityId'],
        metric: json['metric'],
        fromDate: json['fromDate'] != null ? DateTime.parse(json['fromDate']) : null,
        toDate: json['toDate'] != null ? DateTime.parse(json['toDate']) : null,
        groupBy: json['groupBy'],
        limit: json['limit'],
      );
}

// ── Evidence Package ──────────────────────────────────────────────────────────

class EvidencePackage {
  final List<String> eventIds;
  final List<String> entityIds;
  final List<String> patternIds;
  final Map<String, dynamic> statistics;
  final List<String> similarEventIds;
  final String query;

  const EvidencePackage({
    required this.eventIds,
    required this.entityIds,
    required this.patternIds,
    required this.statistics,
    required this.similarEventIds,
    required this.query,
  });
}

// ── Decision Review ───────────────────────────────────────────────────────────

class DecisionReview {
  final String sourceId; // entity or event id
  final String sourceType; // 'entity' or 'event'
  final String decisionTitle;
  final String? expectedOutcome;
  final String? actualOutcome;
  final DateTime? reviewDate;
  final bool isOverdue;

  const DecisionReview({
    required this.sourceId,
    required this.sourceType,
    required this.decisionTitle,
    this.expectedOutcome,
    this.actualOutcome,
    this.reviewDate,
    required this.isOverdue,
  });
}
