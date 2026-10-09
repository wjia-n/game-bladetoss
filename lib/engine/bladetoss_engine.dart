import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Blade Toss modes.
enum GameMode { campaign, endless, timeAttack }

/// Difficulty tiers with clear speed/complexity scaling.
enum Difficulty { easy, normal, hard }

/// Phases owned entirely by the engine. The UI only renders.
/// [flying] = a knife is in the air; input locked, the hit resolves on the
/// engine's own timer. [resolving] = brief impact beat before the next state.
/// This makes stuck states impossible by construction.
enum Phase { idle, countdown, playing, flying, resolving, levelClear, over }

/// A shot fired back by a boss (fractions of screen size).
class EnemyShot {
  double x; // -0.5..0.5, center-relative
  double y; // 0..1 of height
  EnemyShot(this.x, this.y);
}

/// A floating "+20" / "-50" score pop (fractions of screen size).
class ScorePop {
  final int id;
  final double x;
  final double y;
  final String text;
  final bool good;
  final DateTime born = DateTime.now();
  ScorePop(this.id, this.x, this.y, this.text, this.good);
}

/// UI hook for sounds / narration / haptics. Set by the screen.
enum BladeEvent {
  throwKnife,
  stick,
  clink,
  dodge,
  playerHit,
  levelClear,
  bossWarn,
  timeUp,
  gameOver,
  countdownTick,
  invalid,
}

class BladetossEngine extends ChangeNotifier {
  final GameMode mode;
  final Difficulty difficulty;

  final _rand = Random();
  Timer? _tick; // main simulation loop
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  Phase phase = Phase.idle;
  String banner = '';
  String overReason = '';

  int score = 0;
  int level = 1;
  int streak = 0;
  int knivesLeft = 0; // -1 = infinite
  int knivesStuck = 0;
  int target = 0; // -1 = infinite
  int timeLeftMs = 0;
  bool boss = false;

  List<double> stuckAngles = []; // log-local radians of stuck blades
  double logAngle = 0;
  double logSpeed = 1.6;
  int logDir = 1;
  double bossX = 0; // center-relative fraction
  double bossShootT = 2.0;
  double reverseT = 0; // campaign direction-reversal timer
  final List<EnemyShot> shots = [];
  final List<ScorePop> pops = [];
  double throwerX = 0; // center-relative fraction, drag to dodge
  double knifeProgress = -1; // -1 = none in flight, else 0..1
  double hitFlash = 0;
  double shake = 0; // screen shake amount, decays

  void Function(BladeEvent event)? onEvent;

  DateTime _phaseStart = DateTime.now();
  String? _pendingOver;
  bool _pendingClear = false;
  int _popId = 0;
  int _lastTickSecond = -1;

  static const _flightSecs = 0.35;
  static const _resolveSecs = 0.18;
  static const _clearSecs = 1.1;
  static const _countdownSecs = 0.9;
  static const _logFracY = 0.32;
  static const _throwerFracY = 0.88;

  double get _speedMult => switch (difficulty) {
        Difficulty.easy => 0.8,
        Difficulty.normal => 1.0,
        Difficulty.hard => 1.28,
      };

  double get _minGap => switch (difficulty) {
        Difficulty.easy => 0.30,
        Difficulty.normal => 0.32,
        Difficulty.hard => 0.36,
      };

  bool get infiniteKnives => mode != GameMode.campaign;
  bool get canThrow =>
      !paused &&
      phase == Phase.playing &&
      !over &&
      (infiniteKnives || knivesLeft > 0);

  bool get over => phase == Phase.over;

  BladetossEngine({required this.mode, required this.difficulty});

  // --------------------------------------------------------------- lifecycle
  void start() {
    score = 0;
    level = 1;
    streak = 0;
    _setupLevel();
    banner = mode == GameMode.timeAttack ? '60 seconds — stick everything!'
        : mode == GameMode.endless ? 'How long can you last?'
        : 'Level 1 — stick every blade!';
    _enterPhase(Phase.countdown);
    onEvent?.call(BladeEvent.countdownTick);
    _startTick();
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    notifyListeners();
  }

