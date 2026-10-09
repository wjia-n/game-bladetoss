import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/forge_art.dart';
import '../theme/forge_themes.dart';
import 'menu_screen.dart';

/// Single launch splash with two moments:
/// 1. Company moment — the official WAJIHA logo (never redrawn).
/// 2. Game splash — logo + name + animated loading line + "Credits: WAJIHA".
class SplashScreen extends StatefulWidget {
  final ForgeAudio audio;
  final ForgeSettings settings;
  final StoreService store;
  const SplashScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _showGame = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio during the company moment, off the critical path.
    unawaited(widget.audio.prewarm());
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _showGame = true);
    unawaited(widget.audio.startMenuMusic());
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ForgeThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: const Color(0xFF0E0A06),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: _showGame
            ? _GameSplash(key: const ValueKey('game'), theme: theme, loader: _loader)
            : _CompanySplash(key: const ValueKey('company')),
      ),
    );
  }
}

/// Moment 1: the official WAJIHA company logo, copied unchanged.
class _CompanySplash extends StatelessWidget {
  const _CompanySplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/wajiha_logo.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 18),
          const Text(
            'WAJIHA',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 10,
              color: Color(0xFFE8CE7A),
            ),
          ),
        ],
      ),
    );
  }
}

/// Moment 2: game splash — logo + name + animated loading line + credits.
class _GameSplash extends StatelessWidget {
  final ForgeThemeDef theme;
  final AnimationController loader;
  const _GameSplash({super.key, required this.theme, required this.loader});

  @override
  Widget build(BuildContext context) {
    return WoodBackdrop(
      theme: theme,
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: theme.accent, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      offset: Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    Image.asset('assets/bladetoss_logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('Blade Toss', style: Forge.display(52, theme: theme)),
              const SizedBox(height: 6),
              Text(
                'STICK EVERY BLADE. NEVER CLINK.',
                style: Forge.label(13, theme: theme),
              ),
              const SizedBox(height: 30),
              // Animated loading line.
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                              color: theme.accent.withValues(alpha: 0.5)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: LinearGradient(
                                colors: [
                                  theme.accentLight,
                                  theme.accent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        loader.value < 1 ? 'Sharpening blades…' : 'Ready!',
                        style: Forge.body(13,
                            theme: theme,
                            color: theme.ivory.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: Forge.label(14, theme: theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
