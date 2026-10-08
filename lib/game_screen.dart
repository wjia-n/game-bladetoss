import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Blade Toss — tap to throw knives at the spinning log. Don't clink! 🔪
class BladeTossScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const BladeTossScreen({super.key, required this.players, required this.callbacks});

  @override
  State<BladeTossScreen> createState() => _BladeTossScreenState();
}

class _Knife {
  double y; // travel position, 0 = bottom, 1 = hit line
  double vy;
  _Knife(this.y, this.vy);
}

class _BladeTossScreenState extends State<BladeTossScreen> {
  static const _bestKey = 'bladetoss_best';

  final _rand = Random();
  Ticker? _ticker;
  double _lastSec = 0;
  bool over = false;
  bool boss = false;

  int level = 1;
  int knivesLeft = 5;
  int knivesStuck = 0;
  List<double> stuckAngles = []; // log-local angles of stuck knives
  List<_Knife> flying = [];
  double logAngle = 0;
  double logSpeed = 1.6;
  int logDir = 1;
  double bossX = 0; // boss lateral wobble
  double bossShootT = 0;
  List<Offset> enemyShots = []; // absolute x, falling y
  double throwerX = 0; // offset from center; drag to dodge
  double hitFlash = 0;
  int best = 0;
  bool started = false;
  Size _size = Size.zero;

