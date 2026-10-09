# Blade Toss — Rules

## 1. Objective
Stick every blade into the spinning wooden target without any blade
clinking against another. In Campaign, clear level after level; in Endless,
survive as long as you can; in 60s Time Attack, score as much as possible.

## 2. Setup
- One player (renameable thrower profile).
- Campaign: level N needs `target` sticks (level 1: 5, up to 10 max);
  the player gets `target + 1` blades (+2 on boss levels).
- 2–6 blades start pre-stuck in the target (3 on boss levels).
- The target spins at a base speed that grows with level and difficulty.
- Endless: infinite blades, speed grows with every stick.
- 60s Time Attack: infinite blades, 60-second clock.

## 3. Turn order
Single-player skill game — no turns. The player throws whenever ready,
but only ONE blade may be in flight at a time.

## 4. Legal moves
- TAP anywhere to throw a blade straight at the target.
- Blades land at the top of the target; their angle is measured in the
  target's own rotating frame.
- A blade sticks if its landing angle is at least `minGap` radians away
  from every already-stuck blade (Easy 0.30 / Normal 0.32 / Hard 0.36).
- On boss levels, DRAG sideways to dodge the red shots the boss fires.

## 5. Illegal moves
- Throwing while a blade is already in flight is ignored (dry-fire tick).
- Throwing with zero blades left is ignored.

## 6. Captures
Not applicable — blades are never removed from the target once stuck.

## 7. Special rules
- **Boss levels** (every 5th campaign level): the target wobbles sideways
  and fires red shots aimed at the thrower. A shot that hits the thrower
  costs one blade; a dodged shot scores +5.
- **Direction reversal** (campaign level 8+ and Endless): the target
  periodically reverses spin direction.
- **Streaks**: every 5th consecutive stick without a clink adds +25 bonus.
- **60s Time Attack**: a clink costs −50 points (never below 0) and the
  run continues; there is no death by clink.

## 8. Scoring
- Normal stick: +20. Boss-level stick: +30.
- Streak bonus: +25 on every 5th consecutive stick.
- Level-clear bonus (campaign): +25 × level.
- Dodged boss shot: +5.
- Boss shot hit (endless/time attack): −10.

## 9. Winning conditions
- Campaign: clearing a level advances to the next; there is no final
  level — the run ends on the first clink / empty blade rack.
- Endless / Time Attack: the run ends on clink (endless) or time-up
  (time attack); the score is compared against the stored best.

## 10. Draw conditions
Not applicable — single-player score attack.

## 11. AI strategy
No AI opponent. Difficulty scaling: Easy = 0.8× speed, Normal = 1.0×,
Hard = 1.28× speed with tighter gaps and faster boss shots.

## 12. Edge cases
- A blade that would land exactly on `minGap` sticks (gap ≥ minGap is legal).
- If the last blade is spent without reaching the target count, the run
  ends ("Out of blades!").
- Boss shots in flight when a level clears are discarded.
- App backgrounding pauses the simulation; music pauses and resumes.

## 13. Test cases
1. Throw with empty rack → ignored, dry-fire feedback.
2. Double-tap during flight → second tap ignored, one blade resolves.
3. Blade landing within minGap → clink, run over (campaign/endless).
4. Blade landing exactly at minGap → sticks.
5. Boss shot dodge → +5, "dodge" narration.
6. Boss shot hit with 1 blade left and target unmet → "Sniped!" game over.
7. Time attack clink → −50, run continues.
8. Level clear → bonus added, next level starts after the banner beat.
9. Watchdog: a phase with no forward progress for its timeout is
   recovered automatically (never stuck).
10. Hard difficulty selected while free → opens the Pro screen instead.
