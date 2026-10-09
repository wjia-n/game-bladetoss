import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import 'forge_themes.dart';

/// Forge design system for Blade Toss.
/// Workshop warmth: real woods, steel, brass. No neon, no generic Material.
///
/// All widgets accept an optional [ForgeThemeDef]; they default to the
/// Oak Forge theme so existing call sites keep working.
class Forge {
  static TextStyle display(double size, {Color? color, ForgeThemeDef? theme}) =>
      TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 1.2,
        shadows: const [
          Shadow(color: Color(0xFF1A0F08), offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, ForgeThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? theme?.ivory ?? const Color(0xFFF5EFE0),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, ForgeThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        letterSpacing: 0.8,
      );

  static ThemeData theme([ForgeThemeDef? t]) {
    t ??= ForgeThemes.byId('oakforge');
    final lightText = t.id == 'whitesmith';
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDark,
      colorScheme: ColorScheme(
        brightness: lightText ? Brightness.light : Brightness.dark,
        primary: t.accent,
        onPrimary: t.woodDeep,
        secondary: t.accentLight,
        onSecondary: t.woodDeep,
        surface: t.woodMid,
        onSurface: t.ivory,
        error: t.shot,
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
        bodyMedium: body(14, theme: t),
        labelLarge: label(14, theme: t),
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.woodMid),
    );
  }
}

/// Dark wood background with subtle vertical grain + vignette, theme-aware.
class WoodBackdrop extends StatelessWidget {
  final Widget child;
  final ForgeThemeDef? theme;
  const WoodBackdrop({super.key, required this.child, this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ForgeThemes.byId('oakforge');
    return Container(
      decoration: BoxDecoration(color: t.woodDark),
      child: CustomPaint(
        painter: _WoodGrainPainter(t),
        child: child,
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  final ForgeThemeDef t;
  _WoodGrainPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final vignette = RadialGradient(
      center: const Alignment(0, -0.25),
      radius: 1.15,
      colors: [
        t.woodMid.withValues(alpha: 0.55),
        t.woodDark.withValues(alpha: 0.0),
        Colors.black.withValues(alpha: 0.5),
      ],
      stops: const [0.0, 0.55, 1.0],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = vignette.createShader(Offset.zero & size),
    );
    // Subtle vertical planks.
    final plank = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 2;
    final n = max(2, size.width ~/ 90);
    for (int i = 1; i < n; i++) {
      final x = size.width * i / n;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), plank);
    }
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter old) => old.t != t;
}

/// Wooden plank button with brass trim.
class ForgeButton extends StatelessWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;
  final bool primary;
  final double width;
  final ForgeThemeDef? theme;
  const ForgeButton({
    super.key,
    required this.label,
    required this.emoji,
    required this.onTap,
    this.primary = false,
    this.width = 250,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ForgeThemes.byId('oakforge');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: primary
                ? [t.accentLight, t.accent, t.accentDark]
                : [t.woodMid, t.woodDeep],
          ),
          border: Border.all(
              color: primary ? t.ivory : t.accent.withValues(alpha: 0.7),
              width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45, offset: Offset(0, 4), blurRadius: 8),
          ],
        ),
        child: Text(
          '$emoji  $label',
          style: Forge.label(16,
              theme: t, color: primary ? t.woodDeep : t.accentLight),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Renameable thrower profile dialog.
///
/// Saves on EVERY keystroke (order-preserving JSON via setString — never
/// setStringList) and commits again on focus loss and on close.
Future<void> showThrowerNameDialog({
  required BuildContext context,
  required ForgeThemeDef theme,
  required ForgeSettings settings,
  required ForgeAudio audio,
}) async {
  final t = theme;
  final ctrl = TextEditingController(text: settings.playerName);
  final focus = FocusNode();
  // Commit on focus loss.
  focus.addListener(() {
    if (!focus.hasFocus) {
      unawaited(settings.setPlayerName(ctrl.text));
    }
  });
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(colors: [t.woodMid, t.woodDeep]),
          border: Border.all(color: t.accent, width: 2.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your thrower name', style: Forge.display(20, theme: t)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              focusNode: focus,
              autofocus: true,
              maxLength: 16,
              style: Forge.body(16, theme: t),
              // Save on EVERY keystroke.
              onChanged: (v) => settings.setPlayerName(v),
              decoration: InputDecoration(
                counterText: '',
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: t.accent),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: t.accentLight, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ForgeButton(
              label: 'Save',
              emoji: '✏️',
              theme: t,
              primary: true,
              width: 160,
              onTap: () {
                audio.click();
                unawaited(settings.setPlayerName(ctrl.text));
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
  // Final commit on close.
  unawaited(settings.setPlayerName(ctrl.text));
  focus.dispose();
  ctrl.dispose();
}

/// Small circular icon chip used on the menu.
class ForgeIconChip extends StatelessWidget {
  final IconData icon;
  final String caption;
  final VoidCallback onTap;
  final ForgeThemeDef? theme;
  const ForgeIconChip({
    super.key,
    required this.icon,
    required this.caption,
    required this.onTap,
    this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme ?? ForgeThemes.byId('oakforge');
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [t.woodMid, t.woodDeep],
              ),
              border: Border.all(color: t.accent, width: 2),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black45, offset: Offset(0, 3), blurRadius: 6),
              ],
            ),
            child: Icon(icon, color: t.accentLight, size: 26),
          ),
          const SizedBox(height: 6),
          Text(caption, style: Forge.label(11, theme: t)),
        ],
      ),
    );
  }
}
