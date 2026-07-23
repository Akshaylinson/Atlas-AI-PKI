import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../entities/entity_detail_screen.dart';

class KnowledgeGraphScreen extends ConsumerWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitiesAsync = ref.watch(entitiesStreamProvider);
    final relsAsync = ref.watch(allRelationshipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(entitiesStreamProvider);
              ref.invalidate(allRelationshipsProvider);
            },
          ),
        ],
      ),
      body: entitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entities) => relsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (rels) {
            if (entities.isEmpty) {
              return const Center(
                child: Text('No entities yet. Create entities to see the graph.'),
              );
            }

            final byId = {for (final e in entities) e.id: e};
            final decisionCount = entities.where((e) => e.isDecision).length;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Entities',
                        value: entities.length.toString(),
                        icon: Icons.category_outlined,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Decisions',
                        value: decisionCount.toString(),
                        icon: Icons.lightbulb_outline,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Entities',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entities
                      .map(
                        (e) => ActionChip(
                          avatar: Icon(
                            e.isDecision ? Icons.lightbulb : Icons.circle,
                            size: 16,
                            color: e.isDecision ? Colors.amber : Colors.blue,
                          ),
                          label: Text(e.name),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EntityDetailScreen(entityId: e.id),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Relationships',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (rels.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No relationships recorded yet.'),
                  )
                else
                  ...rels.map((rel) => _RelationshipCard(
                        rel: rel,
                        from: byId[rel.fromEntityId],
                        to: byId[rel.toEntityId],
                        onEntityTap: (id) => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntityDetailScreen(entityId: id),
                          ),
                        ),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  final Relationship rel;
  final Entity? from;
  final Entity? to;
  final ValueChanged<String> onEntityTap;

  const _RelationshipCard({
    required this.rel,
    required this.from,
    required this.to,
    required this.onEntityTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fromName = from?.name ?? rel.fromEntityId;
    final toName = to?.name ?? rel.toEntityId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onEntityTap(rel.fromEntityId),
                  child: _EntityPill(
                    label: fromName,
                    color: from?.isDecision == true ? Colors.amber : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => onEntityTap(rel.toEntityId),
                  child: _EntityPill(
                    label: toName,
                    color: to?.isDecision == true ? Colors.amber : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rel.relationshipType,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (rel.description != null && rel.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              rel.description!,
              style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.7)),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'Strength: ${(rel.strength * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EntityPill extends StatelessWidget {
  final String label;
  final Color color;

  const _EntityPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color,
          fontSize: 12,
        ),
      ),
    );
  }
}
