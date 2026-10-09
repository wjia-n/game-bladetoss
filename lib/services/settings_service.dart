import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/forge_themes.dart';

/// Persisted profile + settings + stats for Blade Toss. Survives app restarts.
///
/// PLAYER NAMES: stored as ONE order-preserving JSON string under
/// [kNamesJson] via setString — `["Name"]`. NEVER setStringList: on Android
/// SharedPreferences backs StringLists with an unordered StringSet, which
/// scrambles slot order across restarts. Saved on EVERY keystroke, committed
/// on focus loss. Everything else lives in one more JSON string.
class ForgeSettings extends ChangeNotifier {
  static const kNamesJson = 'bladetoss_player_names_json';
  static const _kProfileJson = 'bladetoss_profile_json';
  // Legacy keys — migrated once, then removed.
  static const _kLegacyBest = 'bladetoss_best';
  static const _kLegacyName = 'bladetoss_name';

  static const defaultName = 'Thrower';

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String playerName = defaultName;
  int mode = 0; // 0 campaign, 1 endless, 2 time attack
  int difficulty = 1; // 0 easy, 1 normal, 2 hard (Pro)
  String themeId = 'oakforge';
  int bladeStyle = 0;
  int targetStyle = 0;
  bool isPro = false;

  // Lifetime stats.
  int bestCampaignScore = 0;
  int bestLevel = 0;
  int bestEndlessScore = 0;
  int bestTimeScore = 0;
  int gamesPlayed = 0;

