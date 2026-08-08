import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/database/tables.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/utils.dart';
import 'matrix_screen.dart';
import '../entities/entity_detail_screen.dart';
import '../events/event_detail_screen.dart';

class DecisionsScreen extends ConsumerWidget {
  const DecisionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decisionEntitiesAsync = ref.watch(decisionEntitiesProvider);
    final decisionEventsAsync = ref.watch(decisionEventsProvider);
    final allMatricesAsync = ref.watch(allMatricesProvider);
    final entitiesAsync = ref.watch(entitiesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision Journal',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Overdue Reviews'),
                Tab(text: 'Outcomes'),
                Tab(text: 'Matrices'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _AllDecisionsTab(
                    entitiesAsync: decisionEntitiesAsync,
                    eventsAsync: decisionEventsAsync,
                  ),
                  _OverdueTab(
                    entitiesAsync: decisionEntitiesAsync,
                    eventsAsync: decisionEventsAsync,
                  ),
                  _OutcomesTab(
                    entitiesAsync: decisionEntitiesAsync,
                    eventsAsync: decisionEventsAsync,
                  ),
                  _MatricesTab(
                    matricesAsync: allMatricesAsync,
                    entitiesAsync: entitiesAsync,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── All Decisions Tab ─────────────────────────────────────────────────────────

class _AllDecisionsTab extends StatelessWidget {
  final AsyncValue<List<Entity>> entitiesAsync;
  final AsyncValue<List<Event>> eventsAsync;

  const _AllDecisionsTab(
      {required this.entitiesAsync, required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    return entitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entities) => eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          if (entities.isEmpty && events.isEmpty) {
            return const EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'No decisions tracked',
              subtitle:
                  'When creating entities or events, check "Mark as Decision" to track them here',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (entities.isNotEmpty) ...[
                const SectionHeader(title: 'Decision Entities'),
                const SizedBox(height: 8),
                ...entities.map((e) => _DecisionEntityCard(entity: e)),
                const SizedBox(height: 16),
              ],
              if (events.isNotEmpty) ...[
                const SectionHeader(title: 'Decision Events'),
                const SizedBox(height: 8),
                ...events.map((e) => _DecisionEventCard(event: e)),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Overdue Tab ───────────────────────────────────────────────────────────────

class _OverdueTab extends StatelessWidget {
  final AsyncValue<List<Entity>> entitiesAsync;
  final AsyncValue<List<Event>> eventsAsync;

  const _OverdueTab(
      {required this.entitiesAsync, required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return entitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entities) => eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          final overdueEntities = entities.where((e) =>
              e.decisionReviewDate != null &&
              e.decisionReviewDate!.isBefore(now) &&
              e.decisionActualOutcome == null).toList();
          final overdueEvents = events.where((e) =>
              e.decisionReviewDate != null &&
              e.decisionReviewDate!.isBefore(now) &&
              e.decisionActualOutcome == null).toList();

          if (overdueEntities.isEmpty && overdueEvents.isEmpty) {
            return const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'No overdue reviews',
              subtitle: 'All decisions are up to date',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...overdueEntities.map((e) => _DecisionEntityCard(
                    entity: e,
                    showOverdueBadge: true,
                  )),
              ...overdueEvents.map((e) => _DecisionEventCard(
                    event: e,
                    showOverdueBadge: true,
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ── Outcomes Tab ──────────────────────────────────────────────────────────────

class _OutcomesTab extends StatelessWidget {
  final AsyncValue<List<Entity>> entitiesAsync;
  final AsyncValue<List<Event>> eventsAsync;

  const _OutcomesTab(
      {required this.entitiesAsync, required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    return entitiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entities) => eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          final withOutcomeEntities = entities
              .where((e) => e.decisionActualOutcome != null)
              .toList();
          final withOutcomeEvents = events
              .where((e) => e.decisionActualOutcome != null)
              .toList();

          if (withOutcomeEntities.isEmpty && withOutcomeEvents.isEmpty) {
            return const EmptyState(
              icon: Icons.compare_arrows,
              title: 'No outcomes recorded',
              subtitle:
                  'Edit decisions and add actual outcomes to compare with expectations',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...withOutcomeEntities.map((e) => _OutcomeComparisonCard(
                    title: e.name,
                    expected: e.decisionExpectedOutcome,
                    actual: e.decisionActualOutcome!,
                    date: e.createdAt,
                  )),
              ...withOutcomeEvents.map((e) => _OutcomeComparisonCard(
                    title: truncate(e.note, 60),
                    expected: e.decisionExpectedOutcome,
                    actual: e.decisionActualOutcome!,
                    date: e.timestamp,
                  )),
            ],
          );
        },
      ),
    );
  }
}

// ?? Matrices Tab ?????????????????????????????????????????????????????????????

class _MatricesTab extends StatelessWidget {
  final AsyncValue<List<DecisionMatrix>> matricesAsync;
  final AsyncValue<List<Entity>> entitiesAsync;

  const _MatricesTab({required this.matricesAsync, required this.entitiesAsync});

  @override
  Widget build(BuildContext context) {
    return matricesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (matrices) => entitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entities) {
          if (matrices.isEmpty) {
            return const EmptyState(
              icon: Icons.view_list_outlined,
              title: 'No matrices saved',
              subtitle: 'Saved evaluations will appear here across all entities',
            );
          }

          final entityNames = {for (final entity in entities) entity.id: entity.name};
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matrices.length,
            itemBuilder: (_, index) {
              final matrix = matrices[index];
              return _MatrixHistoryCard(
                matrix: matrix,
                entityName: entityNames[matrix.entityId] ?? matrix.entityId,
              );
            },
          );
        },
      ),
    );
  }
}

class _MatrixHistoryCard extends StatelessWidget {
  final DecisionMatrix matrix;
  final String entityName;

  const _MatrixHistoryCard({required this.matrix, required this.entityName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final parsed = _parseTopResult(matrix.result);
    final confidence = matrix.confidenceScore ?? 0.0;
    final label = confidence >= 0.7
        ? 'High'
        : confidence >= 0.4
            ? 'Medium'
            : 'Low';
    final labelColor = confidence >= 0.7
        ? Colors.green
        : confidence >= 0.4
            ? Colors.amber
            : Colors.red;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MatrixScreen(entityId: matrix.entityId, existing: matrix),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(entityName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                _ConfidenceChip(label: label, color: labelColor),
              ],
            ),
            const SizedBox(height: 8),
            Text(matrix.question,
                style: TextStyle(fontSize: 13, color: scheme.onSurface.withOpacity(0.8))),
            const SizedBox(height: 8),
            Text('Top result: ${parsed.name} (${parsed.score.toStringAsFixed(2)} / 5.0)'),
            const SizedBox(height: 4),
            Text(formatDate(matrix.createdAt),
                style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.55))),
          ],
        ),
      ),
    );
  }
}

