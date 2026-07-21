import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/utils.dart';
import 'event_form_screen.dart';
import 'event_detail_screen.dart';

final _eventFilterMoodProvider = StateProvider<String?>((ref) => null);
final _eventFilterImportanceProvider = StateProvider<int?>((ref) => null);

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final filterMood = ref.watch(_eventFilterMoodProvider);
    final filterImportance = ref.watch(_eventFilterImportanceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, ref),
          ),
        ],
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          var filtered = events;
          if (filterMood != null) {
            filtered = filtered.where((e) => e.mood == filterMood).toList();
          }
          if (filterImportance != null) {
            filtered =
                filtered.where((e) => e.importance == filterImportance).toList();
          }

          if (filtered.isEmpty) {
            return EmptyState(
              icon: Icons.event_note_outlined,
              title: events.isEmpty ? 'No events yet' : 'No matching events',
              subtitle: events.isEmpty
                  ? 'Start recording your life events'
                  : 'Try adjusting your filters',
              action: events.isEmpty
                  ? FilledButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EventFormScreen())),
                      icon: const Icon(Icons.add),
                      label: const Text('Record Event'),
                    )
                  : null,
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _EventCard(event: filtered[i]),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _FilterSheet(ref: ref),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final WidgetRef ref;

  const _FilterSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final currentMood = ref.watch(_eventFilterMoodProvider);
    final currentImportance = ref.watch(_eventFilterImportanceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Events',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          const Text('Mood', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: currentMood == null,
                onSelected: (_) =>
                    ref.read(_eventFilterMoodProvider.notifier).state = null,
              ),
              ...moodEmojis.keys.map((mood) => FilterChip(
                    label: Text('${moodEmojis[mood]} $mood'),
                    selected: currentMood == mood,
                    onSelected: (_) =>
                        ref.read(_eventFilterMoodProvider.notifier).state =
                            currentMood == mood ? null : mood,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Importance', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: currentImportance == null,
                onSelected: (_) =>
                    ref.read(_eventFilterImportanceProvider.notifier).state = null,
              ),
              ...List.generate(
                5,
                (i) => FilterChip(
                  label: Text('${'⭐' * (i + 1)}'),
                  selected: currentImportance == i + 1,
                  onSelected: (_) => ref
                      .read(_eventFilterImportanceProvider.notifier)
                      .state = currentImportance == i + 1 ? null : i + 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attachments = List.from(jsonDecode(event.attachments));
    final tags = List<String>.from(jsonDecode(event.tags));

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: event.isDecision
                ? Colors.amber.withOpacity(0.4)
                : scheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (event.mood != null)
                  Text(moodEmojis[event.mood] ?? '😐',
                      style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatRelative(event.timestamp),
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.5)),
                  ),
                ),
                Row(
                  children: List.generate(
                    event.importance,
                    (_) => const Icon(Icons.star, size: 10, color: Colors.amber),
                  ),
                ),
                if (event.isDecision) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Decision',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (event.title != null) ...[
              Text(
                event.title!,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
            ],
            Text(truncate(event.note, 120)),
            if (attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, size: 14),
                    Text(' ${attachments.length} attachment(s)',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            if (event.voiceNotePath != null)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.mic, size: 14, color: Colors.red),
                    Text(' Voice note', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 4,
                  children: tags.take(3).map((t) => TagChip(tag: t)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
