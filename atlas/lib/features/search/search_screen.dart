import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/retrieval_engine.dart';
import '../../core/models/models.dart';
import '../../core/database/app_database.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/utils.dart';
import '../entities/entity_detail_screen.dart';
import '../events/event_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  EvidencePackage? _results;
  bool _searching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _results = null);
      return;
    }
    setState(() => _searching = true);
    final engine = ref.read(retrievalEngineProvider);
    final results = await engine.retrieve(query.trim());
    setState(() {
      _results = results;
      _lastQuery = query.trim();
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search events, entities, patterns...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _results = null);
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                if (v.length > 2) _search(v);
              },
              onSubmitted: _search,
            ),
          ),
          if (_searching)
            const LinearProgressIndicator()
          else
            const SizedBox(height: 2),
          Expanded(
            child: _results == null
                ? _SearchHints(onTap: (q) {
                    _ctrl.text = q;
                    _search(q);
                  })
                : _SearchResults(
                    package: _results!,
                    query: _lastQuery,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchHints extends StatelessWidget {
  final ValueChanged<String> onTap;

  const _SearchHints({required this.onTap});

  static const _hints = [
    'client meeting',
    'stressed',
    'project deadline',
    'decision',
    'important',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Try searching for:',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hints
                .map((h) => ActionChip(
                      label: Text(h),
                      onPressed: () => onTap(h),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  final EvidencePackage package;
  final String query;

  const _SearchResults({required this.package, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final entitiesAsync = ref.watch(entitiesStreamProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allEvents) => entitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allEntities) {
          final events = allEvents
              .where((e) => package.eventIds.contains(e.id))
              .toList();
          final entities = allEntities
              .where((e) => package.entityIds.contains(e.id))
              .toList();

          if (events.isEmpty && entities.isEmpty) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'No results for "$query"',
              subtitle: 'Try different keywords or record more events',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${events.length + entities.length} results for "$query"',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (entities.isNotEmpty) ...[
                const SectionHeader(title: 'Entities'),
                const SizedBox(height: 8),
                ...entities.map((e) => _EntityResult(entity: e)),
                const SizedBox(height: 16),
              ],
              if (events.isNotEmpty) ...[
                const SectionHeader(title: 'Events'),
                const SizedBox(height: 8),
                ...events.map((e) => _EventResult(event: e, query: query)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EntityResult extends StatelessWidget {
  final Entity entity;

  const _EntityResult({required this.entity});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EntityDetailScreen(entityId: entity.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_outlined, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entity.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (entity.description != null)
                    Text(truncate(entity.description!, 60),
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EventResult extends StatelessWidget {
  final Event event;
  final String query;

  const _EventResult({required this.event, required this.query});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: event.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_outlined, size: 16),
                const SizedBox(width: 6),
                Text(formatRelative(event.timestamp),
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.5))),
                const Spacer(),
                if (event.mood != null)
                  Text(moodEmojis[event.mood] ?? '',
                      style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 6),
            _HighlightedText(text: truncate(event.note, 120), query: query),
          ],
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    final lower = text.toLowerCase();
    final queryLower = query.toLowerCase();
    final idx = lower.indexOf(queryLower);

    if (idx == -1) return Text(text, style: const TextStyle(fontSize: 13));

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context)
            .style
            .copyWith(fontSize: 13),
        children: [
          TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: TextStyle(
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: text.substring(idx + query.length)),
        ],
      ),
    );
  }
}
