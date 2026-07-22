import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'features/shell/main_shell.dart';
import 'features/package/package_setup_screen.dart';
import 'core/services/atlas_package_service.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class AtlasApp extends ConsumerWidget {
  const AtlasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: 'Atlas',
      theme: AtlasTheme.light,
      darkTheme: AtlasTheme.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      home: const _StartupRouter(),
    );
  }
}

class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  bool _checking = true;
  bool _hasPackage = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final dir = await AtlasPackageService.getActivePackageDir();
    setState(() {
      _hasPackage = dir != null;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _hasPackage ? const MainShell() : const PackageSetupScreen();
  }
}
