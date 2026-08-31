import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import 'package:atlas/shared/utils/utils.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    _inputCtrl.clear();
    setState(() => _sending = true);
    await ref.read(aiChatProvider.notifier).sendMessage(text);
    if (!mounted) return;
    setState(() => _sending = false);
    _inputFocus.requestFocus();
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
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Assistant',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const _ModelToggle(),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Chat',
            onPressed: () => ref.read(aiChatProvider.notifier).clear(),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showModelInfo(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _ChatTranscript(
                scrollCtrl: _scrollCtrl,
                onSuggestionTap: (q) {
                  _inputCtrl.text = q;
                  _inputFocus.requestFocus();
                  _send();
                },
                showTypingIndicator: _sending,
              ),
            ),
            _ChatComposer(
              controller: _inputCtrl,
              focusNode: _inputFocus,
              sending: _sending,
              onSend: _send,
              surfaceColor: scheme.surface,
              outlineColor: scheme.outlineVariant.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('AI Assistant Info'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atlas answers from your local knowledge base.'),
            SizedBox(height: 8),
            Text('• Local processing uses Gemma .task / .bin models'),
            Text('• OpenRouter is available when cloud inference is needed'),
            Text('• AI only reasons over your recorded evidence'),
            Text('• AI never invents statistics'),
            SizedBox(height: 12),
            Text(
              'To enable local AI, place a Gemma model file in the app\'s models folder and select Local AI in Settings.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _ChatTranscript extends ConsumerWidget {
  final ScrollController scrollCtrl;
  final ValueChanged<String> onSuggestionTap;
  final bool showTypingIndicator;

  const _ChatTranscript({
    required this.scrollCtrl,
    required this.onSuggestionTap,
    required this.showTypingIndicator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(aiChatProvider);

    if (messages.isEmpty) {
      return _WelcomeView(onSuggestionTap: onSuggestionTap);
    }

    return ListView.builder(
      controller: scrollCtrl,
      padding: const EdgeInsets.all(16),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
      itemCount: messages.length + (showTypingIndicator ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == messages.length) {
          return const _TypingIndicator();
        }
        return _MessageBubble(message: messages[i]);
      },
    );
  }
}

class _ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final Future<void> Function() onSend;
  final Color surfaceColor;
  final Color outlineColor;

  const _ChatComposer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.surfaceColor,
    required this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top: BorderSide(color: outlineColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Ask about your data...',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: 3,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                onSend();
              },
            ),
          ),
          const SizedBox(width: 4),
          sending
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: onSend,
                ),
        ],
      ),
    );
  }
}

// Persistent AppBar toggle cycling: off → local → api → off
class _ModelToggle extends ConsumerWidget {
  const _ModelToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(aiModeProvider);
    final modelState = ref.watch(gemmaServiceProvider);

    final Color color;
    final IconData iconData;
    final String label;

    if (mode == AiMode.api) {
      color = Colors.green;
      iconData = Icons.cloud_done_outlined;
      label = 'API';
    } else if (mode == AiMode.local) {
      if (modelState.isLoading) {
        color = Colors.orange;
        iconData = Icons.hourglass_top_outlined;
        label = 'Loading…';
      } else if (modelState.isLoaded) {
        color = Colors.blue;
        iconData = Icons.memory_outlined;
        label = 'Local AI';
      } else {
        color = Colors.red;
        iconData = Icons.error_outline;
        label = 'Failed';
      }
    } else {
      color = Colors.grey;
      iconData = Icons.smart_toy_outlined;
      label = 'AI off';
    }

    AiMode nextMode() {
      if (mode == AiMode.off) return AiMode.local;
      if (mode == AiMode.local) return AiMode.api;
      return AiMode.off;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => ref.read(aiModeProvider.notifier).set(nextMode()),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconData, size: 13, color: color),
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
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
        Icon(Icons.psychology,
            size: 64, color: scheme.primary.withOpacity(0.3)),
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
                      Expanded(
                          child: Text(s, style: const TextStyle(fontSize: 13))),
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
                      fontSize: 10, color: scheme.onSurface.withOpacity(0.4)),
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
          Text(label, style: TextStyle(fontSize: 10, color: scheme.primary)),
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
