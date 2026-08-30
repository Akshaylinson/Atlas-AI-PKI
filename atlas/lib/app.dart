import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'features/shell/main_shell.dart';
import 'features/package/package_setup_screen.dart';
import 'core/services/atlas_package_service.dart';
import 'core/services/atlas_storage.dart';
import 'splash_screen.dart';

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
  bool _splashDone = false;
  bool _hasPackage = false;
  String? _bootIssue;

  // _check is passed as onReady callback to AtlasSplashScreen,
  // which calls it after its stage animations complete.
  Future<void> _check() async {
    final dir = await AtlasPackageService.getActivePackageDir();
    if (!mounted) return;
    if (dir == null) {
      setState(() {
        _hasPackage = false;
        _splashDone = true;
        _bootIssue = null;
      });
      return;
    }

    final validation = await AtlasPackageService.validateActivePackage();
    if (!mounted) return;

    if (validation.isValid) {
      await AtlasStorage.beginSession();
    }

    setState(() {
      _hasPackage = validation.isValid;
      _splashDone = true;
      _bootIssue = validation.issues.isNotEmpty ? validation.issues.join('\n') : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return AtlasSplashScreen(onReady: _check);
    }
    if (_hasPackage) return const MainShell();
    return PackageSetupScreen(key: ValueKey(_bootIssue ?? 'no-package'));
  }
}
