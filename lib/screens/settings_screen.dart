import 'dart:async';

import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/forge_art.dart';
import '../theme/forge_themes.dart';

/// Blade Toss settings: audio, profile, difficulty, stats.
class SettingsScreen extends StatelessWidget {
  final ForgeAudio audio;
  final ForgeSettings settings;
  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  ForgeThemeDef _t() => ForgeThemes.byId(
        settings.themeId,
        custom: settings.customTheme,
      );

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
          title: Text('Settings', style: Forge.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              children: [
                _Section(t, 'SOUND'),
                _ToggleRow(
                  t: t,
                  label: 'Music',
                  value: settings.musicOn,
                  onChanged: (v) async {
                    audio.click();
                    await settings.setMusic(v);
                    audio.configure(
                        musicOn: v,
                        sfxOn: settings.sfxOn,
                        volume: settings.volume);
                    if (v) {
                      audio.startMenuMusic();
                    }
                  },
                ),
                _ToggleRow(
                  t: t,
                  label: 'Sound effects',
                  value: settings.sfxOn,
                  onChanged: (v) async {
                    await settings.setSfx(v);
                    audio.configure(
                        musicOn: settings.musicOn,
                        sfxOn: v,
                        volume: settings.volume);
                    if (v) audio.click();
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Row(
                    children: [
                      Text('Volume',
                          style: Forge.body(15, theme: t)),
                      Expanded(
                        child: Slider(
                          value: settings.volume,
                          activeColor: t.accent,
                          inactiveColor:
                              t.accent.withValues(alpha: 0.3),
                          onChanged: (v) {
                            unawaited(settings.setVolume(v));
                            audio.configure(
                                musicOn: settings.musicOn,
                                sfxOn: settings.sfxOn,
                                volume: v);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _Section(t, 'THROWER'),
                _Row(
                  t: t,
                  label: 'Name',
                  trailing: TextButton(
                    onPressed: () async {
                      audio.click();
                      await showThrowerNameDialog(
                        context: context,
                        theme: t,
                        settings: settings,
                        audio: audio,
                      );
                    },
                    child: Text('${settings.playerName} ✏️',
                        style: Forge.label(14, theme: t)),
                  ),
                ),
                _Section(t, 'STATS'),
                _Row(
                    t: t,
                    label: 'Games played',
                    trailing:
                        Text('${settings.gamesPlayed}',
                            style: Forge.body(15, theme: t))),
                _Row(
                    t: t,
                    label: 'Best campaign score',
                    trailing: Text('${settings.bestCampaignScore}',
                        style: Forge.body(15, theme: t))),
                _Row(
                    t: t,
                    label: 'Best level',
                    trailing: Text('${settings.bestLevel}',
                        style: Forge.body(15, theme: t))),
                _Row(
                    t: t,
                    label: 'Best endless score',
                    trailing: Text('${settings.bestEndlessScore}',
                        style: Forge.body(15, theme: t))),
                _Row(
                    t: t,
                    label: 'Best 60s score',
                    trailing: Text('${settings.bestTimeScore}',
                        style: Forge.body(15, theme: t))),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final ForgeThemeDef t;
  final String label;
  const _Section(this.t, this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(label, style: Forge.label(13, theme: t)),
    );
  }
}

class _Row extends StatelessWidget {
  final ForgeThemeDef t;
  final String label;
  final Widget trailing;
  const _Row({required this.t, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Forge.body(15, theme: t)),
          trailing,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final ForgeThemeDef t;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.t,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Forge.body(15, theme: t)),
          Switch(
            value: value,
            activeThumbColor: t.accentLight,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
