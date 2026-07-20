import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphview/GraphView.dart';
import 'dart:convert';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../shared/theme/app_theme.dart';
import '../entities/entity_detail_screen.dart';

class KnowledgeGraphScreen extends ConsumerStatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  ConsumerState<KnowledgeGraphScreen> createState() =>
      _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState
    extends ConsumerState<KnowledgeGraphScreen> {
  final Graph _graph = Graph()..isTree = false;
  final BuchheimWalkerConfiguration _config = BuchheimWalkerConfiguration()
    ..siblingSeparation = 60
    ..levelSeparation = 80
    ..subtreeSeparation = 60
    ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

  final Map<String, Node> _nodeMap = {};
  bool _built = false;

  @override
  Widget build(BuildContext context) {
    final entitiesAsync = ref.watch(entitiesStreamProvider);
    final relsAsync = ref.watch(allRelationshipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Graph'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _built = false),
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

            if (!_built) {
              _buildGraph(entities, rels);
              _built = true;
            }

            return Column(
              children: [
                // Legend
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.circle, size: 10, color: Colors.blue),
                      const SizedBox(width: 4),
                      const Text('Entity', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 16),
                      const Icon(Icons.circle, size: 10, color: Colors.amber),
                      const SizedBox(width: 4),
                      const Text('Decision', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    constrained: false,
                    boundaryMargin: const EdgeInsets.all(100),
                    minScale: 0.3,
                    maxScale: 2.5,
                    child: GraphView(
                      graph: _graph,
                      algorithm: BuchheimWalkerAlgorithm(
                          _config, TreeEdgeRenderer(_config)),
                      paint: Paint()
                        ..color = Theme.of(context)
                            .colorScheme
                            .outlineVariant
                        ..strokeWidth = 1.5
                        ..style = PaintingStyle.stroke,
                      builder: (node) {
                        final entityId = node.key!.value as String;
                        final entity = entities
                            .where((e) => e.id == entityId)
                            .firstOrNull;
                        return _GraphNode(
                          entity: entity,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EntityDetailScreen(entityId: entityId),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _buildGraph(List<Entity> entities, List<Relationship> rels) {
    _graph.nodes.clear();
    _graph.edges.clear();
    _nodeMap.clear();

    for (final entity in entities) {
      final node = Node.Id(entity.id);
      _nodeMap[entity.id] = node;
      _graph.addNode(node);
    }

    for (final rel in rels) {
      final from = _nodeMap[rel.fromEntityId];
      final to = _nodeMap[rel.toEntityId];
      if (from != null && to != null) {
        _graph.addEdge(from, to,
            paint: Paint()
              ..color = Colors.grey.withOpacity(rel.strength)
              ..strokeWidth = rel.strength * 2
              ..style = PaintingStyle.stroke);
      }
    }
  }
}

class _GraphNode extends StatelessWidget {
  final Entity? entity;
  final VoidCallback onTap;

  const _GraphNode({required this.entity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = entity?.isDecision == true
        ? Colors.amber
        : entity?.color != null
            ? Color(int.tryParse(entity!.color!) ?? scheme.primary.value)
            : scheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (entity?.icon != null)
              Text(entity!.icon!, style: const TextStyle(fontSize: 14)),
            if (entity?.icon != null) const SizedBox(width: 4),
            Text(
              entity?.name ?? '?',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color),
            ),
          ],
        ),
      ),
    );
  }
}
