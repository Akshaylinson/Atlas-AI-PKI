import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

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
      home: const MainShell(),
    );
  }
}
