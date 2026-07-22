import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../shared/utils/utils.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(aiChatProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear chat',
            onPressed: () => ref.read(aiChatProvider.notifier).clear(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showModelInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Model status banner
          _ModelStatusBanner(),

          // Messages
          Expanded(
            child: messages.isEmpty
                ? _WelcomeView(onSuggestionTap: (q) {
                    _inputCtrl.text = q;
                    _send();
                  })
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == messages.length) {
                        return const _TypingIndicator();
                      }
                      return _MessageBubble(message: messages[i]);
                    },
                  ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(
                  top: BorderSide(color: scheme.outlineVariant.withOpacity(0.3))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'Ask about your data...',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    maxLines: 3,
                    minLines: 1,
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showModelInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI Model Info'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atlas uses a local Gemma model for reasoning.'),
            SizedBox(height: 8),
            Text('• All processing happens on-device'),
            Text('• No data leaves your phone'),
            Text('• AI only reasons over your recorded evidence'),
            Text('• AI never invents statistics'),
            SizedBox(height: 12),
            Text('To enable full AI: place a Gemma GGUF model file in the app\'s models folder and configure the path in Settings.',
                style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK')),
        ],
      ),
    );
  }
}

class _ModelStatusBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gemmaServiceProvider);
    final modelInstall = ref.watch(modelInstallProvider);

    if (state.isLoaded) return const SizedBox.shrink();

    if (state.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.blue.withOpacity(0.1),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
            ),
            SizedBox(width: 8),
            Text(
              'Loading Gemma model, please wait…',
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      );
    }

    // Model install is still resolving
    if (modelInstall.isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.blue.withOpacity(0.1),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
            ),
            SizedBox(width: 8),
            Text('Initialising AI model…',
                style: TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
      );
    }

    if (state.error != null) {
      // Show as orange info, not red error — evidence mode is fully functional
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.withOpacity(0.1),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Running in evidence-only mode. Answers are based on your recorded data.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    // No model configured at all
    final savedPath = modelInstall.value;
    if (savedPath == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.orange.withOpacity(0.1),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Running in evidence-only mode. Configure Gemma model in Settings for full AI.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }

    // Path is saved but model not loaded yet — trigger load
    ref.listen(modelInstallProvider, (_, next) {
      next.whenData((path) {
        if (path != null && !ref.read(gemmaServiceProvider).isLoaded) {
          ref.read(gemmaServiceProvider.notifier).loadModel(path);
        }
      });
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.orange.withOpacity(0.1),
      child: const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          ),
          SizedBox(width: 8),
          Text('Loading saved model…',
              style: TextStyle(fontSize: 12, color: Colors.orange)),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  final ValueChanged<String> onSuggestionTap;

  const _WelcomeView({required this.onSuggestionTap});

  static const _suggestions = [
    'What patterns have you found in my data?',
    'How has my mood been this month?',
    'Show me my most active entities',
    'What decisions are due for review?',
    'What happened with my recent events?',
    'Which entities appear most frequently together?',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.psychology, size: 64, color: scheme.primary.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text('Ask Atlas anything about your data',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Atlas reasons over your recorded events, entities, and patterns to give evidence-based answers.',
          style: TextStyle(color: scheme.onSurface.withOpacity(0.6)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const Text('Suggestions',
            style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ..._suggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onSuggestionTap(s),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: scheme.outlineVariant.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: scheme.primary),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: const TextStyle(fontSize: 13))),
                      const Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primaryContainer,
              child: const Text('A', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? scheme.onPrimary : scheme.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRelative(message.timestamp),
                  style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurface.withOpacity(0.4)),
                ),
                // Evidence context chip
                if (!isUser && message.context != null)
                  _EvidenceChip(context: message.context!),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: scheme.secondaryContainer,
              child: const Icon(Icons.person, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceChip extends StatelessWidget {
  final Map<String, dynamic> context;

  const _EvidenceChip({required this.context});

  @override
  Widget build(BuildContext context) {
    final events = (this.context['events'] as List?)?.length ?? 0;
    final entities = (this.context['entities'] as List?)?.length ?? 0;
    final patterns = (this.context['patterns'] as List?)?.length ?? 0;

    if (events == 0 && entities == 0 && patterns == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: [
          if (events > 0)
            _SmallChip(label: '$events events', icon: Icons.event_note),
          if (entities > 0)
            _SmallChip(label: '$entities entities', icon: Icons.category),
          if (patterns > 0)
            _SmallChip(label: '$patterns patterns', icon: Icons.pattern),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SmallChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: scheme.primary),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(fontSize: 10, color: scheme.primary)),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primaryContainer,
            child: const Text('A', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Dot(delay: 0),
                SizedBox(width: 4),
                _Dot(delay: 200),
                SizedBox(width: 4),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.3, end: 1.0).animate(_ctrl);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
