import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/providers.dart';
import '../../core/services/atlas_package_service.dart';
import '../search/search_screen.dart';
import '../package/package_setup_screen.dart';


class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _modelPath;
  bool _loadingModel = false;
  String _loadingStatus = '';
  Map<String, dynamic> _packageMeta = {};
  String? _packageDir;

  @override
  void initState() {
    super.initState();
    _loadModelPath();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final meta = await AtlasPackageService.getPackageMeta();
    final dir  = await AtlasPackageService.getActivePackageDir();
    setState(() { _packageMeta = meta; _packageDir = dir; });
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
      withData: false,
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return;

    final pickedPath = result.files.first.path;
    if (pickedPath == null) return;

    final ext = pickedPath.toLowerCase();
    if (!supportedGemmaModelExtensions.any(ext.endsWith)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsupported model format. Please choose a .task or .bin file.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final srcFile = File(pickedPath);
    final srcSize = await srcFile.length();
    if (srcSize < 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File too small (${srcSize} bytes) - not a valid model file'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _loadingModel = true;
      _loadingStatus = 'Copying model (${(srcSize / 1024 / 1024).toStringAsFixed(0)} MB)�';
    });

    final String destPath;
    try {
      destPath = await AtlasPackageService.installModelFile(pickedPath);
      final destSize = await File(destPath).length();
      if (destSize != srcSize) {
        throw Exception('Copy incomplete: $destSize / $srcSize bytes');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingModel = false;
          _loadingStatus = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy model: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _loadingStatus = 'Loading model into memory�');
    final db = ref.read(databaseProvider);
    await db.setSetting('gemma_model_path', destPath);
    await ref.read(gemmaServiceProvider.notifier).loadModel(destPath);

    setState(() {
      _modelPath = destPath;
      _loadingModel = false;
      _loadingStatus = '';
    });

    if (mounted) {
      final state = ref.read(gemmaServiceProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.isLoaded
              ? 'AI model loaded successfully'
              : 'Failed to load model: ${state.error ?? 'Unknown error'}'),
          backgroundColor: state.isLoaded ? Colors.green : Colors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _exportPackage() async {
    setState(() => _loadingStatus = 'Exporting…');
    try {
      final path = await AtlasPackageService.exportPackage();
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Atlas Package Export'),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loadingStatus = '');
    }
  }

  Future<void> _importPackage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() => _loadingStatus = 'Importing…');
    try {
      await AtlasPackageService.importPackage(path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package imported. Restart the app to apply.')),
        );
        await _loadPackageInfo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _loadingStatus = '');
    }
  }

  Future<void> _switchPackage() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PackageSetupScreen()),
    );
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
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                      if (_loadingStatus.isNotEmpty)
                        Text(_loadingStatus,
                            style: const TextStyle(fontSize: 9)),
                    ],
                  )
                : TextButton(
                    onPressed: _pickModel,
                    child: const Text('Browse'),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Select a Gemma .task or .bin model file to enable full AI reasoning.',
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

          // Atlas Package
          _SectionTitle(title: 'Atlas Package'),
          if (_packageMeta.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.folder_special_outlined),
              title: Text(_packageMeta['name'] as String? ?? 'Unknown'),
              subtitle: Text(
                _packageDir ?? '',
                style: const TextStyle(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export Package'),
            subtitle: const Text('Compress & share your .atlas package'),
            trailing: _loadingStatus == 'Exporting…'
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _exportPackage,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import Package'),
            subtitle: const Text('Restore from a .atlas file'),
            trailing: _loadingStatus == 'Importing…'
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _importPackage,
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz_outlined),
            title: const Text('Switch Package'),
            subtitle: const Text('Create or open a different package'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _switchPackage,
          ),

          // Data
          _SectionTitle(title: 'Data'),
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








