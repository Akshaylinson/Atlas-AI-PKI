import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../app.dart';
import '../../core/providers/providers.dart';
import '../search/search_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _modelPath;
  bool _loadingModel = false;

  @override
  void initState() {
    super.initState();
    _loadModelPath();
  }

  Future<void> _loadModelPath() async {
    final db = ref.read(databaseProvider);
    final path = await db.getSetting('gemma_model_path');
    setState(() => _modelPath = path);
  }

  Future<void> _pickModel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;

    setState(() => _loadingModel = true);
    final db = ref.read(databaseProvider);
    await db.setSetting('gemma_model_path', path);

    await ref.read(gemmaServiceProvider.notifier).loadModel(path);

    setState(() {
      _modelPath = path;
      _loadingModel = false;
    });

    if (mounted) {
      final state = ref.read(gemmaServiceProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.isLoaded
              ? 'Gemma model loaded successfully'
              : 'Failed to load model: ${state.error ?? 'Unknown error'}'),
          backgroundColor: state.isLoaded ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _exportData() async {
    final db = ref.read(databaseProvider);
    final entities = await db.getAllEntities();
    final events = await db.getAllEvents();

    final buffer = StringBuffer();
    buffer.writeln('Atlas Data Export');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');
    buffer.writeln('=== ENTITIES (${entities.length}) ===');
    for (final e in entities) {
      buffer.writeln('- ${e.name}: ${e.description ?? ''}');
    }
    buffer.writeln('');
    buffer.writeln('=== EVENTS (${events.length}) ===');
    for (final e in events) {
      buffer.writeln('[${e.timestamp}] ${e.note}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/atlas_export_${DateTime.now().millisecondsSinceEpoch}.txt');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Atlas Data Export'));
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
            'This will permanently delete ALL entities, events, patterns, and statistics. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    final entities = await db.getAllEntities();
    final events = await db.getAllEvents();
    for (final e in entities) { await db.deleteEntity(e.id); }
    for (final e in events) { await db.deleteEvent(e.id); }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance
          _SectionTitle(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light,
                    icon: Icon(Icons.light_mode, size: 16)),
                ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto, size: 16)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.dark_mode, size: 16)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).state = s.first,
            ),
          ),

          // AI Model
          _SectionTitle(title: 'AI Model (Gemma)'),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Model File'),
            subtitle: Text(
              _modelPath ?? 'No model loaded',
              style: TextStyle(
                  fontSize: 12,
                  color: _modelPath != null ? Colors.green : Colors.orange),
            ),
            trailing: _loadingModel
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(
                    onPressed: _pickModel,
                    child: const Text('Browse'),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Place a Gemma GGUF model file on your device and select it here to enable full AI reasoning.',
              style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.5)),
            ),
          ),

          // Search
          _SectionTitle(title: 'Search'),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Open Search'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),

          // Data
          _SectionTitle(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export Data'),
            subtitle: const Text('Share a text export of all your data'),
            onTap: _exportData,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Clear All Data',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently delete everything'),
            onTap: _clearAllData,
          ),

          // About
          _SectionTitle(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Atlas'),
            subtitle: Text('Personal Intelligence Operating System\nVersion 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy'),
            subtitle: Text('All data is stored locally on your device. Nothing is sent to any server.'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}


