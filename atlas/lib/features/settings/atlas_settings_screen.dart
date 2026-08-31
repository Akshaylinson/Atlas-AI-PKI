import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/providers.dart';
import '../../core/services/atlas_package_service.dart';
import '../../core/services/model_loader.dart';
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
  List<String> _validationIssues = [];
  String _storageSize = '';
  final _apiKeyCtrl = TextEditingController();
  bool _showApiKey = false;

  @override
  void initState() {
    super.initState();
    _loadModelPath();
    _loadPackageInfo();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final meta = await AtlasPackageService.getPackageMeta();
    final dir = await AtlasPackageService.getActivePackageDir();
    final validation = await AtlasPackageService.validateActivePackage();
    final size = dir != null ? await _calcDirSize(dir) : '';
    if (!mounted) return;
    setState(() {
      _packageMeta = meta;
      _packageDir = dir;
      _validationIssues = validation.issues;
      _storageSize = size;
    });
  }

  Future<void> _loadModelPath() async {
    final path = await ref.read(databaseProvider).getSetting('gemma_model_path');
    if (!mounted) return;
    setState(() => _modelPath = path);
  }

  Future<void> _loadApiKey() async {
    final key = await ref.read(databaseProvider).getSetting('openrouter_api_key');
    if (!mounted) return;
    _apiKeyCtrl.text = key ?? '';
  }

  String _fmtBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  Future<String> _calcDirSize(String dirPath) async {
    try {
      int total = 0;
      await for (final e in Directory(dirPath).list(recursive: true, followLinks: false)) {
        if (e is File) total += await e.length();
      }
      return _fmtBytes(total);
    } catch (_) {
      return 'unknown';
    }
  }

  // ── Local Gemma model ──────────────────────────────────────────────────────

  Future<void> _pickModel() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any, withData: false);
    if (result == null || result.files.isEmpty) return;
    final pickedPath = result.files.first.path;
    if (pickedPath == null) return;

    if (!supportedGemmaModelExtensions.any(pickedPath.toLowerCase().endsWith)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unsupported format. Choose a Gemma .task or .bin file.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final srcSize = await File(pickedPath).length();
    if (srcSize < 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('File too small ($srcSize bytes) — not a valid model.'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() { _loadingModel = true; _loadingStatus = 'Copying model (${(srcSize / 1024 / 1024).toStringAsFixed(0)} MB)…'; });

    String destPath;
    try {
      destPath = await AtlasPackageService.installModelFile(pickedPath);
      if (await File(destPath).length() != srcSize) throw Exception('Copy incomplete');
    } catch (e) {
      if (!mounted) return;
      setState(() { _loadingModel = false; _loadingStatus = ''; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Copy failed: $e'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _loadingStatus = 'Loading model into memory…');
    await ref.read(databaseProvider).setSetting('gemma_model_path', destPath);
    await ref.read(gemmaServiceProvider.notifier).loadModel(destPath);
    if (!mounted) return;
    setState(() { _modelPath = destPath; _loadingModel = false; _loadingStatus = ''; });

    final s = ref.read(gemmaServiceProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(s.isLoaded ? 'Gemma model loaded ✓' : 'Load failed: ${s.error ?? 'unknown'}'),
      backgroundColor: s.isLoaded ? Colors.green : Colors.red,
    ));
  }

  Future<void> _unloadModel() async {
    await ref.read(gemmaServiceProvider.notifier).unloadModel();
    await ref.read(databaseProvider).setSetting('gemma_model_path', '');
    if (!mounted) return;
    setState(() => _modelPath = null);
    // If local mode was active, switch off
    if (ref.read(aiModeProvider) == AiMode.local) {
      await ref.read(aiModeProvider.notifier).set(AiMode.off);
    }
  }

  // ── OpenRouter API ─────────────────────────────────────────────────────────

  Future<void> _saveApiKey() async {
    final key = _apiKeyCtrl.text.trim();
    await ref.read(databaseProvider).setSetting('openrouter_api_key', key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved')),
    );
  }

  // ── Package actions ────────────────────────────────────────────────────────

  Future<void> _exportPackage() async {
    setState(() => _loadingStatus = 'Exporting…');
    try {
      final path = await AtlasPackageService.exportPackage();
      await SharePlus.instance.share(ShareParams(files: [XFile(path)], text: 'Atlas Package Export'));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loadingStatus = '');
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Package imported. Restart to apply.')));
      await _loadPackageInfo();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loadingStatus = '');
    }
  }

  Future<void> _clearAllData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('Permanently deletes ALL entities, events, patterns and statistics. Cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final db = ref.read(databaseProvider);
    for (final e in await db.getAllEntities()) await db.deleteEntity(e.id);
    for (final e in await db.getAllEvents()) await db.deleteEvent(e.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared')));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final aiMode = ref.watch(aiModeProvider);
    final modelState = ref.watch(gemmaServiceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [

          // ── Appearance ───────────────────────────────────────────────────
          _SectionTitle(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: 16)),
                ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: 16)),
                ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: 16)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).state = s.first,
            ),
          ),

          // ── AI Mode ──────────────────────────────────────────────────────
          _SectionTitle(title: 'AI Mode'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _AiModeCard(
                    icon: Icons.memory_outlined,
                    label: 'Local AI',
                    sublabel: 'Gemma on-device\n.task / .bin model',
                    active: aiMode == AiMode.local,
                    statusColor: aiMode == AiMode.local
                        ? (modelState.isLoading ? Colors.orange : modelState.isLoaded ? Colors.green : Colors.red)
                        : Colors.grey,
                    statusLabel: aiMode == AiMode.local
                        ? (modelState.isLoading ? 'Loading…' : modelState.isLoaded ? 'Ready' : 'Not loaded')
                        : 'Off',
                    onTap: () => ref.read(aiModeProvider.notifier).set(
                      aiMode == AiMode.local ? AiMode.off : AiMode.local,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AiModeCard(
                    icon: Icons.cloud_outlined,
                    label: 'OpenRouter',
                    sublabel: 'Cloud API\nRequires internet',
                    active: aiMode == AiMode.api,
                    statusColor: aiMode == AiMode.api ? Colors.green : Colors.grey,
                    statusLabel: aiMode == AiMode.api ? 'Active' : 'Off',
                    onTap: () => ref.read(aiModeProvider.notifier).set(
                      aiMode == AiMode.api ? AiMode.off : AiMode.api,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Local Gemma model ────────────────────────────────────────────
          _SectionTitle(title: 'Local Gemma Model'),
          ListTile(
            leading: Icon(Icons.psychology_outlined,
                color: modelState.isLoaded ? Colors.green : scheme.onSurface.withOpacity(0.5)),
            title: const Text('Model File'),
            subtitle: Text(
              _modelPath != null && _modelPath!.isNotEmpty
                  ? _modelPath!.split('/').last
                  : 'No model — download a Gemma .task or .bin file',
              style: TextStyle(
                fontSize: 12,
                color: _modelPath != null && _modelPath!.isNotEmpty ? Colors.green : Colors.orange,
              ),
            ),
            trailing: _loadingModel
                ? Column(mainAxisSize: MainAxisSize.min, children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    if (_loadingStatus.isNotEmpty) Text(_loadingStatus, style: const TextStyle(fontSize: 9)),
                  ])
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(onPressed: _pickModel, child: const Text('Browse')),
                    if (_modelPath != null && _modelPath!.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: 'Unload model',
                        onPressed: _unloadModel,
                      ),
                  ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Download: kaggle.com/models/google/gemma/frameworks/tfLite\n'
              'Recommended: gemma-2b-it-gpu-int4.bin (~1.3 GB)',
              style: TextStyle(fontSize: 11, color: scheme.onSurface.withOpacity(0.45)),
            ),
          ),

          // ── OpenRouter API ───────────────────────────────────────────────
          _SectionTitle(title: 'OpenRouter API'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _apiKeyCtrl,
              obscureText: !_showApiKey,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'API Key',
                helperText: 'Get a free key at openrouter.ai',
                suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(_showApiKey ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _showApiKey = !_showApiKey),
                  ),
                  IconButton(
                    icon: const Icon(Icons.save_outlined),
                    tooltip: 'Save',
                    onPressed: _saveApiKey,
                  ),
                ]),
              ),
              onSubmitted: (_) => _saveApiKey(),
            ),
          ),

          // ── Search ───────────────────────────────────────────────────────
          _SectionTitle(title: 'Search'),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Open Search'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
          ),

          // ── Atlas Package ────────────────────────────────────────────────
          _SectionTitle(title: 'Atlas Package'),
          if (_packageMeta.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.folder_special_outlined),
              title: Text(_packageMeta['package_id'] as String? ?? _packageMeta['name'] as String? ?? 'Unknown'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_packageDir ?? '', style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (_storageSize.isNotEmpty)
                    Text('Size: $_storageSize', style: const TextStyle(fontSize: 11)),
                  if (_validationIssues.isNotEmpty)
                    Text('⚠ ${_validationIssues.length} issue(s)', style: const TextStyle(fontSize: 11, color: Colors.orange))
                  else
                    const Text('✓ Valid', style: TextStyle(fontSize: 11, color: Colors.green)),
                ],
              ),
              isThreeLine: true,
            ),
          ListTile(
            leading: const Icon(Icons.verified_outlined),
            title: const Text('Validate Package'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await _loadPackageInfo();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(_validationIssues.isEmpty ? 'Package is valid ✓' : 'Issues: ${_validationIssues.join(', ')}'),
                backgroundColor: _validationIssues.isEmpty ? Colors.green : Colors.orange,
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Export Package (.atlas)'),
            trailing: _loadingStatus == 'Exporting…'
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _exportPackage,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import Package'),
            trailing: _loadingStatus == 'Importing…'
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right),
            onTap: _importPackage,
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz_outlined),
            title: const Text('Switch Package'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PackageSetupScreen()),
            ),
          ),

          // ── Data ─────────────────────────────────────────────────────────
          _SectionTitle(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
            subtitle: const Text('Permanently delete everything'),
            onTap: _clearAllData,
          ),

          // ── Host Capabilities ─────────────────────────────────────────────
          _SectionTitle(title: 'Host Capabilities'),
          Consumer(builder: (context, ref, _) {
            final capAsync = ref.watch(hostCapabilityProvider);
            return capAsync.when(
              loading: () => const ListTile(leading: Icon(Icons.memory_outlined), title: Text('Detecting…')),
              error: (_, __) => const ListTile(leading: Icon(Icons.memory_outlined), title: Text('Detection unavailable')),
              data: (cap) => Column(children: [
                ListTile(
                  leading: const Icon(Icons.memory_outlined),
                  title: Text('${cap.os} / ${cap.architecture}'),
                  subtitle: Text(
                    '${cap.cpuCores} cores'
                    '${cap.ramGb > 0 ? ' · ${cap.ramGb.toStringAsFixed(1)} GB RAM' : ''}'
                    '${cap.gpuAvailable ? ' · GPU: ${cap.gpuType}' : ''}',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('AI Runtime'),
                  subtitle: Text(cap.aiRuntime, style: const TextStyle(fontSize: 11)),
                ),
              ]),
            );
          }),

          // ── About ─────────────────────────────────────────────────────────
          _SectionTitle(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Atlas'),
            subtitle: Text('Portable Personal Intelligence System\nVersion 2.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy'),
            subtitle: Text('All data is stored locally in your Atlas Package. Nothing is sent to any server unless OpenRouter API mode is active.'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── AI Mode Card widget ────────────────────────────────────────────────────────

class _AiModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool active;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _AiModeCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.active,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? scheme.primaryContainer.withOpacity(0.5) : scheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? scheme.primary : scheme.outlineVariant.withOpacity(0.5),
            width: active ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: active ? scheme.primary : scheme.onSurface.withOpacity(0.5)),
              const Spacer(),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ]),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: active ? scheme.primary : scheme.onSurface)),
            const SizedBox(height: 2),
            Text(sublabel, style: TextStyle(fontSize: 10, color: scheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 6),
            Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ],
        ),
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