  void _startTick() {
    _tick?.cancel();
    var last = DateTime.now();
    _tick = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_disposed || paused) {
        last = DateTime.now();
        return;
      }
      final now = DateTime.now();
      final dt = min(0.05, now.difference(last).inMicroseconds / 1e6);
      last = now;
      _step(dt);
    });
  }

  /// Pause: freeze the sim. Resume restarts the tick clock cleanly.
  void setPaused(bool v) {
    if (paused == v || _disposed || over) return;
    paused = v;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _enterPhase(Phase p) {
    phase = p;
    _phaseStart = DateTime.now();
  }

  double _phaseAge() =>
      DateTime.now().difference(_phaseStart).inMicroseconds / 1e6;

  /// Watchdog: any phase found without forward progress gets recovered.
  /// Stuck states are impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || paused || over) return;
    if (_tick == null || !_tick!.isActive) _startTick();
    switch (phase) {
      case Phase.flying:
        if (_phaseAge() > 2.0 && knifeProgress >= 0) _resolveHit();
        break;
      case Phase.resolving:
        if (_phaseAge() > 2.0) _afterResolve();
        break;
      case Phase.levelClear:
        if (_phaseAge() > 3.0) _nextLevel();
        break;
      case Phase.countdown:
        if (_phaseAge() > 3.0) {
          _enterPhase(Phase.playing);
          notifyListeners();
        }
        break;
      case Phase.idle:
      case Phase.playing:
      case Phase.over:
        break;
    }
  }

  // ------------------------------------------------------------------- setup
  void _setupLevel() {
    boss = mode == GameMode.campaign && level % 5 == 0;
    if (mode == GameMode.campaign) {
      target = boss ? 7 : min(4 + level, 10);
      knivesLeft = target + (boss ? 2 : 1);
      final base = 1.5 + level * 0.22;
      logSpeed = base * _speedMult * (boss ? 1.35 : 1.0);
      final pre = boss ? 3 : min(2 + level ~/ 3, 6);
      _seedStuck(pre);
      reverseT = level >= 8 ? 4 + _rand.nextDouble() * 3 : 0;
    } else if (mode == GameMode.endless) {
      target = -1;
      knivesLeft = -1;
      logSpeed = (1.6 + knivesStuckTotal * 0.045) * _speedMult;
      _seedStuck(min(2 + knivesStuckTotal ~/ 8, 8));
      reverseT = 5 + _rand.nextDouble() * 4;
    } else {
      // time attack
      target = -1;
      knivesLeft = -1;
      timeLeftMs = 60000;
      _lastTickSecond = -1;
      logSpeed = (1.7 + level * 0.04) * _speedMult;
      _seedStuck(min(2 + level ~/ 4, 5));
      reverseT = 0;
    }
    knivesStuck = 0;
    shots.clear();
    pops.clear();
    knifeProgress = -1;
    logAngle = 0;
    logDir = _rand.nextBool() ? 1 : -1;
    bossX = 0;
    bossShootT = 2.0;
    hitFlash = 0;
    shake = 0;
    _pendingOver = null;
    _pendingClear = false;
  }

  int knivesStuckTotal = 0;

  void _seedStuck(int n) {
    stuckAngles = [];
    for (int i = 0; i < n; i++) {
      stuckAngles.add(_rand.nextDouble() * pi * 2);
    }
  }

  void restart() {
    knivesStuckTotal = 0;
    paused = false;
    start();
  }

  // ------------------------------------------------------------------- input
  void throwKnife() {
    if (!canThrow) {
      if (!paused && phase == Phase.playing) {
        onEvent?.call(BladeEvent.invalid); // dry-fire feedback
      }
      return;
    }
    if (!infiniteKnives) knivesLeft--;
    knifeProgress = 0;
    _enterPhase(Phase.flying);
    onEvent?.call(BladeEvent.throwKnife);
    notifyListeners();
  }

  /// Drag the thrower sideways (boss dodge).
  void dragThrower(double dxFrac) {
    if (over || paused) return;
    throwerX = (throwerX + dxFrac).clamp(-0.38, 0.38);
    notifyListeners();
  }

  // -------------------------------------------------------------------- step
  void _step(double dt) {
    if (over) return;
    // Decay juice.
    if (hitFlash > 0) hitFlash = max(0, hitFlash - dt * 2.2);
    if (shake > 0) shake = max(0, shake - dt * 3.0);
    pops.removeWhere(
        (p) => DateTime.now().difference(p.born).inMilliseconds > 900);

    switch (phase) {
      case Phase.idle:
        return;
      case Phase.countdown:
        if (_phaseAge() >= _countdownSecs) {
          _enterPhase(Phase.playing);
          notifyListeners();
        }
        return;
      case Phase.over:
        return;
      case Phase.levelClear:
        _spinLog(dt);
        if (_phaseAge() >= _clearSecs) _nextLevel();
        return;
      case Phase.resolving:
        if (_phaseAge() >= _resolveSecs) _afterResolve();
        return;
      case Phase.flying:
        _spinLog(dt);
        _updateShots(dt);
        knifeProgress += dt / _flightSecs;
        if (knifeProgress >= 1.0) _resolveHit();
        break;
      case Phase.playing:
        _spinLog(dt);
        _updateShots(dt);
        if (mode == GameMode.timeAttack) {
          timeLeftMs -= (dt * 1000).round();
          final sec = (timeLeftMs / 1000).ceil();
          if (sec <= 5 && sec != _lastTickSecond && sec > 0) {
            _lastTickSecond = sec;
            onEvent?.call(BladeEvent.countdownTick);
          }
          if (timeLeftMs <= 0) {
            timeLeftMs = 0;
            onEvent?.call(BladeEvent.timeUp);
            _finish('Time!');
            return;
          }
        }
        if (reverseT > 0) {
          reverseT -= dt;
          if (reverseT <= 0) {
            logDir *= -1;
            reverseT = 5 + _rand.nextDouble() * 4;
          }
        }
        break;
    }
    notifyListeners();
  }

  void _spinLog(double dt) {
    logAngle += logDir * logSpeed * dt;
    if (boss) {
      final t = DateTime.now().microsecondsSinceEpoch / 1e6;
      bossX = sin(t * 1.3) * 0.075;
      bossShootT -= dt;
      if (bossShootT <= 0 && (phase == Phase.playing || phase == Phase.flying)) {
        final interval = max(0.8, 2.2 - level * 0.1) *
            switch (difficulty) {
              Difficulty.easy => 1.6,
              Difficulty.normal => 1.0,
              Difficulty.hard => 0.75,
            };
        bossShootT = interval;
        // Aimed at the thrower's current spot.
        shots.add(EnemyShot(throwerX + bossX * 0.4, _logFracY + 0.06));
      }
    }
  }

  void _updateShots(double dt) {
    if (!boss || shots.isEmpty) return;
    for (int i = shots.length - 1; i >= 0; i--) {
      final s = shots[i];
      s.y += 0.95 * dt;
      if (s.y >= _throwerFracY - 0.035) {
        shots.removeAt(i);
        if ((s.x - throwerX).abs() < 0.055) {
          // Hit! Costs a knife in campaign.
          hitFlash = 0.5;
          onEvent?.call(BladeEvent.playerHit);
          if (!infiniteKnives) {
            knivesLeft = max(0, knivesLeft - 1);
            if (knivesLeft == 0 &&
                knifeProgress < 0 &&
                knivesStuck < target) {
              _finish('Sniped!');
              return;
            }
          } else {
            score = max(0, score - 10);
            _pop(throwerX, _throwerFracY - 0.08, '-10', false);
          }
        } else {
          // Dodged!
          score += 5;
          _pop(throwerX, _throwerFracY - 0.08, '+5 dodge', true);
          onEvent?.call(BladeEvent.dodge);
        }
      }
    }
  }

  void _pop(double x, double y, String text, bool good) {
    pops.add(ScorePop(_popId++, x.clamp(-0.45, 0.45), y, text, good));
  }

  // ------------------------------------------------------------------ impact
  void _resolveHit() {
    if (phase != Phase.flying) return;
    knifeProgress = -1;
    // Log-local angle at the top of the log (world -pi/2).
    final local = ((-pi / 2 - logAngle) % (pi * 2) + pi * 2) % (pi * 2);
    for (final a in stuckAngles) {
      var diff = (a - local).abs() % (pi * 2);
      if (diff > pi) diff = pi * 2 - diff;
      if (diff < _minGap) {
        _onClink();
        return;
      }
    }
    _onStick(local);
  }

  void _onStick(double local) {
    stuckAngles.add(local);
    knivesStuck++;
    knivesStuckTotal++;
    streak++;
    final gain = (boss ? 30 : 20) + (streak % 5 == 0 ? 25 : 0);
    score += gain;
    _pop(0, _logFracY - 0.16, '+$gain', true);
    hitFlash = 0.12;
    onEvent?.call(BladeEvent.stick);
    // Endless ramps speed with every stick.
    if (mode == GameMode.endless) {
      logSpeed = (1.6 + knivesStuckTotal * 0.045) * _speedMult;
    }
    if (mode == GameMode.campaign && knivesStuck >= target) {
      final bonus = level * 25;
      score += bonus;
      banner = 'Level $level clear!  +$bonus bonus';
      _pendingClear = true;
      onEvent?.call(BladeEvent.levelClear);
    } else if (mode == GameMode.campaign &&
        !infiniteKnives &&
        knivesLeft == 0 &&
        knivesStuck < target) {
      _pendingOver = 'Out of blades!';
    }
    _enterPhase(Phase.resolving);
    notifyListeners();
  }

  void _onClink() {
    hitFlash = 0.6;
    shake = 1.0;
    streak = 0;
    onEvent?.call(BladeEvent.clink);
    if (mode == GameMode.timeAttack) {
      // Score attack: clink costs points, the run continues.
      score = max(0, score - 50);
      _pop(0, _logFracY - 0.16, '-50 clink', false);
      banner = 'Clink! -50 — keep throwing!';
      _enterPhase(Phase.resolving);
    } else {
      _pendingOver = 'Clink!';
      _enterPhase(Phase.resolving);
    }
    notifyListeners();
  }

  /// Guarded + idempotent: safe for the watchdog to call.
  void _afterResolve() {
    if (phase != Phase.resolving) return;
    if (_pendingOver != null) {
      _finish(_pendingOver!);
      return;
    }
    if (_pendingClear) {
      _pendingClear = false;
      _enterPhase(Phase.levelClear);
      notifyListeners();
      return;
    }
    _enterPhase(Phase.playing);
    notifyListeners();
  }

  void _nextLevel() {
    if (phase != Phase.levelClear) return;
    level++;
    _setupLevel();
    if (boss) {
      banner = 'BOSS LEVEL $level — it shoots back! Drag to dodge!';
      onEvent?.call(BladeEvent.bossWarn);
    } else {
      banner = 'Level $level — stick every blade!';
    }
    _enterPhase(Phase.countdown);
    notifyListeners();
  }

  void _finish(String reason) {
    if (over) return;
    overReason = reason;
    _enterPhase(Phase.over);
    onEvent?.call(BladeEvent.gameOver);
    notifyListeners();
  }
}
