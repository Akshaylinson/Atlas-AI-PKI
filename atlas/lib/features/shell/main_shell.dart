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

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _screens = [
    AnalyticsScreen(),
    EntitiesScreen(),
    EventsScreen(),
    AIChatScreen(),
    DecisionsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(_navIndexProvider);
    return Scaffold(
      body: _screens[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) =>
            ref.read(_navIndexProvider.notifier).state = i,
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
