import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'core/providers/providers.dart';
import 'features/shell/main_shell.dart';
import 'features/package/package_setup_screen.dart';
import 'core/services/atlas_package_service.dart';
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

  // _check is passed as onReady callback to AtlasSplashScreen,
  // which calls it after its stage animations complete.
  Future<void> _check() async {
    final dir = await AtlasPackageService.getActivePackageDir();
    if (!mounted) return;
    setState(() {
      _hasPackage = dir != null;
      _splashDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return AtlasSplashScreen(onReady: _check);
    }
    return _hasPackage ? const MainShell() : const PackageSetupScreen();
  }
}
