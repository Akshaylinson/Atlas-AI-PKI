import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/providers.dart';
import '../../core/database/app_database.dart';
import '../../core/services/atlas_package_service.dart';
import '../../core/services/model_loader.dart';
import '../../shared/widgets/widgets.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/utils/utils.dart';
import '../knowledge_graph/knowledge_graph_screen.dart';
import '../package/package_setup_screen.dart';
import '../patterns/patterns_screen.dart';
import '../search/search_screen.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atlas', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'Knowledge Graph',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const KnowledgeGraphScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.pattern),
            tooltip: 'Patterns',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const PatternsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const _AnalyticsSettingsScreen()),
            ),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardStatsProvider.future),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  StatCard(
                    label: 'Total Events',
                    value: stats.totalEvents.toString(),
                    icon: Icons.event_note,
                    color: Colors.blue,
                  ),
                  StatCard(
                    label: 'Entities',
                    value: stats.totalEntities.toString(),
                    icon: Icons.category,
                    color: Colors.purple,
                  ),
                  StatCard(
                    label: 'Patterns Found',
                    value: stats.patternCount.toString(),
                    icon: Icons.pattern,
                    color: Colors.teal,
                  ),
                  StatCard(
                    label: 'High Confidence',
                    value: stats.highConfidencePatterns.toString(),
                    icon: Icons.verified,
                    color: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (stats.moodDistribution.isNotEmpty) ...[
                const SectionHeader(title: 'Mood Distribution'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: _MoodPieChart(distribution: stats.moodDistribution),
                ),
                const SizedBox(height: 24),
              ],
              eventsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Activity (Last 30 Days)'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 160,
                        child: _ActivityBarChart(events: events),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
              if (stats.recentEvents.isNotEmpty) ...[
                const SectionHeader(title: 'Recent Events'),
                const SizedBox(height: 12),
                ...stats.recentEvents.map((e) => _RecentEventTile(event: e)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodPieChart extends StatelessWidget {
  final Map<String, int> distribution;

  const _MoodPieChart({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final total = distribution.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    final sections = distribution.entries.map((e) {
      final color = moodColors[e.key] ?? Colors.grey;
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        title:
            '${moodEmojis[e.key] ?? ''}\n${((e.value / total) * 100).toStringAsFixed(0)}%',
        radius: 70,
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(PieChartData(sections: sections, sectionsSpace: 2));
  }
}

class _ActivityBarChart extends StatelessWidget {
  final List<Event> events;

  const _ActivityBarChart({required this.events});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final last30 =
        List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));
    final counts = <int, int>{};
    for (final e in events) {
      final diff = now.difference(e.timestamp).inDays;
      if (diff < 30) counts[29 - diff] = (counts[29 - diff] ?? 0) + 1;
    }

    final bars = last30.asMap().entries.map((entry) {
      final count = counts[entry.key] ?? 0;
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      );
    }).toList();

    return BarChart(BarChartData(
      barGroups: bars,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 7,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx < 0 || idx >= last30.length) {
                return const SizedBox.shrink();
              }
              final day = last30[idx];
              return Text('${day.day}/${day.month}',
                  style: const TextStyle(fontSize: 9));
            },
          ),
        ),
      ),
    ));
  }
}

class _RecentEventTile extends StatelessWidget {
  final Event event;

  const _RecentEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          if (event.mood != null)
            Text(moodEmojis[event.mood] ?? '😐',
                style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(truncate(event.note, 80),
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 2),
                Text(formatRelative(event.timestamp),
                    style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          _ImportanceDot(importance: event.importance),
        ],
      ),
    );
  }
}

class _ImportanceDot extends StatelessWidget {
  final int importance;

  const _ImportanceDot({required this.importance});

  @override
  Widget build(BuildContext context) {
    final color = importanceColors[importance] ?? Colors.grey;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AnalyticsSettingsScreen extends ConsumerStatefulWidget {
  const _AnalyticsSettingsScreen();

  @override
  ConsumerState<_AnalyticsSettingsScreen> createState() =>
      _AnalyticsSettingsScreenState();
}

class _AnalyticsSettingsScreenState
    extends ConsumerState<_AnalyticsSettingsScreen> {
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
    final dir = await AtlasPackageService.getActivePackageDir();
    if (!mounted) return;
    setState(() {
      _packageMeta = meta;
      _packageDir = dir;
    });
  }

  Future<void> _loadModelPath() async {
    final db = ref.read(databaseProvider);
    final path = await db.getSetting('gemma_model_path');
    if (!mounted) return;
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
            content: Text('File too small ($srcSize bytes) - not a valid model file'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _loadingModel = true;
      _loadingStatus = 'Copying model ${(srcSize / 1024 / 1024).toStringAsFixed(0)} MB...';
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

    setState(() => _loadingStatus = 'Loading model into memory…');
    final db = ref.read(databaseProvider);
    await db.setSetting('gemma_model_path', destPath);
    await ref.read(gemmaServiceProvider.notifier).loadModel(destPath);

    if (!mounted) return;
    setState(() {
      _modelPath = destPath;
      _loadingModel = false;
      _loadingStatus = '';
    });

    final state = ref.read(gemmaServiceProvider);
    final errorText = state.error ?? 'Unknown error';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state.isLoaded ? 'AI model loaded successfully' : 'Failed to load model: $errorText',
        ),
        backgroundColor: state.isLoaded ? Colors.green : Colors.red,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Future<void> _exportPackage() async {
    setState(() => _loadingStatus = 'Exporting...');
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
      if (mounted) setState(() => _loadingStatus = '');
    }
  }

  Future<void> _importPackage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    setState(() => _loadingStatus = 'Importing...');
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
      if (mounted) setState(() => _loadingStatus = '');
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
          'This will permanently delete ALL entities, events, patterns, and statistics. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
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
    for (final e in entities) {
      await db.deleteEntity(e.id);
    }
    for (final e in events) {
      await db.deleteEvent(e.id);
    }

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
          const _SettingsSectionTitle(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Theme'),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 16),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 16),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).state = s.first,
            ),
          ),
          const _SettingsSectionTitle(title: 'AI Model (Gemma)'),
          ListTile(
            leading: const Icon(Icons.psychology_outlined),
            title: const Text('Model File'),
            subtitle: Text(
              _modelPath ?? 'No model loaded',
              style: TextStyle(
                fontSize: 12,
                color: _modelPath != null ? Colors.green : Colors.orange,
              ),
            ),
            trailing: _loadingModel
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      if (_loadingStatus.isNotEmpty)
                        Text(_loadingStatus, style: const TextStyle(fontSize: 9)),
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
                color: scheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          const _SettingsSectionTitle(title: 'Search'),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Open Search'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          const _SettingsSectionTitle(title: 'Atlas Package'),
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
            trailing: _loadingStatus == 'Exporting...'
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _exportPackage,
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Import Package'),
            subtitle: const Text('Restore from a .atlas file'),
            trailing: _loadingStatus == 'Importing...'
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
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
          const _SettingsSectionTitle(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
            title: const Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('Permanently delete everything'),
            onTap: _clearAllData,
          ),
          const _SettingsSectionTitle(title: 'About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Atlas'),
            subtitle: Text('Personal Intelligence Operating System\nVersion 1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Privacy'),
            subtitle: Text(
              'All data is stored locally on your device. Nothing is sent to any server.',
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final String title;

  const _SettingsSectionTitle({required this.title});

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