_ParsedMatrixResult _parseTopResult(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const _ParsedMatrixResult(name: 'No result', score: 0.0);
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        return _ParsedMatrixResult(
          name: (map['name'] ?? 'Unknown').toString(),
          score: (map['weightedScore'] as num?)?.toDouble() ?? 0.0,
        );
      }
    }
  } catch (_) {}
  return const _ParsedMatrixResult(name: 'No result', score: 0.0);
}

class _ParsedMatrixResult {
  final String name;
  final double score;

  const _ParsedMatrixResult({required this.name, required this.score});
}

class _ConfidenceChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ConfidenceChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ?? Cards ????????????????????????????????????????????????????????????????????

class _DecisionEntityCard extends ConsumerWidget {
  final Entity entity;
  final bool showOverdueBadge;

  const _DecisionEntityCard(
      {required this.entity, this.showOverdueBadge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EntityDetailScreen(entityId: entity.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showOverdueBadge
                ? Colors.red.withOpacity(0.4)
                : Colors.amber.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(entity.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (showOverdueBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('OVERDUE',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (entity.decisionReasoning != null) ...[
              const SizedBox(height: 6),
              Text(truncate(entity.decisionReasoning!, 80),
                  style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.6))),
            ],
            if (entity.decisionExpectedOutcome != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.arrow_forward, size: 12,
                      color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                        'Expected: ${truncate(entity.decisionExpectedOutcome!, 60)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.blue)),
                  ),
                ],
              ),
            ],
            if (entity.decisionReviewDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12),
                  const SizedBox(width: 4),
                  Text(
                      'Review: ${formatDate(entity.decisionReviewDate!)}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
            if (entity.decisionConfidence != null) ...[
              const SizedBox(height: 4),
              Text(
                  'Confidence at decision: ${entity.decisionConfidence}/10',
                  style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DecisionEventCard extends ConsumerWidget {
  final Event event;
  final bool showOverdueBadge;

  const _DecisionEventCard(
      {required this.event, this.showOverdueBadge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: event.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showOverdueBadge
                ? Colors.red.withOpacity(0.4)
                : Colors.amber.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(truncate(event.note, 60),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (showOverdueBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('OVERDUE',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(formatDate(event.timestamp),
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.5))),
            if (event.decisionExpectedOutcome != null) ...[
              const SizedBox(height: 4),
              Text(
                  'Expected: ${truncate(event.decisionExpectedOutcome!, 60)}',
                  style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ],
            if (event.decisionReviewDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12),
                  const SizedBox(width: 4),
                  Text('Review: ${formatDate(event.decisionReviewDate!)}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OutcomeComparisonCard extends StatelessWidget {
  final String title;
  final String? expected;
  final String actual;
  final DateTime date;

  const _OutcomeComparisonCard({
    required this.title,
    required this.expected,
    required this.actual,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(formatDate(date),
              style: TextStyle(
                  fontSize: 11,
                  color: scheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 10),
          if (expected != null) ...[
            const Text('Expected',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue)),
            Text(expected!, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
          ],
          const Text('Actual',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.green)),
          Text(actual, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
