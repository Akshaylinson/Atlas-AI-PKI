import 'dart:convert';
import '../database/app_database.dart';
import '../models/models.dart';

/// Adaptive Analytics Engine
/// Converts an AnalyticsPlan (from AI or user) into database queries.
class AnalyticsEngine {
  final AppDatabase _db;

  AnalyticsEngine(this._db);

  Future<Map<String, dynamic>> execute(AnalyticsPlan plan) async {
    switch (plan.intent) {
      case 'count':
        return _executeCount(plan);
      case 'trend':
        return _executeTrend(plan);
      case 'distribution':
        return _executeDistribution(plan);
      case 'timeline':
        return _executeTimeline(plan);
      case 'compare':
        return _executeCompare(plan);
      case 'decision_review':
        return _executeDecisionReview(plan);
      default:
        return _executeCount(plan);
    }
  }

  Future<Map<String, dynamic>> _executeCount(AnalyticsPlan plan) async {
    if (plan.entityId != null) {
      final stats = await _db.getStatisticsForEntity(plan.entityId!);
      return {
        'intent': 'count',
        'entityId': plan.entityId,
        'totalEvents': stats?.totalEvents ?? 0,
        'totalDecisions': stats?.totalDecisions ?? 0,
        'lastActivity': stats?.lastEventAt?.toIso8601String(),
      };
    }
    final totalEvents = await _db.getTotalEventCount();
    final totalEntities = await _db.getTotalEntityCount();
    return {
      'intent': 'count',
      'totalEvents': totalEvents,
      'totalEntities': totalEntities,
    };
  }

  Future<Map<String, dynamic>> _executeTrend(AnalyticsPlan plan) async {
    List<Event> events;
    if (plan.entityId != null) {
      events = await _db.getEventsForEntity(plan.entityId!);
    } else {
      events = await _db.getAllEvents();
    }

    if (plan.fromDate != null) {
      events = events.where((e) => e.timestamp.isAfter(plan.fromDate!)).toList();
    }
    if (plan.toDate != null) {
      events = events.where((e) => e.timestamp.isBefore(plan.toDate!)).toList();
    }

    final groupBy = plan.groupBy ?? 'month';
    final grouped = <String, int>{};
    for (final e in events) {
      final key = _groupKey(e.timestamp, groupBy);
      grouped[key] = (grouped[key] ?? 0) + 1;
    }

    final sortedKeys = grouped.keys.toList()..sort();
    return {
      'intent': 'trend',
      'groupBy': groupBy,
      'data': {for (final k in sortedKeys) k: grouped[k]},
    };
  }

  Future<Map<String, dynamic>> _executeDistribution(AnalyticsPlan plan) async {
    if (plan.metric == 'mood') {
      final dist = await _db.getMoodDistribution();
      return {'intent': 'distribution', 'metric': 'mood', 'data': dist};
    }
    if (plan.metric == 'importance') {
      final events = await _db.getAllEvents();
      final dist = <String, int>{};
      for (final e in events) {
        final key = e.importance.toString();
        dist[key] = (dist[key] ?? 0) + 1;
      }
      return {'intent': 'distribution', 'metric': 'importance', 'data': dist};
    }
    return {'intent': 'distribution', 'data': {}};
  }

  Future<Map<String, dynamic>> _executeTimeline(AnalyticsPlan plan) async {
    List<Event> events;
    if (plan.entityId != null) {
      events = await _db.getEventsForEntity(plan.entityId!);
    } else {
      events = await _db.getAllEvents();
    }

    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (plan.limit != null) events = events.take(plan.limit!).toList();

    return {
      'intent': 'timeline',
      'events': events
          .map((e) => {
                'id': e.id,
                'note': e.note.length > 100 ? '${e.note.substring(0, 100)}...' : e.note,
                'timestamp': e.timestamp.toIso8601String(),
                'mood': e.mood,
                'importance': e.importance,
              })
          .toList(),
    };
  }

  Future<Map<String, dynamic>> _executeCompare(AnalyticsPlan plan) async {
    final allEntities = await _db.getAllEntities();
    final comparisons = <Map<String, dynamic>>[];

    for (final entity in allEntities.take(plan.limit ?? 5)) {
      final stats = await _db.getStatisticsForEntity(entity.id);
      comparisons.add({
        'entityId': entity.id,
        'entityName': entity.name,
        'totalEvents': stats?.totalEvents ?? 0,
        'avgMoodScore': stats?.avgMoodScore ?? 0.0,
        'avgImportance': stats?.avgImportance ?? 0.0,
      });
    }

    return {'intent': 'compare', 'entities': comparisons};
  }

  Future<Map<String, dynamic>> _executeDecisionReview(AnalyticsPlan plan) async {
    final decisionEvents = await _db.getDecisionEvents();
    final decisionEntities = await _db.getDecisionEntities();
    final now = DateTime.now();

    final overdue = <Map<String, dynamic>>[];
    final pending = <Map<String, dynamic>>[];

    for (final e in decisionEvents) {
      if (e.decisionReviewDate != null) {
        final item = {
          'id': e.id,
          'type': 'event',
          'title': e.note.length > 60 ? '${e.note.substring(0, 60)}...' : e.note,
          'reviewDate': e.decisionReviewDate!.toIso8601String(),
          'expectedOutcome': e.decisionExpectedOutcome,
          'actualOutcome': e.decisionActualOutcome,
        };
        if (e.decisionReviewDate!.isBefore(now) && e.decisionActualOutcome == null) {
          overdue.add(item);
        } else {
          pending.add(item);
        }
      }
    }

    for (final entity in decisionEntities) {
      if (entity.decisionReviewDate != null) {
        final item = {
          'id': entity.id,
          'type': 'entity',
          'title': entity.name,
          'reviewDate': entity.decisionReviewDate!.toIso8601String(),
          'expectedOutcome': entity.decisionExpectedOutcome,
          'actualOutcome': entity.decisionActualOutcome,
        };
        if (entity.decisionReviewDate!.isBefore(now) && entity.decisionActualOutcome == null) {
          overdue.add(item);
        } else {
          pending.add(item);
        }
      }
    }

    return {
      'intent': 'decision_review',
      'overdue': overdue,
      'pending': pending,
    };
  }

  String _groupKey(DateTime dt, String groupBy) {
    switch (groupBy) {
      case 'day':
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      case 'week':
        final weekNum = ((dt.difference(DateTime(dt.year, 1, 1)).inDays) / 7).floor();
        return '${dt.year}-W${weekNum.toString().padLeft(2, '0')}';
      case 'month':
      default:
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    }
  }
}
