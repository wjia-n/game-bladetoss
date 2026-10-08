import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const BladeTossApp());

class BladeTossApp extends StatelessWidget {
  const BladeTossApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.midnightNeon,
      title: 'Blade Toss',
      tagline: 'Stick every knife. Never clink. Bosses shoot back.',
      emoji: '🔪',
      slug: 'bladetoss',
      howToPlay:
          '• TAP to throw a knife at the spinning log. Only one flies at a time.\n• Don\'t hit a stuck knife — CLINK means game over!\n• The log gets faster and reverses. Bosses every 5 levels move and shoot back.\n• DRAG sideways to dodge red shots — a hit costs you a knife. 🔥',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => BladeTossScreen(players: players, callbacks: cb),
    );
  }
}
