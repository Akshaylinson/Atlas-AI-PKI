import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/services/pattern_ai_service.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/utils.dart';

class PatternsScreen extends ConsumerWidget {
  const PatternsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patternsAsync = ref.watch(patternsStreamProvider);
    final aiState = ref.watch(patternAiProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patterns',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: aiState.isRunning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Run AI pattern scan',
            onPressed: aiState.isRunning
                ? null
                : () => ref.read(patternAiProvider.notifier).runScan(),
          ),
        ],
      ),
      body: patternsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (patterns) {
          final latestRun = aiState.latestRun;
          final latestLabels = aiState.latestLabelsByPatternId;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (aiState.error != null) ...[
                _StatusBanner(
                  icon: Icons.error_outline,
                  title: 'AI scan failed',
                  message: aiState.error!,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
              ],
              _AiControlCard(
                isRunning: aiState.isRunning,
                latestRun: latestRun,
                onRun: aiState.isRunning
                    ? null
                    : () => ref.read(patternAiProvider.notifier).runScan(),
              ),
              const SizedBox(height: 16),
              if (patterns.isEmpty)
                const EmptyState(
                  icon: Icons.pattern,
                  title: 'No patterns discovered yet',
                  subtitle:
                      'Patterns are automatically discovered as you record more events. The AI button can label them once they exist.',
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Total Patterns',
                        value: patterns.length.toString(),
                        icon: Icons.pattern,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'High Confidence',
                        value: patterns
                            .where((p) => p.confidence > 0.7)
                            .length
                            .toString(),
                        icon: Icons.verified,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _PatternFrequencyChart(patterns: patterns),
                const SizedBox(height: 16),
                SectionHeader(
                  title: 'Discovered Patterns',
                  trailing: Text(
                    'Auto + AI',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.55),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...patterns.map((p) => _PatternCard(
                      pattern: p,
                      aiLabel: latestLabels[p.id],
                    )),
              ],
              const SizedBox(height: 8),
              if (aiState.history.isNotEmpty) ...[
                const SizedBox(height: 8),
                const SectionHeader(title: 'AI Pattern History'),
                const SizedBox(height: 12),
                ...aiState.history
                    .map((run) => _PatternAiHistoryCard(run: run)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AiControlCard extends StatelessWidget {
  final bool isRunning;
  final PatternAiRun? latestRun;
  final VoidCallback? onRun;

  const _AiControlCard({
    required this.isRunning,
    required this.latestRun,
    required this.onRun,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.12),
            scheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: scheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AI Pattern Labeling',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton.icon(
                onPressed: onRun,
                icon: isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bolt),
                label: Text(isRunning ? 'Scanning' : 'Run Scan'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'The automatic pattern engine keeps working in the background. This button asks AI to relabel the current patterns and append a history entry below.',
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withOpacity(0.72),
            ),
          ),
          if (latestRun != null) ...[
            const SizedBox(height: 12),
            Text(
              'Latest AI summary',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 6),
            Text(latestRun!.summary.isEmpty
                ? 'AI scan complete.'
                : latestRun!.summary),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _AiMetaChip(
                  icon: Icons.schedule,
                  label: formatRelative(latestRun!.timestamp),
                ),
                _AiMetaChip(
                  icon: Icons.memory,
                  label: latestRun!.backend.toUpperCase(),
                ),
                _AiMetaChip(
                  icon: Icons.label_outline,
                  label: '${latestRun!.labels.length} labels',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;

  const _StatusBanner({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontWeight: FontWeight.w600, color: color)),
                const SizedBox(height: 2),
                Text(message),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PatternFrequencyChart extends StatelessWidget {
  final List<Pattern> patterns;
  const _PatternFrequencyChart({required this.patterns});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typeCounts = <String, int>{};
    for (final p in patterns) {
      typeCounts[p.patternType] = (typeCounts[p.patternType] ?? 0) + 1;
    }
    final entries = typeCounts.entries.toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    const typeColors = {
      'association': Color(0xFF2563EB),
      'sequential': Color(0xFF7C3AED),
      'mood_trend': Color(0xFF16A34A),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pattern Types',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: BarChart(BarChartData(
            barGroups: entries.asMap().entries.map((e) {
              final color = typeColors[e.value.key] ?? scheme.primary;
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.value.toDouble(),
                    color: color,
                    width: 28,
                    borderRadius: BorderRadius.circular(6),
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
                    final i = v.toInt();
                    if (i < 0 || i >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    final label = entries[i].key.replaceAll('_', ' ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(label, style: const TextStyle(fontSize: 9)),
                    );
                  },
                ),
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class _PatternCard extends ConsumerWidget {
  final Pattern pattern;
  final PatternAiLabel? aiLabel;

  const _PatternCard({required this.pattern, this.aiLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final evidenceList = List.from(jsonDecode(pattern.evidence));
    final relatedIds = List<String>.from(jsonDecode(pattern.relatedEntityIds));

    Color typeColor;
    IconData typeIcon;
    switch (pattern.patternType) {
      case 'association':
        typeColor = Colors.blue;
        typeIcon = Icons.link;
        break;
      case 'sequential':
        typeColor = Colors.purple;
        typeIcon = Icons.timeline;
        break;
      case 'mood_trend':
        typeColor = Colors.green;
        typeIcon = Icons.mood;
        break;
      default:
        typeColor = Colors.teal;
        typeIcon = Icons.pattern;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, size: 16, color: typeColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(pattern.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              if (aiLabel != null) ...[
                const SizedBox(width: 8),
                _AiTag(
                    label: aiLabel!.relationshipLabel,
                    confidence: aiLabel!.confidence),
              ],
              ConfidenceGauge(confidence: pattern.confidence, size: 48),
            ],
          ),
          const SizedBox(height: 8),
          Text(pattern.description,
              style: TextStyle(
                  fontSize: 13, color: scheme.onSurface.withOpacity(0.7))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            children: [
              _MetaChip(
                icon: Icons.repeat,
                label: '${pattern.occurrences} occurrences',
              ),
              _MetaChip(
                icon: Icons.event_note,
                label: '${evidenceList.length} events',
              ),
              _MetaChip(
                icon: Icons.update,
                label: 'Updated ${formatRelative(pattern.updatedAt)}',
              ),
            ],
          ),
          if (relatedIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: relatedIds
                  .take(3)
                  .map((id) => _EntityNameChip(entityId: id))
                  .toList(),
            ),
          ],
          if (aiLabel != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: typeColor.withOpacity(0.15)),
              ),
              child: Text(
                'AI label: ${aiLabel!.relationshipLabel} • ${aiLabel!.reason}',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.75),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Confidence bar
          Row(
            children: [
              Text(confidenceLabel(pattern.confidence),
                  style: TextStyle(
                      fontSize: 11,
                      color: typeColor,
                      fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pattern.confidence,
                    backgroundColor: typeColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(typeColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(pattern.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiTag extends StatelessWidget {
  final String label;
  final double confidence;

  const _AiTag({required this.label, required this.confidence});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withOpacity(0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'AI ${label.replaceAll('_', ' ')} ${(confidence * 100).toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _AiMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _AiMetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: scheme.onSurface.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _PatternAiHistoryCard extends StatelessWidget {
  final PatternAiRun run;

  const _PatternAiHistoryCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatRelative(run.timestamp),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                run.backend.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(run.summary.isEmpty ? 'AI scan completed.' : run.summary),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: run.labels.take(4).map((label) {
              return _AiTag(
                label: label.relationshipLabel,
                confidence: label.confidence,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
      ],
    );
  }
}

class _EntityNameChip extends ConsumerWidget {
  final String entityId;

  const _EntityNameChip({required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityAsync = ref.watch(entityByIdProvider(entityId));
    return entityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entity) => entity == null
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(entity.name, style: const TextStyle(fontSize: 11)),
            ),
    );
  }
}
