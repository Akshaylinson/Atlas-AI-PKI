import 'dart:convert';

import '../database/app_database.dart';

class PatternAiLabel {
  final String patternId;
  final String relationshipLabel;
  final double confidence;
  final String reason;

  const PatternAiLabel({
    required this.patternId,
    required this.relationshipLabel,
    required this.confidence,
    required this.reason,
  });

  factory PatternAiLabel.fromJson(Map<String, dynamic> json) {
    return PatternAiLabel(
      patternId: json['patternId'] as String? ?? '',
      relationshipLabel: json['relationshipLabel'] as String? ?? 'unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'patternId': patternId,
        'relationshipLabel': relationshipLabel,
        'confidence': confidence,
        'reason': reason,
      };
}

class PatternAiRun {
  final String id;
  final DateTime timestamp;
  final String backend;
  final String summary;
  final List<PatternAiLabel> labels;

  const PatternAiRun({
    required this.id,
    required this.timestamp,
    required this.backend,
    required this.summary,
    required this.labels,
  });

  factory PatternAiRun.fromJson(Map<String, dynamic> json) {
    return PatternAiRun(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      backend: json['backend'] as String? ?? 'unknown',
      summary: json['summary'] as String? ?? '',
      labels: ((json['labels'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) =>
              PatternAiLabel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'backend': backend,
        'summary': summary,
        'labels': labels.map((label) => label.toJson()).toList(),
      };
}

class PatternAiAnalysis {
  final String summary;
  final List<PatternAiLabel> labels;

  const PatternAiAnalysis({
    required this.summary,
    required this.labels,
  });
}

class PatternAiService {
  static const String historySettingKey = 'pattern_ai_history';

  String buildPrompt({
    required List<Pattern> patterns,
    required List<Event> recentEvents,
    required List<Relationship> relationships,
  }) {
    final patternPayload = patterns.map((pattern) {
      final relatedIds =
          List<String>.from(jsonDecode(pattern.relatedEntityIds));
      final evidence = List<String>.from(jsonDecode(pattern.evidence));
      return {
        'id': pattern.id,
        'title': pattern.title,
        'description': pattern.description,
        'patternType': pattern.patternType,
        'confidence': pattern.confidence,
        'occurrences': pattern.occurrences,
        'relatedEntityIds': relatedIds,
        'evidenceCount': evidence.length,
      };
    }).toList();

    final relationshipPayload = relationships.take(40).map((relationship) {
      return {
        'fromEntityId': relationship.fromEntityId,
        'toEntityId': relationship.toEntityId,
        'relationshipType': relationship.relationshipType,
        'description': relationship.description,
        'strength': relationship.strength,
      };
    }).toList();

    final recentPayload = recentEvents.take(20).map((event) {
      return {
        'id': event.id,
        'title': event.title,
        'note': event.note,
        'mood': event.mood,
        'timestamp': event.timestamp.toIso8601String(),
        'linkedEntityIds': List<String>.from(jsonDecode(event.linkedEntityIds)),
      };
    }).toList();

    return '''
You are Atlas Pattern Intelligence.
Analyze the discovered patterns and infer the underlying relationship label for each pattern.
Use the existing automatic pattern discovery as the source of truth, then add an AI label.

Return JSON only in this exact shape:
{
  "summary": "short overall summary",
  "labels": [
    {
      "patternId": "exact pattern id",
      "relationshipLabel": "personal|professional|operational|behavioral|mood|transactional|mixed|unknown",
      "confidence": 0.0,
      "reason": "short reason"
    }
  ]
}

Rules:
- Use the patternId exactly as provided.
- Keep the reason short and direct.
- Do not include markdown, code fences, or extra commentary.
- If a pattern is unclear, use relationshipLabel "unknown".

Patterns:
${const JsonEncoder.withIndent('  ').convert(patternPayload)}

Relationships:
${const JsonEncoder.withIndent('  ').convert(relationshipPayload)}

Recent events:
${const JsonEncoder.withIndent('  ').convert(recentPayload)}
''';
  }

  PatternAiAnalysis parseAnalysis(String response, List<Pattern> patterns) {
    final decoded = _decodeJsonObject(response);
    if (decoded is Map<String, dynamic>) {
      final labels = ((decoded['labels'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) =>
              PatternAiLabel.fromJson(Map<String, dynamic>.from(item)))
          .where((label) => label.patternId.isNotEmpty)
          .toList();
      final summary = decoded['summary'] as String? ?? '';
      return PatternAiAnalysis(
          summary: summary, labels: _fillMissingLabels(labels, patterns));
    }

    return PatternAiAnalysis(
      summary: response.trim(),
      labels: _fillMissingLabels(const [], patterns),
    );
  }

  List<PatternAiLabel> _fillMissingLabels(
      List<PatternAiLabel> labels, List<Pattern> patterns) {
    final byId = {for (final label in labels) label.patternId: label};
    return patterns
        .map(
          (pattern) =>
              byId[pattern.id] ??
              PatternAiLabel(
                patternId: pattern.id,
                relationshipLabel: 'unknown',
                confidence: 0.0,
                reason: 'No AI label returned.',
              ),
        )
        .toList();
  }

  dynamic _decodeJsonObject(String response) {
    final trimmed = response.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return null;
    }
    final jsonSlice = trimmed.substring(start, end + 1);
    try {
      return jsonDecode(jsonSlice);
    } catch (_) {
      return null;
    }
  }
}
