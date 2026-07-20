import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/database/tables.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/utils.dart';
import '../entities/entity_detail_screen.dart';
import '../events/event_detail_screen.dart';

class DecisionsScreen extends ConsumerWidget {
  const DecisionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decisionEntitiesAsync = ref.watch(decisionEntitiesProvider);
    final decisionEventsAsync = ref.watch(decisionEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision Journal',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'All'),
                Tab(text: 'Overdue Reviews'),
                Tab(text: 'Outcomes'),
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

// ── Cards ─────────────────────────────────────────────────────────────────────

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
