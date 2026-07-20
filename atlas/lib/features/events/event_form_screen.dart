import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:drift/drift.dart' show Value;
import '../../core/database/app_database.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/theme/app_theme.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final Event? event;
  final String? prelinkedEntityId;

  const EventFormScreen({super.key, this.event, this.prelinkedEntityId});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();

  String? _selectedMood;
  int _importance = 3;
  int? _durationMinutes;
  List<String> _tags = [];
  List<Attachment> _attachments = [];
  String? _voiceNotePath;
  List<String> _linkedEntityIds = [];
  List<Map<String, String>> _customFields = [];
  DateTime _timestamp = DateTime.now();

  bool _isDecision = false;
  final _decisionOptionsCtrl = TextEditingController();
  final _decisionReasoningCtrl = TextEditingController();
  final _decisionExpectedCtrl = TextEditingController();
  int _decisionConfidence = 5;
  DateTime? _reviewDate;

  bool _saving = false;
  bool _isRecording = false;
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    if (e != null) {
      _noteCtrl.text = e.note;
      _locationCtrl.text = e.location ?? '';
      _selectedMood = e.mood;
      _importance = e.importance;
      _durationMinutes = e.durationMinutes;
      _tags = List<String>.from(jsonDecode(e.tags));
      _attachments = Attachment.listFromJson(e.attachments);
      _voiceNotePath = e.voiceNotePath;
      _linkedEntityIds = List<String>.from(jsonDecode(e.linkedEntityIds));
      _timestamp = e.timestamp;
      _isDecision = e.isDecision;
      if (e.decisionOptions != null) {
        _decisionOptionsCtrl.text =
            (jsonDecode(e.decisionOptions!) as List).join('\n');
      }
      _decisionReasoningCtrl.text = e.decisionReasoning ?? '';
      _decisionExpectedCtrl.text = e.decisionExpectedOutcome ?? '';
      _decisionConfidence = e.decisionConfidence ?? 5;
      _reviewDate = e.decisionReviewDate;
      final fields = jsonDecode(e.customFields) as Map<String, dynamic>;
      _customFields = fields.entries
          .map((e) => {'key': e.key, 'value': e.value.toString(), 'type': 'text'})
          .toList();
    }
    if (widget.prelinkedEntityId != null &&
        !_linkedEntityIds.contains(widget.prelinkedEntityId)) {
      _linkedEntityIds.add(widget.prelinkedEntityId!);
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _locationCtrl.dispose();
    _tagCtrl.dispose();
    _decisionOptionsCtrl.dispose();
    _decisionReasoningCtrl.dispose();
    _decisionExpectedCtrl.dispose();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final db = ref.read(databaseProvider);
    final pki = ref.read(pkiPipelineProvider);
    final id = widget.event?.id ?? const Uuid().v4();

    final customFieldsMap = {
      for (final f in _customFields) f['key']!: f['value']!
    };

    final options = _decisionOptionsCtrl.text.trim().isEmpty
        ? null
        : jsonEncode(_decisionOptionsCtrl.text
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList());

    await db.upsertEvent(EventsCompanion(
      id: Value(id),
      note: Value(_noteCtrl.text.trim()),
      linkedEntityIds: Value(jsonEncode(_linkedEntityIds)),
      attachments: Value(Attachment.listToJson(_attachments)),
      voiceNotePath: Value(_voiceNotePath),
      mood: Value(_selectedMood),
      importance: Value(_importance),
      location: Value(_locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim()),
      durationMinutes: Value(_durationMinutes),
      customFields: Value(jsonEncode(customFieldsMap)),
      tags: Value(jsonEncode(_tags)),
      isDecision: Value(_isDecision),
      decisionOptions: Value(options),
      decisionReasoning: Value(_decisionReasoningCtrl.text.trim().isEmpty
          ? null
          : _decisionReasoningCtrl.text.trim()),
      decisionConfidence: Value(_isDecision ? _decisionConfidence : null),
      decisionExpectedOutcome: Value(_decisionExpectedCtrl.text.trim().isEmpty
          ? null
          : _decisionExpectedCtrl.text.trim()),
      decisionReviewDate: Value(_reviewDate),
      timestamp: Value(_timestamp),
    ));

    // Run PKI pipeline in background
    pki.process(id);

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickMultiImage();
    if (result.isEmpty) return;
    final storage = ref.read(fileStorageProvider);
    for (final xfile in result) {
      final att = await storage.saveFile(File(xfile.path));
      setState(() => _attachments.add(att));
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    final storage = ref.read(fileStorageProvider);
    for (final f in result.files) {
      if (f.path == null) continue;
      final att = await storage.saveFile(File(f.path!), customName: f.name);
      setState(() => _attachments.add(att));
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _voiceNotePath = path;
      });
    } else {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a');
      await _recorder.start(const RecordConfig(), path: path);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _togglePlayback() async {
    if (_voiceNotePath == null) return;
    if (_isPlaying) {
      await _player.stop();
      setState(() => _isPlaying = false);
    } else {
      await _player.setFilePath(_voiceNotePath!);
      _player.play();
      setState(() => _isPlaying = true);
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _isPlaying = false);
        }
      });
    }
  }

  Future<void> _pickTimestamp() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null) return;
    setState(() => _timestamp =
        DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final entitiesAsync = ref.watch(entitiesStreamProvider);
    final isEdit = widget.event != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Event' : 'New Event'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Timestamp
            InkWell(
              onTap: _pickTimestamp,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 18),
                    const SizedBox(width: 8),
                    Text('${_timestamp.day}/${_timestamp.month}/${_timestamp.year} '
                        '${_timestamp.hour.toString().padLeft(2, '0')}:${_timestamp.minute.toString().padLeft(2, '0')}'),
                    const Spacer(),
                    const Icon(Icons.edit, size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Note
            TextFormField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note *',
                hintText: 'What happened? What did you observe?',
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Mood
            const Text('Mood', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: moodEmojis.keys
                  .map((mood) => MoodChip(
                        mood: mood,
                        selected: _selectedMood == mood,
                        onTap: () => setState(() =>
                            _selectedMood =
                                _selectedMood == mood ? null : mood),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),

            // Importance
            const Text('Importance', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ImportanceSelector(
              value: _importance,
              onChanged: (v) => setState(() => _importance = v),
            ),
            const SizedBox(height: 16),

            // Location & Duration
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _durationMinutes?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Duration (min)',
                      prefixIcon: Icon(Icons.timer_outlined, size: 18),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (v) =>
                        _durationMinutes = int.tryParse(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Linked Entities
            const Text('Linked Entities',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            entitiesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (entities) => Wrap(
                spacing: 8,
                runSpacing: 6,
                children: entities
                    .map((entity) => FilterChip(
                          label: Text(entity.name),
                          selected: _linkedEntityIds.contains(entity.id),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _linkedEntityIds.add(entity.id);
                            } else {
                              _linkedEntityIds.remove(entity.id);
                            }
                          }),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Tags
            const Text('Tags', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Add tag...', isDense: true),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add_circle_outline)),
              ],
            ),
            if (_tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _tags
                      .map((t) => TagChip(
                            tag: t,
                            onDelete: () => setState(() => _tags.remove(t)),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),

            // Attachments
            const Text('Attachments',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Photos'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Files'),
                ),
              ],
            ),
            if (_attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _attachments
                      .map((att) => Chip(
                            avatar: Icon(_attachmentIcon(att.type), size: 16),
                            label: Text(att.name ?? 'File',
                                style: const TextStyle(fontSize: 12)),
                            onDeleted: () =>
                                setState(() => _attachments.remove(att)),
                          ))
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),

            // Voice Note
            const Text('Voice Note',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _toggleRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'Stop' : 'Record'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : null,
                  ),
                ),
                if (_voiceNotePath != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _togglePlayback,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    tooltip: _isPlaying ? 'Stop' : 'Play',
                  ),
                  IconButton(
                    onPressed: () => setState(() => _voiceNotePath = null),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete',
                  ),
                  const Text('Voice note recorded',
                      style: TextStyle(fontSize: 12, color: Colors.green)),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Custom Fields
            Row(
              children: [
                const Text('Custom Fields',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() =>
                      _customFields.add({'key': '', 'value': '', 'type': 'text'})),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                ),
              ],
            ),
            ..._customFields.asMap().entries.map((entry) {
              final i = entry.key;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Field name', isDense: true),
                        controller: TextEditingController(
                            text: _customFields[i]['key']),
                        onChanged: (v) => _customFields[i]['key'] = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                            hintText: 'Value', isDense: true),
                        controller: TextEditingController(
                            text: _customFields[i]['value']),
                        onChanged: (v) => _customFields[i]['value'] = v,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      onPressed: () =>
                          setState(() => _customFields.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),

            // Decision checkbox
            const Divider(height: 32),
            CheckboxListTile(
              value: _isDecision,
              onChanged: (v) => setState(() => _isDecision = v!),
              title: const Text('Mark as Decision',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Manually label this event as a decision for tracking'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            if (_isDecision) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Decision Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.amber)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _decisionOptionsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Options Considered (one per line)',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _decisionReasoningCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Reasoning at the time',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _decisionExpectedCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Expected Outcome'),
                    ),
                    const SizedBox(height: 12),
                    Text('Confidence Level: $_decisionConfidence / 10',
                        style: const TextStyle(fontSize: 13)),
                    Slider(
                      value: _decisionConfidence.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_decisionConfidence',
                      onChanged: (v) =>
                          setState(() => _decisionConfidence = v.toInt()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Review Date: ',
                            style: TextStyle(fontSize: 13)),
                        TextButton(
                          onPressed: _pickReviewDate,
                          child: Text(_reviewDate != null
                              ? '${_reviewDate!.day}/${_reviewDate!.month}/${_reviewDate!.year}'
                              : 'Set date'),
                        ),
                        if (_reviewDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () =>
                                setState(() => _reviewDate = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReviewDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reviewDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _reviewDate = picked);
  }

  IconData _attachmentIcon(AttachmentType type) {
    switch (type) {
      case AttachmentType.image: return Icons.image;
      case AttachmentType.video: return Icons.videocam;
      case AttachmentType.audio: return Icons.audiotrack;
      case AttachmentType.pdf: return Icons.picture_as_pdf;
      default: return Icons.insert_drive_file;
    }
  }
}
