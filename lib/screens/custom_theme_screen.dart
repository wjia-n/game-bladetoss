import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/forge_art.dart';
import '../theme/forge_themes.dart';

/// PRO: custom theme creator — pick workshop colors. Live preview, persisted.
class CustomThemeScreen extends StatefulWidget {
  final ForgeAudio audio;
  final ForgeSettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  @override
  State<CustomThemeScreen> createState() => _CustomThemeScreenState();
}

class _CustomThemeScreenState extends State<CustomThemeScreen> {
  ForgeThemeDef get _t => ForgeThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  // Curated workshop-friendly palette.
  static const List<Color> palette = [
    Color(0xFF2E2118), Color(0xFF4A3524), Color(0xFF1A120C),
    Color(0xFF3A2416), Color(0xFF5E3B20), Color(0xFF201209),
    Color(0xFF1E2126), Color(0xFF33373E), Color(0xFF101216),
    Color(0xFFC9A227), Color(0xFFE8CE7A), Color(0xFF8A6D1A),
    Color(0xFFB87333), Color(0xFFE09E5A), Color(0xFF7E4F22),
    Color(0xFFC0C6D4), Color(0xFFE8ECF5), Color(0xFF7E8698),
    Color(0xFFF5EFE0), Color(0xFFFAF6EE), Color(0xFF2E2118),
    Color(0xFFE3B871), Color(0xFFB98A48), Color(0xFF9A6E34),
    Color(0xFF5C3A21), Color(0xFF8A5E38), Color(0xFF654222),
    Color(0xFFC98A5E), Color(0xFFA3653F), Color(0xFF7E4B28),
    Color(0xFFDDE3EA), Color(0xFF9AA4B0), Color(0xFF4A2F1B),
    Color(0xFF2E1C10), Color(0xFFD64545), Color(0xFFFF5A3C),
    Color(0xFF2E5A88), Color(0xFF5E8AC0), Color(0xFF1E3A5C),
  ];

  static const rows = [
    ('Wood dark', 'woodDark'),
    ('Wood mid', 'woodMid'),
    ('Wood deep', 'woodDeep'),
    ('Accent metal', 'accent'),
    ('Accent light', 'accentLight'),
    ('Accent dark', 'accentDark'),
    ('Ivory text', 'ivory'),
    ('Target light', 'boardLight'),
    ('Target dark', 'boardDark'),
    ('Growth rings', 'ring'),
    ('Bark', 'bark'),
    ('Blade steel', 'steel'),
    ('Blade dark', 'steelDark'),
    ('Grip', 'grip'),
    ('Grip dark', 'gripDark'),
    ('Boss shots', 'shot'),
  ];

  Future<void> _pick(String key, String label) async {
    final s = widget.settings;
    final chosen = await showDialog<Color>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [
              _t.woodMid,
              _t.woodDeep,
            ]),
            border: Border.all(color: _t.accent, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pick $label',
                  style: Forge.display(20, theme: _t)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final c in palette)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(c),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: c.toARGB32() ==
                                    s.customColors[key]
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            width: c.toARGB32() == s.customColors[key]
                                ? 3
                                : 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) {
      widget.audio.click();
      await s.setCustomColor(key, chosen.toARGB32());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('My Creation',
              style: Forge.display(22, theme: t)),
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () {
                widget.audio.click();
                unawaited(s.resetCustomColors());
              },
              child: Text('Reset',
                  style: Forge.label(13, theme: t)),
            ),
          ],
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) {
              final tt = _t;
              return ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                children: [
                  // Live preview: mini target with a blade.
                  Center(
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: tt.bark, width: 10),
                      ),
                      child: CustomPaint(
                        painter: _PreviewPainter(tt),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final r in rows)
                    GestureDetector(
                      onTap: () => _pick(r.$2, r.$1),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color:
                              Colors.black.withValues(alpha: 0.3),
                          border: Border.all(
                              color: tt.accent
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(r.$1,
                                style: Forge.body(14, theme: tt)),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(
                                    s.customColors[r.$2]!),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.6),
                                    width: 2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 30),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  final ForgeThemeDef t;
  _PreviewPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [t.boardLight, t.boardDark],
          ).createShader(Rect.fromCircle(center: c, radius: r)));
    for (final f in [0.35, 0.6, 0.85]) {
      canvas.drawCircle(
          c,
          r * f,
          Paint()
            ..color = t.ring.withValues(alpha: 0.7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
    }
    // A blade stuck at the top.
    final blade = Path()
      ..moveTo(c.dx - 6, c.dy - r * 0.55)
      ..lineTo(c.dx + 6, c.dy - r * 0.55)
      ..lineTo(c.dx + 6, c.dy - r * 0.55 - 26)
      ..lineTo(c.dx, c.dy - r * 0.55 - 36)
      ..lineTo(c.dx - 6, c.dy - r * 0.55 - 26)
      ..close();
    canvas.drawPath(blade, Paint()..color = t.steel);
    canvas.drawRect(
        Rect.fromLTWH(c.dx - 8, c.dy - r * 0.55, 16, 22),
        Paint()..color = t.grip);
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter old) => old.t != t;
}
