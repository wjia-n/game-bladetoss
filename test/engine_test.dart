import 'package:flutter_test/flutter_test.dart';
import 'package:bladetoss/engine/bladetoss_engine.dart';

/// Engine contract tests: the state machine must always move forward —
/// no phase may strand the game with no legal action (see RULES.md §13).
///
/// NOTE: these are plain `test()`s (real async), not testWidgets, because
/// the engine measures phase ages with the wall clock while its simulation
/// ticks on Timers — fake async would freeze the clock.
Future<void> _waitThrowable(BladetossEngine engine) async {
  for (int w = 0; w < 60 && !engine.canThrow && !engine.over; w++) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  test('endless: 25 throws always settle, never stuck', () async {
    final engine = BladetossEngine(
        mode: GameMode.endless, difficulty: Difficulty.normal);
    addTearDown(engine.dispose);
    engine.start();
    await Future.delayed(const Duration(milliseconds: 1200));
    expect(engine.phase, Phase.playing);

    for (int i = 0; i < 25 && !engine.over; i++) {
      await _waitThrowable(engine);
      if (engine.over) break;
      expect(engine.canThrow, isTrue,
          reason: 'throw $i never became legal — stuck state');
      engine.throwKnife();
      expect(engine.phase, Phase.flying);
      // Flight (0.35s) + resolve beat (0.18s) must settle well under 2s.
      await Future.delayed(const Duration(milliseconds: 900));
      expect(engine.phase, anyOf([Phase.playing, Phase.over]),
          reason: 'throw $i never settled — stuck in ${engine.phase}');
    }
    // Either still playing or cleanly over; never mid-flight.
    expect(engine.phase, anyOf([Phase.playing, Phase.over]));
  });

  test('time attack: clock runs out and the run ends cleanly', () async {
    final engine = BladetossEngine(
        mode: GameMode.timeAttack, difficulty: Difficulty.easy);
    addTearDown(engine.dispose);
    var gameOverFired = false;
    engine.onEvent = (e) {
      if (e == BladeEvent.gameOver) gameOverFired = true;
    };
    engine.start();
    await Future.delayed(const Duration(milliseconds: 1200));
    expect(engine.phase, Phase.playing);
    // Throw a few, then fast-forward the clock (test seam: public field).
    for (int i = 0; i < 2; i++) {
      if (engine.canThrow) engine.throwKnife();
      await Future.delayed(const Duration(milliseconds: 900));
    }
    engine.timeLeftMs = 1200;
    await Future.delayed(const Duration(seconds: 2));
    expect(engine.phase, Phase.over);
    expect(engine.overReason, 'Time!');
    expect(gameOverFired, isTrue);
  });

  test('campaign: blind throws resolve, restart recovers', () async {
    final engine = BladetossEngine(
        mode: GameMode.campaign, difficulty: Difficulty.hard);
    addTearDown(engine.dispose);
    engine.start();
    await Future.delayed(const Duration(milliseconds: 1200));

    for (int i = 0; i < 8 && !engine.over; i++) {
      await _waitThrowable(engine);
      if (engine.over) break;
      engine.throwKnife();
      await Future.delayed(const Duration(milliseconds: 900));
      expect(
          engine.phase,
          anyOf(
              [Phase.playing, Phase.resolving, Phase.levelClear, Phase.over]),
          reason: 'throw $i stuck in ${engine.phase}');
    }
    // If the run ended, restart must bring back a fresh level.
    if (engine.over) {
      engine.restart();
      await Future.delayed(const Duration(milliseconds: 1200));
      expect(engine.phase, Phase.playing);
      expect(engine.level, 1);
      expect(engine.score, 0);
    }
  });

  test('pause freezes the sim and resume continues', () async {
    final engine = BladetossEngine(
        mode: GameMode.endless, difficulty: Difficulty.normal);
    addTearDown(engine.dispose);
    engine.start();
    await Future.delayed(const Duration(milliseconds: 1200));
    expect(engine.phase, Phase.playing);

    engine.setPaused(true);
    final angleFrozen = engine.logAngle;
    await Future.delayed(const Duration(milliseconds: 600));
    expect(engine.logAngle, angleFrozen);
    expect(engine.canThrow, isFalse);

    engine.setPaused(false);
    await Future.delayed(const Duration(milliseconds: 600));
    expect(engine.logAngle, isNot(angleFrozen));
    expect(engine.canThrow, isTrue);
  });

  test('dry-fire while flying is ignored, one blade resolves', () async {
    final engine = BladetossEngine(
        mode: GameMode.endless, difficulty: Difficulty.normal);
    addTearDown(engine.dispose);
    var invalidFired = false;
    engine.onEvent = (e) {
      if (e == BladeEvent.invalid) invalidFired = true;
    };
    engine.start();
    await Future.delayed(const Duration(milliseconds: 1200));

    engine.throwKnife();
    expect(engine.phase, Phase.flying);
    // Second tap mid-flight: ignored, still one blade in flight.
    engine.throwKnife();
    expect(engine.phase, Phase.flying);
    await Future.delayed(const Duration(milliseconds: 900));
    expect(engine.phase, anyOf([Phase.playing, Phase.over]));
    // The mid-flight tap must not have fired an invalid event
    // (invalid only fires when idle-playing with no blades).
    expect(invalidFired, isFalse);
  });

}