  int get score => widget.players[0].score;
  int get target => boss ? 7 : 4 + level;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => best = prefs.getInt(_bestKey) ?? 0);
  }

  void _begin() {
    setState(() {
      started = true;
      over = false;
      level = 1;
      throwerX = 0;
      widget.players[0].score = 0;
    });
    widget.callbacks.refreshHud();
    _setupLevel();
    _lastSec = 0;
    _ticker?.dispose();
    _ticker = Ticker(_tick)..start();
    Sfx.click();
  }

  void _setupLevel() {
    boss = level % 5 == 0;
    knivesLeft = boss ? 7 : 4 + level;
    knivesStuck = 0;
    stuckAngles = [];
    flying.clear();
    enemyShots.clear();
    logAngle = 0;
    final base = 1.5 + level * 0.22;
    logSpeed = base * (boss ? 1.4 : 1);
    logDir = _rand.nextBool() ? 1 : -1;
    // pre-stuck knives make it spicy
    final pre = boss ? 3 : min(2 + level ~/ 3, 6);
    for (int i = 0; i < pre; i++) {
      stuckAngles.add(_rand.nextDouble() * pi * 2);
    }
    bossX = 0;
    bossShootT = 2.0;
    setState(() {});
  }

  void _tick(Duration d) {
    final sec = d.inMicroseconds / 1e6;
    final dt = min(0.05, _lastSec == 0 ? 0.016 : sec - _lastSec);
    _lastSec = sec;
    if (over || !mounted || !started) return;
    setState(() {
      if (hitFlash > 0) hitFlash -= dt;
      logAngle += logDir * logSpeed * dt;
      if (boss) {
        bossX = sin(sec * 1.3) * 60;
        bossShootT -= dt;
        if (bossShootT <= 0) {
          bossShootT = max(0.8, 2.2 - level * 0.1);
          // aimed at the thrower's current spot
          enemyShots.add(Offset(_size.width / 2 + throwerX, _size.height * 0.32 + 100));
        }
      }
      final throwerAbsX = _size.width / 2 + throwerX;
      final throwerY = _size.height * 0.88;
      for (int i = enemyShots.length - 1; i >= 0; i--) {
        final s = enemyShots[i];
        final ny = s.dy + 460 * dt;
        enemyShots[i] = Offset(s.dx, ny);
        if (ny >= throwerY - 24) {
          enemyShots.removeAt(i);
          if ((s.dx - throwerAbsX).abs() < 36) {
            // hit! lose a knife from stock
            knivesLeft = max(0, knivesLeft - 1);
            hitFlash = 0.3;
            Sfx.lose();
            widget.callbacks.refreshHud();
            if (knivesLeft == 0 && flying.isEmpty && knivesStuck < target) {
              _gameOver('Sniped! 🏹');
              return;
            }
          } else {
            // dodged!
            widget.players[0].score += 5;
            widget.callbacks.refreshHud();
          }
        }
      }
      for (int i = flying.length - 1; i >= 0; i--) {
        final k = flying[i];
        k.y += k.vy * dt;
        if (k.y >= 1.0) {
          flying.removeAt(i);
          _landKnife();
        }
      }
    });
  }

  void _throw() {
    if (over || !started || knivesLeft <= 0 || flying.isNotEmpty) return;
    Sfx.move();
    setState(() {
      knivesLeft--;
      flying.add(_Knife(0, 2.6));
    });
  }

  void _landKnife() {
    // angle where the knife meets the log, in log-local space
    final worldAngle = -pi / 2; // top of log
    final local = (worldAngle - logAngle) % (pi * 2);
    const minGap = 0.32;
    for (final a in stuckAngles) {
      var diff = (a - local).abs() % (pi * 2);
      if (diff > pi) diff = pi * 2 - diff;
      if (diff < minGap) {
        // CLINK — game over
        hitFlash = 0.5;
        Sfx.lose();
        _gameOver('Clink! 🔪');
        return;
      }
    }
    stuckAngles.add(local);
    knivesStuck++;
    widget.players[0].score += boss ? 30 : 20;
    Sfx.tap();
    widget.callbacks.refreshHud();
    if (knivesStuck >= target) {
      // level clear!
      widget.players[0].score += level * 25;
      Sfx.win();
      widget.callbacks.refreshHud();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted || over) return;
        setState(() => level++);
        _setupLevel();
      });
    }
    setState(() {});
  }

  Future<void> _gameOver(String reason) async {
    if (over) return;
    over = true;
    _ticker?.stop();
    final s = score;
    final isBest = s > best;
    if (isBest) {
      best = s;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, best);
    }
    if (!mounted) return;
    widget.callbacks.finish(
      headline: '$reason Level $level — score $s! 🔪',
      subline: isBest ? 'NEW BEST! Sharpest thrower alive 🏆' : 'Best: $best — throw again?',
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    _size = MediaQuery.of(context).size;
    if (!started) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔪', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('Stick every knife. Never clink.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.text),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Bosses every 5 levels dodge and shoot back. Tap anywhere to throw — but only one knife flies at a time!',
                  style: TextStyle(color: theme.muted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              WajihaButton(label: 'Start throwing', emoji: '🎯', onTap: _begin, primary: true),
              const SizedBox(height: 12),
              Text('Best: $best', style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _throw,
      onHorizontalDragUpdate: (d) {
        setState(() {
          throwerX = (throwerX + d.delta.dx).clamp(-_size.width / 2 + 50, _size.width / 2 - 50);
        });
      },
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _BladePainter(
              logAngle: logAngle,
              stuckAngles: stuckAngles,
              flying: flying,
              boss: boss,
              bossX: bossX,
              enemyShots: enemyShots,
              hitFlash: hitFlash,
              throwerX: throwerX,
              theme: theme,
            ),
          ),
          Positioned(
            top: 8, left: 12, right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🔪 $score', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: theme.text)),
                Text(boss ? '👹 BOSS $level' : 'Level $level',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.accent)),
                Text('🗡 ×$knivesLeft', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: theme.text)),
              ],
            ),
          ),
          if (boss)
            Positioned(
              bottom: 12, left: 0, right: 0,
              child: Center(
                child: Text('dodge the red shots — +5 per dodge!',
                    style: TextStyle(color: theme.muted, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _BladePainter extends CustomPainter {
  final double logAngle;
  final List<double> stuckAngles;
  final List<_Knife> flying;
  final bool boss;
  final double bossX;
  final List<Offset> enemyShots;
  final double hitFlash;
  final double throwerX;
  final GameTheme theme;

  _BladePainter({
    required this.logAngle,
    required this.stuckAngles,
    required this.flying,
    required this.boss,
    required this.bossX,
    required this.enemyShots,
    required this.hitFlash,
    required this.throwerX,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2 + (boss ? bossX : 0);
    final cy = size.height * 0.32;
    const logR = 86.0;

    if (hitFlash > 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.red.withValues(alpha: hitFlash));
    }

    // enemy shots (absolute positions, falling toward the thrower)
    for (final s in enemyShots) {
      canvas.drawCircle(s, 9, Paint()..color = Colors.red);
      canvas.drawCircle(s, 4, Paint()..color = Colors.white);
    }

    // the log
    canvas.save();
    canvas.translate(cx, cy);
    final logPaint = Paint()..color = boss ? const Color(0xFF6B3FA0) : const Color(0xFF8B5E34);
    canvas.drawCircle(Offset.zero, logR, logPaint);
    canvas.drawCircle(Offset.zero, logR, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 5);
    canvas.rotate(logAngle);
    // wood rings
    for (final r in [30.0, 55.0, 76.0]) {
      canvas.drawCircle(Offset.zero, r, Paint()..color = Colors.black12..style = PaintingStyle.stroke..strokeWidth = 3);
    }
    if (boss) {
      // angry face
      canvas.drawCircle(const Offset(-22, -12), 10, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(22, -12), 10, Paint()..color = Colors.white);
      canvas.drawCircle(const Offset(-22, -10), 4, Paint()..color = Colors.red);
      canvas.drawCircle(const Offset(22, -10), 4, Paint()..color = Colors.red);
      canvas.drawArc(Rect.fromCircle(center: const Offset(0, 22), radius: 22), pi + 0.4, pi - 0.8, false,
          Paint()..color = Colors.black..strokeWidth = 5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    } else {
      canvas.drawCircle(Offset.zero, 12, Paint()..color = const Color(0xFFD9A05B));
    }
    // stuck knives (rotate with log)
    for (final a in stuckAngles) {
      canvas.save();
      canvas.rotate(a);
      _drawKnife(canvas, -logR - 34);
      canvas.restore();
    }
    canvas.restore();

    // flying knives
    for (final k in flying) {
      final y = size.height * 0.92 - k.y * (size.height * 0.92 - (cy - logR - 40));
      canvas.save();
      canvas.translate(cx, y);
      _drawKnife(canvas, 0);
      canvas.restore();
    }

    // the thrower (you) — drag sideways to dodge
    final tx = size.width / 2 + throwerX;
    final ty = size.height * 0.88;
    canvas.drawCircle(Offset(tx, ty), 22, Paint()..color = theme.primary);
    canvas.drawCircle(Offset(tx - 7, ty - 4), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(tx + 7, ty - 4), 4, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(tx - 7, ty - 4), 1.8, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(tx + 7, ty - 4), 1.8, Paint()..color = Colors.black);
    canvas.drawArc(Rect.fromCircle(center: Offset(tx, ty + 4), radius: 9), 0.4, pi - 0.8, false,
        Paint()..color = Colors.white..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // knife in hand
    canvas.save();
    canvas.translate(tx + 20, ty - 10);
    canvas.rotate(-0.5);
    _drawKnifeMini(canvas);
    canvas.restore();
  }

  void _drawKnifeMini(Canvas canvas) {
    final blade = Path()
      ..moveTo(-5, 0)
      ..lineTo(5, 0)
      ..lineTo(5, -22)
      ..lineTo(0, -30)
      ..lineTo(-5, -22)
      ..close();
    canvas.drawPath(blade, Paint()..color = const Color(0xFFDDE3EA));
    canvas.drawRect(const Rect.fromLTWH(-6, 0, 12, 16), Paint()..color = const Color(0xFF4A2F1B));
  }

  void _drawKnife(Canvas canvas, double yOff) {
    // blade pointing up (toward log)
    canvas.save();
    canvas.translate(0, yOff);
    final blade = Path()
      ..moveTo(-7, 0)
      ..lineTo(7, 0)
      ..lineTo(7, -34)
      ..lineTo(0, -46)
      ..lineTo(-7, -34)
      ..close();
    canvas.drawPath(blade, Paint()..color = const Color(0xFFDDE3EA));
    canvas.drawPath(blade, Paint()..color = Colors.black26..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawRect(const Rect.fromLTWH(-9, 0, 18, 26), Paint()..color = const Color(0xFF4A2F1B));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BladePainter old) => true;
}
