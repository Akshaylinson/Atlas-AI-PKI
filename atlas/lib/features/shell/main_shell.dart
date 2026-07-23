import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../analytics/analytics_screen.dart';
import '../entities/entities_screen.dart';
import '../entities/entity_form_screen.dart';
import '../events/events_screen.dart';
import '../events/event_form_screen.dart';
import '../ai_chat/ai_chat_screen.dart';
import '../decisions/decisions_screen.dart';

final _navIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  final List<Widget?> _loadedScreens = List<Widget?>.filled(5, null);

  @override
  void initState() {
    super.initState();
    _loadedScreens[0] = const AnalyticsScreen();
  }

  Widget _screenFor(int index) {
    return _loadedScreens[index] ??= switch (index) {
      0 => const AnalyticsScreen(),
      1 => const EntitiesScreen(),
      2 => const EventsScreen(),
      3 => const AIChatScreen(),
      _ => const DecisionsScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(_navIndexProvider);
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: List.generate(
          5,
          (i) => _loadedScreens[i] ?? const SizedBox.shrink(),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() {
            ref.read(_navIndexProvider.notifier).state = i;
            _loadedScreens[i] = _screenFor(i);
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Entities',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outlined),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Decisions',
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, index),
    );
  }

  Widget? _buildFAB(BuildContext context, int index) {
    if (index == 1) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EntityFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Entity'),
      );
    }
    if (index == 2) {
      return FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
      );
    }
    return null;
  }
}
