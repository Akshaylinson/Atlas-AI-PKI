import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:photo_view/photo_view.dart';
import '../../core/providers/providers.dart';
import '../../core/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/utils.dart';
import 'event_form_screen.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback(String path) async {
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.setFilePath(path);
      _player.play();
      setState(() => _isPlaying = true);
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch all events and find the one we need
    final eventsAsync = ref.watch(eventsStreamProvider);

    return eventsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (events) {
        final event =
            events.where((e) => e.id == widget.eventId).firstOrNull;
        if (event == null) {
          return const Scaffold(
              body: Center(child: Text('Event not found')));
        }

        final attachments = Attachment.listFromJson(event.attachments);
        final tags = List<String>.from(jsonDecode(event.tags));
        final linkedIds =
            List<String>.from(jsonDecode(event.linkedEntityIds));
        final customFields =
            Map<String, dynamic>.from(jsonDecode(event.customFields));
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Event'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EventFormScreen(event: event)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header row
              Row(
                children: [
                  if (event.mood != null)
                    Text(moodEmojis[event.mood] ?? '😐',
                        style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(formatDateTime(event.timestamp),
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    scheme.onSurface.withOpacity(0.6))),
                        if (event.mood != null)
                          Text(
                              event.mood![0].toUpperCase() +
                                  event.mood!.substring(1),
                              style: TextStyle(
                                  color: moodColors[event.mood] ??
                                      Colors.grey)),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(
                      event.importance,
                      (_) => const Icon(Icons.star,
                          size: 16, color: Colors.amber),
                    ),
                  ),
                  if (event.isDecision) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Decision',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Note
              if (event.title != null) ...[
                Text(
                  event.title!,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
              ],
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(event.note,
                    style: const TextStyle(fontSize: 15, height: 1.5)),
              ),
              const SizedBox(height: 16),

              // Meta info
              if (event.location != null || event.durationMinutes != null)
                Wrap(
                  spacing: 12,
                  children: [
                    if (event.location != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.location_on_outlined, size: 14),
                        const SizedBox(width: 4),
                        Text(event.location!,
                            style: const TextStyle(fontSize: 13)),
                      ]),
                    if (event.durationMinutes != null)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.timer_outlined, size: 14),
                        const SizedBox(width: 4),
                        Text('${event.durationMinutes} min',
                            style: const TextStyle(fontSize: 13)),
                      ]),
                  ],
                ),

              // Tags
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: tags.map((t) => TagChip(tag: t)).toList(),
                ),
              ],

              // Linked entities
              if (linkedIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionHeader(title: 'Linked Entities'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: linkedIds
                      .map((id) => _LinkedEntityChip(entityId: id))
                      .toList(),
                ),
              ],

              // Voice note
              if (event.voiceNotePath != null) ...[
                const SizedBox(height: 16),
                const SectionHeader(title: 'Voice Note'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          _togglePlayback(event.voiceNotePath!),
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Stop' : 'Play'),
                    ),
                  ],
                ),
              ],

              // Attachments
              if (attachments.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionHeader(title: 'Attachments'),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: attachments.length,
                  itemBuilder: (_, i) =>
                      _AttachmentTile(attachment: attachments[i]),
                ),
              ],

              // Custom fields
              if (customFields.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionHeader(title: 'Custom Fields'),
                const SizedBox(height: 8),
                ...customFields.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Text('${e.key}: ',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13)),
                          Text(e.value.toString(),
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )),
              ],

              // Decision details
              if (event.isDecision) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Decision Details',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 12),
                if (event.decisionOptions != null)
                  _DecisionField(
                    label: 'Options Considered',
                    value: (jsonDecode(event.decisionOptions!) as List)
                        .join('\n• '),
                  ),
                if (event.decisionReasoning != null)
                  _DecisionField(
                    label: 'Reasoning',
                    value: event.decisionReasoning!,
                  ),
                if (event.decisionExpectedOutcome != null)
                  _DecisionField(
                    label: 'Expected Outcome',
                    value: event.decisionExpectedOutcome!,
                  ),
                if (event.decisionActualOutcome != null)
                  _DecisionField(
                    label: 'Actual Outcome',
                    value: event.decisionActualOutcome!,
                  ),
                if (event.decisionConfidence != null)
                  _DecisionField(
                    label: 'Confidence',
                    value: '${event.decisionConfidence}/10',
                  ),
                if (event.decisionReviewDate != null)
                  _DecisionField(
                    label: 'Review Date',
                    value: formatDate(event.decisionReviewDate!),
                  ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event?'),
        content: const Text('This will permanently delete this event.'),
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
      await ref.read(databaseProvider).deleteEvent(widget.eventId);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _LinkedEntityChip extends ConsumerWidget {
  final String entityId;

  const _LinkedEntityChip({required this.entityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entityAsync = ref.watch(entityByIdProvider(entityId));
    return entityAsync.when(
      loading: () => const Chip(label: Text('...')),
      error: (_, __) => const SizedBox.shrink(),
      data: (entity) => entity == null
          ? const SizedBox.shrink()
          : Chip(
              avatar: Text(entity.icon ?? entity.name[0],
                  style: const TextStyle(fontSize: 14)),
              label: Text(entity.name),
            ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final Attachment attachment;

  const _AttachmentTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    if (attachment.type == AttachmentType.image) {
      return GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(),
              body: PhotoView(imageProvider: FileImage(File(attachment.path))),
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(File(attachment.path), fit: BoxFit.cover),
        ),
      );
    }
    return GestureDetector(
      onTap: () => OpenFilex.open(attachment.path),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_typeIcon(attachment.type), size: 28),
            const SizedBox(height: 4),
            Text(
              attachment.name ?? 'File',
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.video: return Icons.videocam;
      case AttachmentType.audio: return Icons.audiotrack;
      case AttachmentType.pdf: return Icons.picture_as_pdf;
      default: return Icons.insert_drive_file;
    }
  }
}

class _DecisionField extends StatelessWidget {
  final String label;
  final String value;

  const _DecisionField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
