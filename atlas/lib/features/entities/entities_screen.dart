import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/utils/utils.dart';
import 'entity_form_screen.dart';
import 'entity_detail_screen.dart';

final _entitySearchQueryProvider = StateProvider<String>((ref) => '');

class EntitiesScreen extends ConsumerWidget {
  const EntitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(_entitySearchQueryProvider);
    final entitiesAsync = query.isEmpty
        ? ref.watch(entitiesStreamProvider)
        : ref.watch(entitySearchProvider(query)).when(
            data: (data) => AsyncValue.data(data),
            loading: () => const AsyncValue.loading(),
            error: (e, s) => AsyncValue.error(e, s),
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entities', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search entities...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) =>
                  ref.read(_entitySearchQueryProvider.notifier).state = v,
            ),
          ),
        ),
      ),
      body: entitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entities) => entities.isEmpty
            ? EmptyState(
                icon: Icons.category_outlined,
                title: 'No entities yet',
                subtitle: 'Create your first entity to start building your knowledge base',
                action: FilledButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const EntityFormScreen())),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Entity'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _EntityCard(entity: entities[i]),
              ),
      ),
    );
  }
}

class _EntityCard extends ConsumerWidget {
  final Entity entity;

  const _EntityCard({required this.entity});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final tags = List<String>.from(jsonDecode(entity.tags));
    final color = entity.color != null
        ? Color(int.tryParse(entity.color!) ?? scheme.primary.value)
        : scheme.primary;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EntityDetailScreen(entityId: entity.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  entity.icon ?? entity.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: entity.icon != null ? 22 : 18,
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
                      Expanded(
                        child: Text(entity.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                      ),
                      if (entity.isDecision)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Decision',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  if (entity.description != null && entity.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        truncate(entity.description!, 60),
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.6)),
                      ),
                    ),
                  if (tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        children: tags
                            .take(3)
                            .map((t) => TagChip(tag: t))
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}
