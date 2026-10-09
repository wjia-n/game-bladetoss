import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/bladetoss_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/forge_art.dart';
import '../theme/forge_themes.dart';
import '../store_url.dart';

/// Blade Toss game screen — renders the engine's state, owns nothing.
class GameScreen extends StatefulWidget {
  final ForgeAudio audio;
  final ForgeSettings settings;
  final StoreService store;
  final GameMode mode;
  final Difficulty difficulty;
  const GameScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.mode,
    required this.difficulty,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final BladetossEngine engine;
  bool _recorded = false;
  bool _showPause = false;

  ForgeThemeDef get _t => ForgeThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    engine = BladetossEngine(mode: widget.mode, difficulty: widget.difficulty);
    engine.onEvent = _onEvent;
    engine.start();
  }

  void _onEvent(BladeEvent e) {
    final a = widget.audio;
    switch (e) {
      case BladeEvent.throwKnife:
        a.throwKnife();
        break;
      case BladeEvent.stick:
        a.knifeStick();
        break;
      case BladeEvent.clink:
        a.clink();
        break;
      case BladeEvent.dodge:
        a.dodge();
        break;
      case BladeEvent.playerHit:
        a.playerHit();
        break;
      case BladeEvent.levelClear:
        a.levelClear();
        break;
      case BladeEvent.bossWarn:
        a.bossWarn();
        break;
      case BladeEvent.countdownTick:
        a.countdownTick();
        break;
      case BladeEvent.timeUp:
      case BladeEvent.gameOver:
        a.gameOver();
        break;
      case BladeEvent.invalid:
        a.invalid();
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      engine.setPaused(true);
      widget.audio.onAppPaused();
      if (mounted) setState(() => _showPause = true);
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    engine.dispose();
    super.dispose();
  }

  void _togglePause() {
    widget.audio.click();
    engine.setPaused(!engine.paused);
    setState(() => _showPause = engine.paused);
  }

  void _quit() {
    widget.audio.click();
    Navigator.of(context).pop();
  }

  Future<void> _recordOnce() async {
    if (_recorded || !engine.over) return;
    _recorded = true;
    final newBest = await widget.settings.recordGame(
      modePlayed: widget.mode.index,
      score: engine.score,
      level: engine.level,
    );
    if (mounted && (newBest || engine.level >= 5)) {
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: engine,
            builder: (context, _) {
              if (engine.over) unawaited(_recordOnce());
              return Stack(
                children: [
                  // Tap anywhere to throw; drag sideways to dodge.
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: engine.throwKnife,
                    onHorizontalDragUpdate: (d) {
                      final w = MediaQuery.of(context).size.width;
                      engine.dragThrower(d.delta.dx / w);
                    },
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ForgeScenePainter(
                        engine: engine,
                        theme: t,
                        bladeStyle: widget.settings.bladeStyle,
                        targetStyle: widget.settings.targetStyle,
                        playerName: widget.settings.playerName,
                      ),
                    ),
                  ),
                  _Hud(engine: engine, theme: t),
                  Positioned(
                    top: 6,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                          engine.paused ? Icons.play_arrow : Icons.pause,
                          color: t.accentLight),
                      onPressed: _togglePause,
                    ),
                  ),
                  // Banner overlays.
                  if (engine.phase == Phase.countdown ||
                      engine.phase == Phase.levelClear)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 36),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black.withValues(alpha: 0.55),
                          border: Border.all(color: t.accent, width: 2),
                        ),
                        child: Text(
                          engine.phase == Phase.countdown
                              ? 'Ready…'
                              : engine.banner,
                          style: Forge.display(20, theme: t),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_showPause && !engine.over)
                    _PauseOverlay(
                      theme: t,
                      onResume: _togglePause,
                      onRestart: () {
                        widget.audio.click();
                        _recorded = false;
                        setState(() => _showPause = false);
                        engine.restart();
                      },
                      onQuit: _quit,
                    ),
                  if (engine.over)
                    _GameOverOverlay(
                      theme: t,
                      engine: engine,
                      settings: widget.settings,
                      audio: widget.audio,
                      onReplay: () {
                        widget.audio.click();
                        _recorded = false;
                        engine.restart();
                      },
                      onQuit: _quit,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _Hud extends StatelessWidget {
  final BladetossEngine engine;
  final ForgeThemeDef theme;
  const _Hud({required this.engine, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    String middle;
    if (engine.mode == GameMode.timeAttack) {
      final s = (engine.timeLeftMs / 1000).ceil();
      middle = '⏱ $s';
    } else if (engine.boss) {
      middle = '👹 BOSS ${engine.level}';
    } else if (engine.mode == GameMode.endless) {
      middle = '♾️ Endless';
    } else {
      middle = 'Level ${engine.level}';
    }
    final knives = engine.infiniteKnives
        ? '🗡 ∞'
        : '🗡 ×${engine.knivesLeft}';
    final target = engine.target < 0
        ? ''
        : '  ${engine.knivesStuck}/${engine.target}';
    return Positioned(
      top: 8,
      left: 12,
      right: 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('⭐ ${engine.score}',
              style: Forge.label(22, theme: t)),
          Text(middle, style: Forge.label(18, theme: t)),
          Text('$knives$target', style: Forge.label(18, theme: t)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _PauseOverlay extends StatelessWidget {
  final ForgeThemeDef theme;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;
  const _PauseOverlay({
    required this.theme,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Paused', style: Forge.display(40, theme: t)),
            const SizedBox(height: 20),
            ForgeButton(
                label: 'Resume', emoji: '▶️', theme: t, primary: true,
                onTap: onResume),
            const SizedBox(height: 12),
            ForgeButton(
                label: 'Restart', emoji: '🔄', theme: t, onTap: onRestart),
            const SizedBox(height: 12),
            ForgeButton(
                label: 'Quit to menu', emoji: '🏠', theme: t, onTap: onQuit),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _GameOverOverlay extends StatelessWidget {
  final ForgeThemeDef theme;
  final BladetossEngine engine;
  final ForgeSettings settings;
  final ForgeAudio audio;
  final VoidCallback onReplay;
  final VoidCallback onQuit;
  const _GameOverOverlay({
    required this.theme,
    required this.engine,
    required this.settings,
    required this.audio,
    required this.onReplay,
    required this.onQuit,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final best = switch (engine.mode) {
      GameMode.campaign => settings.bestCampaignScore,
      GameMode.endless => settings.bestEndlessScore,
      GameMode.timeAttack => settings.bestTimeScore,
    };
    final isBest = engine.score >= best && engine.score > 0;
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${engine.overReason} 🔪',
                  style: Forge.display(38, theme: t),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                engine.mode == GameMode.campaign
                    ? '${settings.playerName} reached level ${engine.level}'
                    : '${settings.playerName}\'s run',
                style: Forge.body(15, theme: t),
              ),
              const SizedBox(height: 16),
              Text('${engine.score}',
                  style: Forge.display(56, theme: t)),
              Text(isBest ? 'NEW BEST! 🏆' : 'Best: $best',
                  style: Forge.label(16, theme: t)),
              const SizedBox(height: 20),
              ForgeButton(
                  label: 'Throw again',
                  emoji: '🔪',
                  theme: t,
                  primary: true,
                  onTap: onReplay),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ForgeIconChip(
                    icon: Icons.share,
                    caption: 'Share',
                    theme: t,
                    onTap: () async {
                      audio.click();
                      await SharePlus.instance.share(
                        ShareParams(
                            text:
                                'I scored ${engine.score} in Blade Toss! Can you stick them all? $storeUrl'),
                      );
                    },
                  ),
                  const SizedBox(width: 24),
                  ForgeIconChip(
                    icon: Icons.home,
                    caption: 'Menu',
                    theme: t,
                    onTap: onQuit,
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

// ---------------------------------------------------------------------------
/// The full workshop scene: target log, stuck blades, flying blade, thrower,
/// boss shots, score pops, hit flash, shake.
class _ForgeScenePainter extends CustomPainter {
  final BladetossEngine engine;
  final ForgeThemeDef theme;
  final int bladeStyle;
  final int targetStyle;
  final String playerName;

  _ForgeScenePainter({
    required this.engine,
    required this.theme,
    required this.bladeStyle,
    required this.targetStyle,
    required this.playerName,
  }) : super(repaint: engine);

  // Target-style palettes (face light/dark, ring, bark).
  List<Color> _targetColors() {
    switch (targetStyle) {
      case 1: // birch
        return const [Color(0xFFF0E2C4), Color(0xFFD9C69C), Color(0xFFBFA878), Color(0xFF6E6250)];
      case 2: // walnut
        return const [Color(0xFF8A5E38), Color(0xFF654222), Color(0xFF4A2F16), Color(0xFF33200F)];
      case 3: // cherry
        return const [Color(0xFFC98A5E), Color(0xFFA3653F), Color(0xFF7E4B28), Color(0xFF4E2E18)];
      case 4: // maple
        return const [Color(0xFFF5E8C8), Color(0xFFE0CB9E), Color(0xFFC2A878), Color(0xFF7A6A4E)];
      case 5: // charred
        return const [Color(0xFF3A332C), Color(0xFF211D18), Color(0xFF141210), Color(0xFF0E0C0A)];
      case 7: // burl
        return const [Color(0xFF9A6B3C), Color(0xFF6E4A24), Color(0xFF4E3218), Color(0xFF33200F)];
      default: // oak + painted use theme
        return [theme.boardLight, theme.boardDark, theme.ring, theme.bark];
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final t = theme;
    final cx = size.width / 2 + engine.bossX * size.width;
    final cy = size.height * 0.32;
    final logR = min(size.width, size.height) * 0.21;

    // Screen shake.
    if (engine.shake > 0) {
      final r = Random(engine.shake.hashCode ^ DateTime.now().millisecond);
      canvas.translate(
          (r.nextDouble() - 0.5) * 18 * engine.shake,
          (r.nextDouble() - 0.5) * 18 * engine.shake);
    }

    if (engine.hitFlash > 0) {
      canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..color =
                Colors.red.withValues(alpha: engine.hitFlash.clamp(0.0, 0.6)));
    }

    // Boss warning ring.
    if (engine.boss) {
      final pulse = 0.5 + 0.5 * sin(DateTime.now().millisecond / 180);
      canvas.drawCircle(
          Offset(cx, cy),
          logR + 14 + pulse * 6,
          Paint()
            ..color = t.shot.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4);
    }

    // Enemy shots.
    for (final s in engine.shots) {
      final p = Offset(size.width / 2 + s.x * size.width, s.y * size.height);
      canvas.drawCircle(p, 11, Paint()..color = t.shot);
      canvas.drawCircle(p, 11,
          Paint()..color = Colors.white.withValues(alpha: 0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawCircle(p, 4, Paint()..color = Colors.white);
    }

    // The target log.
    canvas.save();
    canvas.translate(cx, cy);
    _paintLog(canvas, logR);
    canvas.rotate(engine.logAngle);
    _paintLogFace(canvas, logR);
    // Stuck blades rotate with the log.
    for (final a in engine.stuckAngles) {
      canvas.save();
      canvas.rotate(a);
      _paintBlade(canvas, -logR - 6, 1.0);
      canvas.restore();
    }
    canvas.restore();

    // Flying blade.
    if (engine.knifeProgress >= 0) {
      final p = Curves.easeIn.transform(engine.knifeProgress.clamp(0.0, 1.0));
      final startY = size.height * 0.92;
      final endY = cy - logR - 44;
      final y = startY + (endY - startY) * p;
      canvas.save();
      canvas.translate(size.width / 2 + engine.throwerX * size.width, y);
      _paintBlade(canvas, 0, 1.0);
      canvas.restore();
    }

    // The thrower.
    _paintThrower(canvas, size);

    // Score pops.
    for (final pop in engine.pops) {
      final age =
          DateTime.now().difference(pop.born).inMilliseconds / 900.0;
      final p = Offset(size.width / 2 + pop.x * size.width,
          pop.y * size.height - age * 46);
      canvas.drawParagraph(
        _textParagraph(pop.text, 20, pop.good ? t.accentLight : t.shot,
            1.0 - age),
        Offset(p.dx - 40, p.dy - 12),
      );
    }

    // Boss hint.
    if (engine.boss && engine.phase == Phase.playing) {
      canvas.drawParagraph(
        _textParagraph('drag sideways to dodge the red shots!', 14,
            t.ivory.withValues(alpha: 0.8), 1.0),
        Offset(20, size.height - 60),
      );
    }
  }

  ui.Paragraph _textParagraph(
      String text, double size, Color color, double alpha) {
    final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
      fontSize: size,
      fontWeight: FontWeight.w800,
    ))
      ..pushStyle(ui.TextStyle(color: color.withValues(alpha: alpha)))
      ..addText(text);
    final para = builder.build();
    para.layout(const ui.ParagraphConstraints(width: 400));
    return para;
  }

  void _paintLog(Canvas canvas, double r) {
    final c = _targetColors();
    // Bark rim.
    canvas.drawCircle(Offset.zero, r + 8,
        Paint()..color = c[3]);
    canvas.drawCircle(
        Offset.zero, r + 8,
        Paint()
          ..color = Colors.black45
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    // Face.
    final face = Paint()
      ..shader = RadialGradient(
        colors: [c[0], c[1]],
        stops: const [0.25, 1.0],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
    canvas.drawCircle(Offset.zero, r, face);
  }

  void _paintLogFace(Canvas canvas, double r) {
    final c = _targetColors();
    if (targetStyle == 6) {
      // Painted rings: classic red/white bullseye.
      const rings = [Colors.white, Color(0xFFC0392B)];
      for (int i = 4; i >= 0; i--) {
        canvas.drawCircle(Offset.zero, r * (i + 1) / 5,
            Paint()..color = rings[i % 2]);
      }
      canvas.drawCircle(Offset.zero, r * 0.12,
          Paint()..color = const Color(0xFFC0392B));
      return;
    }
    // Growth rings.
    for (final frac in [0.3, 0.52, 0.72, 0.9]) {
      canvas.drawCircle(
          Offset.zero,
          r * frac,
          Paint()
            ..color = c[2].withValues(alpha: 0.75)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    // Cracks for character.
    final crack = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(r * 0.2, -r * 0.1), Offset(r * 0.55, r * 0.25), crack);
    canvas.drawLine(Offset(-r * 0.3, r * 0.2), Offset(-r * 0.6, r * 0.5), crack);
    // Center mark.
    canvas.drawCircle(Offset.zero, 10, Paint()..color = c[2]);
  }

  void _paintThrower(Canvas canvas, Size size) {
    final t = theme;
    final tx = size.width / 2 + engine.throwerX * size.width;
    final ty = size.height * 0.88;
    // Throwing glove hand.
    canvas.drawCircle(Offset(tx, ty), 24,
        Paint()..color = t.grip);
    canvas.drawCircle(
        Offset(tx, ty), 24,
        Paint()
          ..color = Colors.black38
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(Offset(tx - 8, ty - 5), 4, Paint()..color = t.ivory);
    canvas.drawCircle(Offset(tx + 8, ty - 5), 4, Paint()..color = t.ivory);
    // Blade in hand.
    canvas.save();
    canvas.translate(tx + 22, ty - 12);
    canvas.rotate(-0.6);
    _paintBladeMini(canvas);
    canvas.restore();
    // Name tag.
    if (playerName.isNotEmpty) {
      canvas.drawParagraph(
        _textParagraph(playerName, 12, t.ivory.withValues(alpha: 0.7), 1.0),
        Offset(tx - 100, ty + 30),
      );
    }
  }

  void _paintBladeMini(Canvas canvas) {
    final t = theme;
    final blade = Path()
      ..moveTo(-5, 0)
      ..lineTo(5, 0)
      ..lineTo(5, -20)
      ..lineTo(0, -27)
      ..lineTo(-5, -20)
      ..close();
    canvas.drawPath(blade, Paint()..color = t.steel);
    canvas.drawRect(
        const Rect.fromLTWH(-6, 0, 12, 14), Paint()..color = t.grip);
  }

  /// Full blade pointing UP (tip at -size), handle below origin.
  /// Origin = the point that bites into the log.
  void _paintBlade(Canvas canvas, double yOff, double scale) {
    final t = theme;
    final steel = Paint()..color = t.steel;
    final steelDark = Paint()..color = t.steelDark;
    final grip = Paint()..color = t.grip;
    final gripDark = Paint()..color = t.gripDark;
    canvas.save();
    canvas.translate(0, yOff);
    canvas.scale(scale);
    switch (bladeStyle) {
      case 1: // kitchen
        final p = Path()
          ..moveTo(-8, 0)
          ..lineTo(10, 0)
          ..lineTo(10, -26)
          ..quadraticBezierTo(2, -40, -8, -44)
          ..close();
        canvas.drawPath(p, steel);
        canvas.drawRect(const Rect.fromLTWH(-9, 2, 20, 26), grip);
        for (final ry in [8.0, 16.0, 24.0]) {
          canvas.drawCircle(Offset(1, ry), 2.5, steelDark);
        }
        break;
      case 2: // bowie
        final p = Path()
          ..moveTo(-7, 0)
          ..lineTo(7, 0)
          ..lineTo(7, -30)
          ..lineTo(-1, -44)
          ..lineTo(-7, -34)
          ..close();
        canvas.drawPath(p, steel);
        canvas.drawRect(const Rect.fromLTWH(-8, 2, 16, 28), grip);
        canvas.drawLine(const Offset(-8, 10), const Offset(8, 6), gripDark
          ..strokeWidth = 3);
        canvas.drawLine(const Offset(-8, 20), const Offset(8, 16), gripDark
          ..strokeWidth = 3);
        break;
      case 3: // stiletto
        final p = Path()
          ..moveTo(-4, 0)
          ..lineTo(4, 0)
          ..lineTo(2, -40)
          ..lineTo(0, -48)
          ..lineTo(-2, -40)
          ..close();
        canvas.drawPath(p, steel);
        canvas.drawRect(const Rect.fromLTWH(-6, 2, 12, 22), gripDark);
        break;
      case 4: // cleaver
        canvas.drawRect(const Rect.fromLTWH(-16, -34, 32, 34), steel);
        canvas.drawRect(const Rect.fromLTWH(-16, -34, 32, 6), steelDark);
        canvas.drawRect(const Rect.fromLTWH(-7, 2, 14, 28), grip);
        for (final ry in [9.0, 17.0, 25.0]) {
          canvas.drawCircle(Offset(0, ry), 2.5, Paint()..color = t.accent);
        }
        break;
      case 5: // kunai
        final p = Path()
          ..moveTo(-7, 0)
          ..lineTo(7, 0)
          ..lineTo(4, -24)
          ..lineTo(0, -34)
          ..lineTo(-4, -24)
          ..close();
        canvas.drawPath(p, steelDark);
        canvas.drawRect(const Rect.fromLTWH(-5, 2, 10, 24), grip);
        canvas.drawCircle(const Offset(0, 32), 7,
            Paint()..color = t.steel
              ..style = PaintingStyle.stroke
              ..strokeWidth = 4);
        break;
      case 6: // hatchet
        final head = Path()
          ..moveTo(-20, -52)
          ..lineTo(20, -52)
          ..lineTo(14, -30)
          ..lineTo(-14, -30)
          ..close();
        canvas.drawPath(head, steel);
        canvas.drawRect(const Rect.fromLTWH(-5, -44, 10, 76), grip);
        break;
      case 7: // dagger
        final p = Path()
          ..moveTo(-6, 0)
          ..lineTo(6, 0)
          ..lineTo(3, -30)
          ..lineTo(0, -40)
          ..lineTo(-3, -30)
          ..close();
        canvas.drawPath(p, steel);
        canvas.drawLine(const Offset(0, 0), const Offset(0, -36),
            steelDark..strokeWidth = 2);
        canvas.drawRect(const Rect.fromLTWH(-14, 2, 28, 6),
            Paint()..color = t.accent);
        canvas.drawRect(const Rect.fromLTWH(-6, 8, 12, 22), grip);
        break;
      case 8: // machete
        final p = Path()
          ..moveTo(-6, 0)
          ..lineTo(6, 0)
          ..lineTo(8, -52)
          ..lineTo(-2, -58)
          ..close();
        canvas.drawPath(p, steel);
        canvas.drawRect(const Rect.fromLTWH(-7, 2, 14, 30), grip);
        for (double gy = 8; gy < 30; gy += 6) {
          canvas.drawLine(Offset(-7, gy), Offset(7, gy - 3), gripDark
            ..strokeWidth = 2);
        }
        break;
      case 9: // kris
        final p = Path()..moveTo(-6, 0)..lineTo(6, 0);
        for (int i = 0; i < 5; i++) {
          final y0 = -i * 9.0;
          p.lineTo(i.isEven ? 8 : -8, y0 - 9);
        }
        p.lineTo(0, -48);
        p.close();
        canvas.drawPath(p, steel);
        canvas.drawRect(const Rect.fromLTWH(-8, 2, 16, 24), grip);
        break;
      default: // 0 classic thrower
        final p = Path()
          ..moveTo(-7, 0)
          ..lineTo(7, 0)
          ..lineTo(7, -34)
          ..lineTo(0, -46)
          ..lineTo(-7, -34)
          ..close();
        canvas.drawPath(p, steel);
        canvas.drawPath(p,
            Paint()..color = Colors.black26
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
        canvas.drawRect(const Rect.fromLTWH(-9, 2, 18, 26), grip);
        for (double gy = 8; gy < 26; gy += 5) {
          canvas.drawLine(Offset(-9, gy), Offset(9, gy - 3), gripDark
            ..strokeWidth = 2.5);
        }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ForgeScenePainter old) => true;
}
