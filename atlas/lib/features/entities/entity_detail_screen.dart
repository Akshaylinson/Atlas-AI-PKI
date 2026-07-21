import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/services/decision_intelligence.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/utils.dart';
import 'entity_form_screen.dart';
import '../events/event_form_screen.dart';
import '../events/event_detail_screen.dart';

class EntityDetailScreen extends ConsumerWidget {
  final String entityId;

  const EntityDetailScreen({super.key, required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityAsync = ref.watch(entityByIdProvider(entityId));
    final eventsAsync = ref.watch(eventsForEntityProvider(entityId));
    final statsAsync = ref.watch(entityStatsProvider(entityId));
    final relsAsync = ref.watch(relationshipsForEntityProvider(entityId));

    return entityAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (entity) {
        if (entity == null) {
          return const Scaffold(
              body: Center(child: Text('Entity not found')));
        }
        final color = entity.color != null
            ? Color(int.tryParse(entity.color!) ??
                Theme.of(context).colorScheme.primary.toARGB32())
            : Theme.of(context).colorScheme.primary;
        final tags = List<String>.from(jsonDecode(entity.tags));

        return Scaffold(
          appBar: AppBar(
            title: Text(entity.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EntityFormScreen(entity: entity)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      EventFormScreen(prelinkedEntityId: entityId)),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Event'),
          ),
          body: DefaultTabController(
            length: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: color.withValues(alpha: 0.08),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                entity.icon ?? entity.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontSize: entity.icon != null ? 28 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(entity.name,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    if (entity.isDecision) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text('Decision',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.amber,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                    ],
                                  ],
                                ),
                                if (entity.description != null)
                                  Text(entity.description!,
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Wrap(
                            spacing: 6,
                            children:
                                tags.map((t) => TagChip(tag: t)).toList(),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text('Created ${formatDate(entity.createdAt)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Timeline'),
                    Tab(text: 'Stats'),
                    Tab(text: 'Graph'),
                    Tab(text: 'Decision'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _TimelineTab(eventsAsync: eventsAsync),
                      _StatsTab(statsAsync: statsAsync),
                      _GraphTab(
                          entityId: entityId, relsAsync: relsAsync),
                      _DecisionTab(entity: entity),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entity?'),
        content: const Text('This will permanently delete this entity.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(databaseProvider).deleteEntity(entityId);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ── Timeline Tab ──────────────────────────────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  final AsyncValue<List<Event>> eventsAsync;

  const _TimelineTab({required this.eventsAsync});

  @override
  Widget build(BuildContext context) {
    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (events) => events.isEmpty
          ? const EmptyState(
              icon: Icons.event_note_outlined,
              title: 'No events yet',
              subtitle: 'Add events linked to this entity',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              itemBuilder: (_, i) => _TimelineEventTile(
                  event: events[i], isLast: i == events.length - 1),
            ),
    );
  }
}

class _TimelineEventTile extends StatelessWidget {
  final Event event;
  final bool isLast;

  const _TimelineEventTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final moodColor = event.mood != null
        ? (moodColors[event.mood] ?? Colors.grey)
        : scheme.primary;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EventDetailScreen(eventId: event.id),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                        color: moodColor, shape: BoxShape.circle),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                          width: 2, color: scheme.outlineVariant),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formatDateTime(event.timestamp),
                        style: TextStyle(
                            fontSize: 11,
                            color: scheme.onSurface.withValues(alpha: 0.5))),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.note),
                          if (event.mood != null || event.importance > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  if (event.mood != null)
                                    Text(
                                        '${moodEmojis[event.mood] ?? ''} ${event.mood}',
                                        style:
                                            const TextStyle(fontSize: 12)),
                                  const Spacer(),
                                  Row(
                                    children: List.generate(
                                      event.importance,
                                      (_) => const Icon(Icons.star,
                                          size: 12, color: Colors.amber),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (event.isDecision)
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Decision',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber,
                                      fontWeight: FontWeight.w600)),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.chevron_right,
                                  size: 14,
                                  color: scheme.onSurface.withValues(alpha: 0.3)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats Tab ─────────────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final AsyncValue<EntityStatistic?> statsAsync;

  const _StatsTab({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (stats) {
        if (stats == null) {
          return const EmptyState(
            icon: Icons.bar_chart_outlined,
            title: 'No statistics yet',
            subtitle: 'Statistics will appear after you add events',
          );
        }
        final moodDist =
            Map<String, int>.from(jsonDecode(stats.moodDistribution));
        final monthlyActivity =
            Map<String, int>.from(jsonDecode(stats.monthlyActivity));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                    label: 'Total Events',
                    value: stats.totalEvents.toString(),
                    icon: Icons.event_note,
                    color: Colors.blue),
                StatCard(
                    label: 'Decisions',
                    value: stats.totalDecisions.toString(),
                    icon: Icons.lightbulb,
                    color: Colors.amber),
                StatCard(
                    label: 'Avg Mood',
                    value:
                        '${(stats.avgMoodScore * 100).toStringAsFixed(0)}%',
                    icon: Icons.mood,
                    color: Colors.green),
                StatCard(
                    label: 'Avg Importance',
                    value: stats.avgImportance.toStringAsFixed(1),
                    icon: Icons.star,
                    color: Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            if (moodDist.isNotEmpty) ...[
              const SectionHeader(title: 'Mood Distribution'),
              const SizedBox(height: 12),
              SizedBox(
                  height: 180,
                  child: _MoodBarChart(distribution: moodDist)),
              const SizedBox(height: 24),
            ],
            if (monthlyActivity.isNotEmpty) ...[
              const SectionHeader(title: 'Monthly Activity'),
              const SizedBox(height: 12),
              SizedBox(
                  height: 160,
                  child: _MonthlyChart(activity: monthlyActivity)),
            ],
          ],
        );
      },
    );
  }
}

class _MoodBarChart extends StatelessWidget {
  final Map<String, int> distribution;

  const _MoodBarChart({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final entries = distribution.entries.toList();
    return BarChart(BarChartData(
      barGroups: entries.asMap().entries.map((e) {
        final color = moodColors[e.value.key] ?? Colors.grey;
        return BarChartGroupData(
          x: e.key,
          barRods: [
            BarChartRodData(
              toY: e.value.value.toDouble(),
              color: color,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= entries.length) {
                return const SizedBox.shrink();
              }
              final key = entries[idx].key;
              return Text(moodEmojis[key] ?? '',
                  style: const TextStyle(fontSize: 16));
            },
          ),
        ),
      ),
    ));
  }
}

class _MonthlyChart extends StatelessWidget {
  final Map<String, int> activity;

  const _MonthlyChart({required this.activity});

  @override
  Widget build(BuildContext context) {
    final sorted = activity.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final spots = sorted
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
        .toList();

    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Theme.of(context).colorScheme.primary,
          barWidth: 2,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.1),
          ),
        ),
      ],
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i >= sorted.length) return const SizedBox.shrink();
              final parts = sorted[i].key.split('-');
              return Text(parts.length > 1 ? parts[1] : '',
                  style: const TextStyle(fontSize: 10));
            },
          ),
        ),
      ),
    ));
  }
}

