import 'package:flutter/material.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/atlas_logo.dart';

class AtlasSplashScreen extends StatefulWidget {
  final Future<void> Function() onReady;

  const AtlasSplashScreen({super.key, required this.onReady});

  @override
  State<AtlasSplashScreen> createState() => _AtlasSplashScreenState();
}

class _AtlasSplashScreenState extends State<AtlasSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _logoScale;

  int _stageIndex = 0;

  static const _stages = [
    'Initializing knowledge system...',
    'Loading database...',
    'Preparing intelligence...',
    'Ready.',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    _runStages();
  }

  Future<void> _runStages() async {
    for (var i = 0; i < _stages.length - 1; i++) {
      await Future.delayed(const Duration(milliseconds: 320));
      if (mounted) setState(() => _stageIndex = i + 1);
    }
    await widget.onReady();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AtlasColors.paper,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                const Spacer(flex: 3),

                ScaleTransition(
                  scale: _logoScale,
                  child: const AtlasLogo(size: 72, dark: true),
                ),
                const SizedBox(height: 20),

                Text(
                  'ATLAS',
                  style: AtlasTextStyles.headingSm.copyWith(
                    letterSpacing: 6,
                    fontWeight: FontWeight.w600,
                    color: AtlasColors.ink,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Personal Intelligence OS',
                  style: AtlasTextStyles.caption.copyWith(
                    letterSpacing: 1.2,
                    color: AtlasColors.midGray,
                  ),
                ),

                const Spacer(flex: 3),

                _StageIndicator(
                  stages: _stages,
                  currentIndex: _stageIndex,
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StageIndicator extends StatelessWidget {
  final List<String> stages;
  final int currentIndex;

  const _StageIndicator({required this.stages, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isReady = currentIndex == stages.length - 1;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(
              begin: 0,
              end: (currentIndex + 1) / stages.length,
            ),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            builder: (_, value, __) => LinearProgressIndicator(
              value: value,
              minHeight: 2,
              backgroundColor: AtlasColors.hairline,
              valueColor: AlwaysStoppedAnimation(
                isReady ? AtlasColors.ink : AtlasColors.midGray,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: Text(
            stages[currentIndex],
            key: ValueKey(currentIndex),
            style: AtlasTextStyles.caption.copyWith(
              color: isReady ? AtlasColors.ink : AtlasColors.midGray,
              fontWeight: isReady ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }
}