  /// Custom theme creator colors (ARGB ints). Defaults mirror Oak Forge.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF2E2118,
    'woodMid': 0xFF4A3524,
    'woodDeep': 0xFF1A120C,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'ivory': 0xFFF5EFE0,
    'boardLight': 0xFFE3B871,
    'boardDark': 0xFFB98A48,
    'ring': 0xFF9A6E34,
    'bark': 0xFF5C3A21,
    'steel': 0xFFDDE3EA,
    'steelDark': 0xFF9AA4B0,
    'grip': 0xFF4A2F1B,
    'gripDark': 0xFF2E1C10,
    'shot': 0xFFD64545,
  };

  ForgeThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return ForgeThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      ivory: c('ivory'),
      boardLight: c('boardLight'),
      boardDark: c('boardDark'),
      ring: c('ring'),
      bark: c('bark'),
      steel: c('steel'),
      steelDark: c('steelDark'),
      grip: c('grip'),
      gripDark: c('gripDark'),
      shot: c('shot'),
    );
  }

  SharedPreferences? _prefs;

  Map<String, Object> _toJson() => {
        'v': 1,
        'musicOn': musicOn,
        'sfxOn': sfxOn,
        'volume': volume,
        'mode': mode,
        'difficulty': difficulty,
        'themeId': themeId,
        'bladeStyle': bladeStyle,
        'targetStyle': targetStyle,
        'isPro': isPro,
        'bestCampaignScore': bestCampaignScore,
        'bestLevel': bestLevel,
        'bestEndlessScore': bestEndlessScore,
        'bestTimeScore': bestTimeScore,
        'gamesPlayed': gamesPlayed,
        'customColors': Map.of(customColors),
      };

  void _fromJson(Map<String, Object?> j) {
    bool b(String k, bool d) => j[k] is bool ? j[k] as bool : d;
    int n(String k, int d) => j[k] is num ? (j[k] as num).toInt() : d;
    double f(String k, double d) => j[k] is num ? (j[k] as num).toDouble() : d;
    String s(String k, String d) => j[k] is String ? j[k] as String : d;

    musicOn = b('musicOn', true);
    sfxOn = b('sfxOn', true);
    volume = f('volume', 0.8).clamp(0.0, 1.0);
    mode = n('mode', 0).clamp(0, 2);
    difficulty = n('difficulty', 1).clamp(0, 2);
    themeId = s('themeId', 'oakforge');
    bladeStyle = n('bladeStyle', 0).clamp(0, BladeStyles.names.length - 1);
    targetStyle = n('targetStyle', 0).clamp(0, TargetStyles.names.length - 1);
    isPro = b('isPro', false);
    bestCampaignScore = n('bestCampaignScore', 0);
    bestLevel = n('bestLevel', 0);
    bestEndlessScore = n('bestEndlessScore', 0);
    bestTimeScore = n('bestTimeScore', 0);
    gamesPlayed = n('gamesPlayed', 0);
    final cc = j['customColors'];
    if (cc is Map) {
      for (final k in _defaultCustomColors.keys) {
        final v = cc[k];
        if (v is num) customColors[k] = v.toInt();
      }
    }
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    String? profileEmbeddedName;
    final raw = p.getString(_kProfileJson);
    if (raw != null) {
      try {
        final d = jsonDecode(raw);
        if (d is Map<String, dynamic>) {
          // Older builds embedded the name in the profile JSON;
          // it is a migration source now, never the live store.
          final pn = d['playerName'];
          if (pn is String && pn.trim().isNotEmpty) {
            profileEmbeddedName = pn.trim();
          }
          _fromJson(d);
        }
      } catch (_) {}
    }
    // Names live in ONE order-preserving JSON string.
    var name = defaultName;
    final namesRaw = p.getString(kNamesJson);
    if (namesRaw != null) {
      try {
        final d = jsonDecode(namesRaw);
        if (d is List && d.isNotEmpty && d.first is String) {
          final first = (d.first as String).trim();
          if (first.isNotEmpty) name = first;
        }
      } catch (_) {}
    } else {
      // One-time migration from legacy keys, then they are removed.
      final legacyName = p.getString(_kLegacyName);
      if (legacyName != null && legacyName.trim().isNotEmpty) {
        name = legacyName.trim();
      } else if (profileEmbeddedName != null) {
        name = profileEmbeddedName;
      }
      final legacyBest = p.getInt(_kLegacyBest);
      if (legacyBest != null && legacyBest > bestCampaignScore) {
        bestCampaignScore = legacyBest;
      }
      await p.remove(_kLegacyBest);
      await p.remove(_kLegacyName);
      await _saveNames(name);
      await _save();
    }
    playerName = name;
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kProfileJson, jsonEncode(_toJson()));
  }

  /// Write the name list as ONE JSON string. Called on every keystroke.
  Future<void> _saveNames(String name) async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(kNamesJson, jsonEncode([name]));
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || ForgeThemes.isProTheme(themeId)) {
      themeId = 'oakforge';
      changed = true;
    }
    if (BladeStyles.isPro(bladeStyle)) {
      bladeStyle = 0;
      changed = true;
    }
    if (TargetStyles.isPro(targetStyle)) {
      targetStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      unawaited(_save());
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  /// Save on EVERY keystroke (call from the field's onChanged) and commit
  /// on focus loss / dialog close. Never setStringList.
  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _saveNames(playerName);
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 2);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // hard mode is Pro
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    if (!isPro && (id == 'custom' || ForgeThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBladeStyle(int v) async {
    v = v.clamp(0, BladeStyles.names.length - 1);
    if (!isPro && BladeStyles.isPro(v)) return;
    bladeStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setTargetStyle(int v) async {
    v = v.clamp(0, TargetStyles.names.length - 1);
    if (!isPro && TargetStyles.isPro(v)) return;
    targetStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return;
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  /// Record a finished run. Returns true if any best was beaten.
  Future<bool> recordGame({
    required int modePlayed,
    required int score,
    required int level,
  }) async {
    var newBest = false;
    if (modePlayed == 0) {
      if (score > bestCampaignScore) {
        bestCampaignScore = score;
        newBest = true;
      }
      if (level > bestLevel) {
        bestLevel = level;
        newBest = true;
      }
    } else if (modePlayed == 1) {
      if (score > bestEndlessScore) {
        bestEndlessScore = score;
        newBest = true;
      }
    } else {
      if (score > bestTimeScore) {
        bestTimeScore = score;
        newBest = true;
      }
    }
    gamesPlayed++;
    notifyListeners();
    await _save();
    return newBest;
  }
}
