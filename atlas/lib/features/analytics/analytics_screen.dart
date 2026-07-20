import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/utils.dart';
import '../knowledge_graph/knowledge_graph_screen.dart';
import '../patterns/patterns_screen.dart';
import '../settings/settings_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'Knowledge Graph',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KnowledgeGraphScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.pattern),
            tooltip: 'Patterns',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PatternsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardStatsProvider.future),
          child: ListView(
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
                    color: Colors.blue,
                  ),
                  StatCard(
                    label: 'Entities',
                    value: stats.totalEntities.toString(),
                    icon: Icons.category,
                    color: Colors.purple,
                  ),
                  StatCard(
                    label: 'Patterns Found',
                    value: stats.patternCount.toString(),
                    icon: Icons.pattern,
                    color: Colors.teal,
                  ),
                  StatCard(
                    label: 'High Confidence',
                    value: stats.highConfidencePatterns.toString(),
                    icon: Icons.verified,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (stats.moodDistribution.isNotEmpty) ...[
                const SectionHeader(title: 'Mood Distribution'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _MoodPieChart(distribution: stats.moodDistribution),
                ),
                const SizedBox(height: 24),
              ],
              eventsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Activity (Last 30 Days)'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: _ActivityBarChart(events: events),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
              if (stats.recentEvents.isNotEmpty) ...[
                const SectionHeader(title: 'Recent Events'),
                const SizedBox(height: 12),
                ...stats.recentEvents.map((e) => _RecentEventTile(event: e)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodPieChart extends StatelessWidget {
  final Map<String, int> distribution;

  const _MoodPieChart({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = distribution.entries.map((e) {
      final color = moodColors[e.key] ?? Colors.grey;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        title:
            '${moodEmojis[e.key] ?? ''}\n${((e.value / total) * 100).toStringAsFixed(0)}%',
        radius: 70,
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(PieChartData(sections: sections, sectionsSpace: 2));
  }
}

class _ActivityBarChart extends StatelessWidget {
  final List<Event> events;

  const _ActivityBarChart({required this.events});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last30 =
        List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    final counts = <int, int>{};
    for (final e in events) {
      final diff = now.difference(e.timestamp).inDays;
      if (diff < 30) counts[29 - diff] = (counts[29 - diff] ?? 0) + 1;
    }

    final bars = last30.asMap().entries.map((entry) {
      final count = counts[entry.key] ?? 0;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();

    return BarChart(BarChartData(
      barGroups: bars,
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
            interval: 7,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx < 0 || idx >= last30.length) {
                return const SizedBox.shrink();
              }
              final day = last30[idx];
              return Text('${day.day}/${day.month}',
                  style: const TextStyle(fontSize: 9));
            },
          ),
        ),
      ),
    ));
  }
}

class _RecentEventTile extends StatelessWidget {
  final Event event;

  const _RecentEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (event.mood != null)
            Text(moodEmojis[event.mood] ?? '😐',
                style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(truncate(event.note, 80),
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                Text(formatRelative(event.timestamp),
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          _ImportanceDot(importance: event.importance),
        ],
      ),
    );
  }
}

class _ImportanceDot extends StatelessWidget {
  final int importance;

  const _ImportanceDot({required this.importance});

  @override
  Widget build(BuildContext context) {
    final color = importanceColors[importance] ?? Colors.grey;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
