import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/bladetoss_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../store_url.dart';
import '../theme/forge_art.dart';
import '../theme/forge_themes.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'rules_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';

/// Blade Toss main menu: profile, modes, difficulty, play, customization.
class MenuScreen extends StatefulWidget {
  final ForgeAudio audio;
  final ForgeSettings settings;
  final StoreService store;
  const MenuScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  ForgeThemeDef get _t => ForgeThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  Future<void> _requestReview() async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      }
    } catch (_) {}
  }

  void _play() {
    widget.audio.click();
    unawaited(widget.audio.startGameMusic());
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
          mode: GameMode.values[widget.settings.mode],
          difficulty: Difficulty.values[widget.settings.difficulty],
        ),
      ),
    ).then((_) => widget.audio.startMenuMusic());
  }

  Future<void> _editName() async {
    widget.audio.click();
    await showThrowerNameDialog(
      context: context,
      theme: _t,
      settings: widget.settings,
      audio: widget.audio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo + title.
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: t.accent, width: 3),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black54,
                            offset: Offset(0, 8),
                            blurRadius: 18),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/bladetoss_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Text('Blade Toss', style: Forge.display(44, theme: t)),
                  const SizedBox(height: 4),
                  Text('Stick every blade. Never clink.',
                      style: Forge.body(14,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.8))),
                  const SizedBox(height: 18),
                  // Renameable profile.
                  GestureDetector(
                    onTap: _editName,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.3),
                        border: Border.all(
                            color: t.accent.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🎯 ${s.playerName}',
                              style: Forge.label(16, theme: t)),
                          const SizedBox(width: 8),
                          Icon(Icons.edit,
                              size: 16,
                              color:
                                  t.accentLight.withValues(alpha: 0.8)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Mode cards.
                  Text('GAME MODE', style: Forge.label(13, theme: t)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _ModeCard(
                        t: t,
                        emoji: '🪵',
                        name: 'Campaign',
                        desc: 'Levels + bosses',
                        selected: s.mode == 0,
                        onTap: () {
                          widget.audio.click();
                          s.setMode(0);
                        },
                      ),
                      const SizedBox(width: 10),
                      _ModeCard(
                        t: t,
                        emoji: '♾️',
                        name: 'Endless',
                        desc: 'Speed keeps rising',
                        selected: s.mode == 1,
                        onTap: () {
                          widget.audio.click();
                          s.setMode(1);
                        },
                      ),
                      const SizedBox(width: 10),
                      _ModeCard(
                        t: t,
                        emoji: '⏱️',
                        name: 'Time 60s',
                        desc: 'Score attack',
                        selected: s.mode == 2,
                        onTap: () {
                          widget.audio.click();
                          s.setMode(2);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Difficulty.
                  Text('DIFFICULTY', style: Forge.label(13, theme: t)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _DiffChip(
                          t: t,
                          label: 'Easy',
                          selected: s.difficulty == 0,
                          locked: false,
                          onTap: () {
                            widget.audio.click();
                            s.setDifficulty(0);
                          }),
                      const SizedBox(width: 8),
                      _DiffChip(
                          t: t,
                          label: 'Normal',
                          selected: s.difficulty == 1,
                          locked: false,
                          onTap: () {
                            widget.audio.click();
                            s.setDifficulty(1);
                          }),
                      const SizedBox(width: 8),
                      _DiffChip(
                          t: t,
                          label: 'Hard 🔒',
                          selected: s.difficulty == 2,
                          locked: !s.isPro,
                          onTap: () {
                            widget.audio.click();
                            if (s.isPro) {
                              s.setDifficulty(2);
                            } else {
                              _openPro();
                            }
                          }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hard: faster log, tighter gaps, angrier bosses.',
                    style: Forge.body(12,
                        theme: t,
                        color: t.ivory.withValues(alpha: 0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 22),
                  ForgeButton(
                    label: 'THROW BLADES',
                    emoji: '🔪',
                    theme: t,
                    primary: true,
                    onTap: _play,
                  ),
                  const SizedBox(height: 18),
                  // Best scores.
                  _BestStrip(t: t, s: s),
                  const SizedBox(height: 18),
                  // Icon row.
                  Wrap(
                    spacing: 18,
                    runSpacing: 14,
                    alignment: WrapAlignment.center,
                    children: [
                      ForgeIconChip(
                        icon: Icons.palette,
                        caption: 'Styles',
                        theme: t,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ThemeScreen(
                                  audio: widget.audio,
                                  settings: s,
                                  store: widget.store),
                            ),
                          );
                        },
                      ),
                      ForgeIconChip(
                        icon: Icons.settings,
                        caption: 'Settings',
                        theme: t,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(
                                  audio: widget.audio, settings: s),
                            ),
                          );
                        },
                      ),
                      ForgeIconChip(
                        icon: Icons.star,
                        caption: s.isPro ? 'PRO ✓' : 'Get PRO',
                        theme: t,
                        onTap: _openPro,
                      ),
                      ForgeIconChip(
                        icon: Icons.book,
                        caption: 'Rules',
                        theme: t,
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) =>
                                    RulesScreen(theme: t)),
                          );
                        },
                      ),
                      ForgeIconChip(
                        icon: Icons.share,
                        caption: 'Share',
                        theme: t,
                        onTap: () async {
                          widget.audio.click();
                          await SharePlus.instance.share(
                            ShareParams(
                                text:
                                    'I\'m tossing blades in Blade Toss! Think you can stick them all? $storeUrl'),
                          );
                        },
                      ),
                      ForgeIconChip(
                        icon: Icons.rate_review,
                        caption: 'Review',
                        theme: t,
                        onTap: () {
                          widget.audio.click();
                          _requestReview();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 24, height: 24, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Forge.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPro() {
    widget.audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final ForgeThemeDef t;
  final String emoji;
  final String name;
  final String desc;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({
    required this.t,
    required this.emoji,
    required this.name,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: selected
                  ? [t.accentLight, t.accent, t.accentDark]
                  : [t.woodMid.withValues(alpha: 0.7),
                      t.woodDeep.withValues(alpha: 0.8)],
            ),
            border: Border.all(
                color: selected ? t.ivory : t.accent.withValues(alpha: 0.6),
                width: selected ? 2.5 : 1.5),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text(name,
                  style: Forge.label(13,
                      theme: t,
                      color: selected ? t.woodDeep : t.accentLight)),
              Text(desc,
                  style: Forge.body(10,
                      theme: t,
                      color: selected
                          ? t.woodDeep.withValues(alpha: 0.8)
                          : t.ivory.withValues(alpha: 0.65)),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final ForgeThemeDef t;
  final String label;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _DiffChip({
    required this.t,
    required this.label,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: selected
              ? t.accent.withValues(alpha: 0.35)
              : Colors.black.withValues(alpha: 0.3),
          border: Border.all(
              color: selected ? t.accentLight : t.accent.withValues(alpha: 0.5),
              width: selected ? 2 : 1.2),
        ),
        child: Text(label,
            style: Forge.label(13,
                theme: t,
                color: selected
                    ? t.accentLight
                    : locked
                        ? t.ivory.withValues(alpha: 0.5)
                        : t.ivory.withValues(alpha: 0.85))),
      ),
    );
  }
}

class _BestStrip extends StatelessWidget {
  final ForgeThemeDef t;
  final ForgeSettings s;
  const _BestStrip({required this.t, required this.s});

  @override
  Widget build(BuildContext context) {
    Widget cell(String emoji, String label, String value) => Expanded(
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              Text(value, style: Forge.display(18, theme: t)),
              Text(label,
                  style: Forge.body(10,
                      theme: t,
                      color: t.ivory.withValues(alpha: 0.6))),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.28),
        border:
            Border.all(color: t.accent.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        children: [
          cell('🏆', 'Best campaign', '${s.bestCampaignScore}'),
          cell('🪜', 'Best level', '${s.bestLevel}'),
          cell('♾️', 'Best endless', '${s.bestEndlessScore}'),
          cell('⏱️', 'Best 60s', '${s.bestTimeScore}'),
        ],
      ),
    );
  }
}