// ── Graph Tab ─────────────────────────────────────────────────────────────────

class _GraphTab extends ConsumerWidget {
  final String entityId;
  final AsyncValue<List<Relationship>> relsAsync;

  const _GraphTab({required this.entityId, required this.relsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return relsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (rels) => rels.isEmpty
          ? const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No relationships yet',
              subtitle:
                  'Relationships are auto-detected when entities appear together in events',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _RelationshipTile(
                rel: rels[i],
                currentEntityId: entityId,
              ),
            ),
    );
  }
}

class _RelationshipTile extends ConsumerWidget {
  final Relationship rel;
  final String currentEntityId;

  const _RelationshipTile(
      {required this.rel, required this.currentEntityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherId = rel.fromEntityId == currentEntityId
        ? rel.toEntityId
        : rel.fromEntityId;
    final otherAsync = ref.watch(entityByIdProvider(otherId));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rel.relationshipType.replaceAll('_', ' '),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500)),
                otherAsync.when(
                  loading: () => const Text('...'),
                  error: (_, __) => const Text('Unknown'),
                  data: (e) => Text(e?.name ?? 'Unknown',
                      style:
                          const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          Text('${(rel.strength * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }
}

// ── Decision Tab ──────────────────────────────────────────────────────────────

class _DecisionTab extends ConsumerWidget {
  final Entity entity;

  const _DecisionTab({required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!entity.isDecision) {
      return EmptyState(
        icon: Icons.lightbulb_outline,
        title: 'Not a Decision',
        subtitle:
            'Edit this entity and check "Mark as Decision" to track it',
        action: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => EntityFormScreen(entity: entity)),
          ),
          child: const Text('Edit Entity'),
        ),
      );
    }

    return FutureBuilder<DecisionEvidence>(
      future: ref
          .read(decisionIntelligenceProvider)
          .analyzeEntity(entity.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final evidence = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                RiskBadge(riskLevel: evidence.riskLevel),
                const Spacer(),
                ConfidenceGauge(confidence: evidence.evidenceStrength),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                StatCard(
                    label: 'Supporting Events',
                    value: evidence.totalEvents.toString(),
                    icon: Icons.event_note,
                    color: Colors.blue),
                StatCard(
                    label: 'Trend',
                    value: evidence.trend,
                    icon: Icons.trending_up,
                    color: Colors.teal),
                StatCard(
                    label: 'Recent (30d)',
                    value: evidence.recentActivity.toString(),
                    icon: Icons.calendar_today,
                    color: Colors.purple),
                StatCard(
                    label: 'Patterns',
                    value: evidence.relatedPatternCount.toString(),
                    icon: Icons.pattern,
                    color: Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            if (entity.decisionReasoning != null) ...[
              const Text('Reasoning',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(entity.decisionReasoning!),
              const SizedBox(height: 12),
            ],
            if (entity.decisionExpectedOutcome != null) ...[
              const Text('Expected Outcome',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(entity.decisionExpectedOutcome!),
              const SizedBox(height: 12),
            ],
            if (entity.decisionActualOutcome != null) ...[
              const Text('Actual Outcome',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(entity.decisionActualOutcome!),
              const SizedBox(height: 12),
            ],
            if (entity.decisionReviewDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14),
                  const SizedBox(width: 6),
                  Text(
                      'Review by: ${formatDate(entity.decisionReviewDate!)}',
                      style: const TextStyle(fontSize: 13)),
                  const Spacer(),
                  if (entity.decisionReviewDate!
                      .isBefore(DateTime.now()))
                    const Text('OVERDUE',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
