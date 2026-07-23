import '../database/app_database.dart';
import '../models/models.dart';
import 'retrieval_engine.dart';
import 'model_loader.dart';

/// Local AI layer.
/// The assistant responds from retrieved evidence and keeps answers grounded.
class GemmaService {
  final AppDatabase _db;
  final RetrievalEngine _retrieval;
  final ModelLoader _loader;

  GemmaService(this._db)
      : _retrieval = RetrievalEngine(_db),
        _loader = ModelLoader();

  bool get isModelLoaded => _loader.isLoaded;
  bool get isModelLoading => _loader.isLoading;
  String? get modelLoadError => _loader.loadError;

  /// Load the Gemma model from internal storage install directory.
  Future<bool> loadModel(String installDir) => _loader.load(installDir);

  /// Main query entry point.
  Future<AIResponse> query(String userQuestion) async {
    final evidence = await _retrieval.retrieve(userQuestion);
    final context = await _buildContext(evidence);

    // Keep the assistant on the fast Dart path to avoid native model stalls
    // that can trigger ANRs on Android devices.
    final responseText = _buildEvidenceBasedResponse(context);

    return AIResponse(
      question: userQuestion,
      answer: responseText,
      evidencePackage: evidence,
      context: context,
      timestamp: DateTime.now(),
    );
  }

  Future<Map<String, dynamic>> _buildContext(EvidencePackage evidence) async {
    final context = <String, dynamic>{};

    final events = <Map<String, dynamic>>[];
    for (final eventId in evidence.eventIds.take(10)) {
      final event = await _db.getEventById(eventId);
      if (event != null) {
        events.add({
          'note': event.note,
          'timestamp': event.timestamp.toIso8601String(),
          'mood': event.mood,
          'importance': event.importance,
        });
      }
    }
    context['events'] = events;

    final entities = <Map<String, dynamic>>[];
    for (final entityId in evidence.entityIds.take(5)) {
      final entity = await _db.getEntityById(entityId);
      if (entity != null) {
        final stats = await _db.getStatisticsForEntity(entityId);
        entities.add({
          'name': entity.name,
          'description': entity.description,
          'totalEvents': stats?.totalEvents ?? 0,
          'avgMood': stats?.avgMoodScore ?? 0.0,
        });
      }
    }
    context['entities'] = entities;

    final patterns = <Map<String, dynamic>>[];
    final allPatterns = await _db.getAllPatterns();
    for (final patternId in evidence.patternIds.take(5)) {
      final pattern = allPatterns.where((p) => p.id == patternId).firstOrNull;
      if (pattern != null) {
        patterns.add({
          'title': pattern.title,
          'description': pattern.description,
          'confidence': pattern.confidence,
          'occurrences': pattern.occurrences,
        });
      }
    }
    context['patterns'] = patterns;
    context['statistics'] = evidence.statistics;

    return context;
  }

  String _buildEvidenceBasedResponse(Map<String, dynamic> context) {
    final sb = StringBuffer();
    sb.writeln('Based on your recorded data:');
    sb.writeln('');

    final events = context['events'] as List? ?? [];
    final entities = context['entities'] as List? ?? [];
    final patterns = context['patterns'] as List? ?? [];
    final stats = context['statistics'] as Map? ?? {};

    if (events.isEmpty && entities.isEmpty) {
      return 'No relevant data found for your query. Try recording more events related to this topic.';
    }

    if (entities.isNotEmpty) {
      sb.writeln('Relevant Entities (${entities.length})');
      for (final e in entities) {
        sb.writeln('- ${e['name']}: ${e['totalEvents']} events recorded');
      }
      sb.writeln('');
    }

    if (events.isNotEmpty) {
      sb.writeln('Recent Relevant Events (${events.length})');
      for (final e in events.take(5)) {
        final note = e['note'] as String? ?? '';
        final ts = DateTime.tryParse(e['timestamp']?.toString() ?? '');
        final dateStr = ts != null ? '${ts.day}/${ts.month}/${ts.year}' : '';
        final preview = note.length > 80 ? '${note.substring(0, 80)}...' : note;
        sb.writeln('- [$dateStr] $preview');
      }
      sb.writeln('');
    }

    if (patterns.isNotEmpty) {
      sb.writeln('Discovered Patterns');
      for (final p in patterns) {
        final confidence = (p['confidence'] as num?)?.toDouble() ?? 0.0;
        final conf = (confidence * 100).toStringAsFixed(0);
        sb.writeln('- ${p['title']} ($conf% confidence, ${p['occurrences']} occurrences)');
      }
      sb.writeln('');
    }

    if (stats['totalRelevantEvents'] != null) {
      sb.writeln('Evidence Summary');
      sb.writeln('- Supporting events: ${stats['totalRelevantEvents']}');
      sb.writeln('- Related entities: ${stats['totalRelevantEntities']}');
    }

    return sb.toString();
  }
}

class AIResponse {
  final String question;
  final String answer;
  final EvidencePackage evidencePackage;
  final Map<String, dynamic> context;
  final DateTime timestamp;

  const AIResponse({
    required this.question,
    required this.answer,
    required this.evidencePackage,
    required this.context,
    required this.timestamp,
  });
}
