import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/forge_art.dart';
import '../theme/forge_themes.dart';
import 'custom_theme_screen.dart';
import 'pro_screen.dart';

/// Blade Toss style picker: themes, blade styles, target styles.
class ThemeScreen extends StatelessWidget {
  final ForgeAudio audio;
  final ForgeSettings settings;
  final StoreService store;
  const ThemeScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  ForgeThemeDef _t() => ForgeThemes.byId(
        settings.themeId,
        custom: settings.customTheme,
      );

  void _openPro(BuildContext context) {
    audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: audio,
          settings: settings,
          store: store,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t();
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
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Workshop Styles',
              style: Forge.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) {
              final tt = _t();
              return ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                children: [
                  _Header(tt, 'THEMES',
                      '${ForgeThemes.freeThemeIds.length} free · ${ForgeThemes.all.length - ForgeThemes.freeThemeIds.length} pro'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: ForgeThemes.all.length,
                    itemBuilder: (_, i) {
                      final th = ForgeThemes.all[i];
                      final locked = !settings.isPro &&
                          ForgeThemes.isProTheme(th.id);
                      final selected = settings.themeId == th.id;
                      return _SwatchCard(
                        name: th.name,
                        colors: [
                          th.woodMid,
                          th.accent,
                          th.boardLight,
                          th.steel
                        ],
                        selected: selected,
                        locked: locked,
                        onTap: () {
                          audio.click();
                          if (locked) {
                            _openPro(context);
                          } else {
                            unawaited(settings.setTheme(th.id));
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  _CustomCard(
                    t: tt,
                    selected: settings.themeId == 'custom',
                    locked: !settings.isPro,
                    onTap: () {
                      audio.click();
                      if (!settings.isPro) {
                        _openPro(context);
                      } else {
                        unawaited(settings.setTheme('custom'));
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomThemeScreen(
                                audio: audio, settings: settings),
                          ),
                        );
                      }
                    },
                    onEdit: () {
                      audio.click();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CustomThemeScreen(
                              audio: audio, settings: settings),
                        ),
                      );
                    },
                  ),
                  _Header(tt, 'BLADE STYLES',
                      '${BladeStyles.freeCount} free · ${BladeStyles.names.length - BladeStyles.freeCount} pro'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: BladeStyles.names.length,
                    itemBuilder: (_, i) {
                      final locked = !settings.isPro &&
                          BladeStyles.isPro(i);
                      return _SwatchCard(
                        name: BladeStyles.names[i],
                        emoji: '🔪',
                        colors: const [],
                        selected: settings.bladeStyle == i,
                        locked: locked,
                        onTap: () {
                          audio.click();
                          if (locked) {
                            _openPro(context);
                          } else {
                            unawaited(settings.setBladeStyle(i));
                          }
                        },
                      );
                    },
                  ),
                  _Header(tt, 'TARGET STYLES',
                      '${TargetStyles.freeCount} free · ${TargetStyles.names.length - TargetStyles.freeCount} pro'),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.1,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: TargetStyles.names.length,
                    itemBuilder: (_, i) {
                      final locked = !settings.isPro &&
                          TargetStyles.isPro(i);
                      return _SwatchCard(
                        name: TargetStyles.names[i],
                        emoji: '🎯',
                        colors: const [],
                        selected: settings.targetStyle == i,
                        locked: locked,
                        onTap: () {
                          audio.click();
                          if (locked) {
                            _openPro(context);
                          } else {
                            unawaited(settings.setTargetStyle(i));
                          }
                        },
                      );
                    },
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

class _Header extends StatelessWidget {
  final ForgeThemeDef t;
  final String title;
  final String sub;
  const _Header(this.t, this.title, this.sub);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Forge.label(14, theme: t)),
          Text(sub,
              style: Forge.body(11,
                  theme: t, color: t.ivory.withValues(alpha: 0.6))),
        ],
      ),
    );
  }
}

class _SwatchCard extends StatelessWidget {
  final String name;
  final String? emoji;
  final List<Color> colors;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  const _SwatchCard({
    required this.name,
    this.emoji,
    required this.colors,
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
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.32),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.25),
            width: selected ? 2.5 : 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${locked ? '🔒 ' : ''}$name',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (emoji != null)
                  Text(emoji!,
                      style: const TextStyle(fontSize: 18)),
              ],
            ),
            if (colors.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final c in colors)
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CustomCard extends StatelessWidget {
  final ForgeThemeDef t;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const _CustomCard({
    required this.t,
    required this.selected,
    required this.locked,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: [
            t.accent.withValues(alpha: 0.25),
            Colors.black.withValues(alpha: 0.3)
          ]),
          border: Border.all(
              color: selected ? Colors.white : t.accent, width: selected ? 2.5 : 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${locked ? '🔒 ' : ''}My Creation',
                      style: Forge.label(14, theme: t)),
                  Text('Design your own workshop colors',
                      style: Forge.body(11,
                          theme: t,
                          color: t.ivory.withValues(alpha: 0.7))),
                ],
              ),
            ),
            if (!locked && selected)
              TextButton(
                onPressed: onEdit,
                child: Text('Edit 🎨',
                    style: Forge.label(13, theme: t)),
              ),
          ],
        ),
      ),
    );
  }
}
