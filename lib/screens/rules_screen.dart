import 'package:flutter/material.dart';
import '../theme/forge_art.dart';
import '../theme/forge_themes.dart';

/// Blade Toss rules screen — a readable summary of RULES.md.
class RulesScreen extends StatelessWidget {
  final ForgeThemeDef theme;
  const RulesScreen({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final rules = [
      (
        '🎯 Goal',
        'Stick every blade into the spinning log. Never let two blades clink!'
      ),
      (
        '🔪 Throw',
        'TAP anywhere to throw. Only one blade flies at a time — wait for it to land.'
      ),
      (
        '🪵 The log',
        'It spins faster every level and reverses direction from level 8. Pre-stuck blades are your obstacles.'
      ),
      (
        '👹 Bosses',
        'Every 5th level the log comes alive: it wobbles and shoots red shots at you. DRAG sideways to dodge — a hit costs a blade, a dodge scores +5.'
      ),
      (
        '🔥 Streaks',
        'Every 5th stick in a row earns a +25 bonus. Boss sticks pay +30 instead of +20.'
      ),
      (
        '♾️ Endless',
        'Infinite blades, speed rises with every stick. One clink ends it.'
      ),
      (
        '⏱️ 60s Time Attack',
        'Infinite blades, 60 seconds. Clinks cost −50 but never end the run — stick fast!'
      ),
      (
        '⭐ PRO',
        'Pro unlocks Hard difficulty, 12+ themes, 10 blade styles, 8 target styles and the custom workshop creator.'
      ),
    ];
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('How to play', style: Forge.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            children: [
              for (final r in rules)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withValues(alpha: 0.3),
                    border: Border.all(
                        color: t.accent.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.$1, style: Forge.label(15, theme: t)),
                      const SizedBox(height: 4),
                      Text(r.$2, style: Forge.body(14, theme: t)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
