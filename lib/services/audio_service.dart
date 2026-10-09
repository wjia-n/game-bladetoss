import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Procedural audio for Blade Toss — all sounds synthesized in code as WAV.
/// No asset files. Workshop-appropriate: wood thunks, steel clangs, whooshes.
///
/// Reliability design (every call is safe to repeat and safe to overlap):
/// - Music clips are synthesized ONCE and cached; starting music never blocks
///   the UI thread after the first build.
/// - A [_musicGen] generation counter serializes track changes: every
///   start/stop bumps the generation, in-flight work from an older request
///   aborts, and the LATEST request always wins.
/// - Lifecycle uses pause()/resume() so an interruption (call, backgrounding)
///   resumes exactly where it left off.
/// - Every public method catches player errors; audio can never crash the app.
class ForgeAudio {
  static const int _rate = 22050;
  final AudioPlayer _sfx = AudioPlayer();
  final AudioPlayer _music = AudioPlayer();
  final _rand = Random();

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;

  final Map<String, Uint8List> _cache = {};

  int _musicGen = 0;
  bool _musicBusy = false;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  ForgeAudio() {
    unawaited(_music.setReleaseMode(ReleaseMode.loop));
  }

  void configure(
      {required bool musicOn, required bool sfxOn, required double volume}) {
    this.musicOn = musicOn;
    this.sfxOn = sfxOn;
    volume = volume.clamp(0.0, 1.0);
    this.volume = volume;
    unawaited(_music.setVolume(musicOn ? volume * 0.55 : 0.0));
    unawaited(_sfx.setVolume(sfxOn ? volume : 0.0));
    if (!musicOn) unawaited(stopMusic());
  }

  /// Pre-build music clips off the critical path. Safe to call any time.
  Future<void> prewarm() async {
    if (_disposed) return;
    await Future(() {});
    _menuBytes();
    _gameBytes();
  }

  // ---------------------------------------------------------- WAV synthesis
  Uint8List _wav(List<double> samples) {
    final n = samples.length;
    final data = ByteData(44 + n * 2);
    void writeStr(int o, String s) {
      for (int i = 0; i < s.length; i++) {
        data.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    writeStr(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    writeStr(8, 'WAVE');
    writeStr(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _rate, Endian.little);
    data.setUint32(28, _rate * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    writeStr(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      final v = samples[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _env(int i, int n, {double attack = 0.02}) {
    final t = i / n;
    final a = (t / attack).clamp(0.0, 1.0);
    final d = pow(1 - t, 2.2).toDouble();
    return a * d;
  }

  List<double> _tone(double freq, double secs,
      {double freqEnd = 0, double attack = 0.02, double harmonics = 0.25}) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final f = freqEnd > 0 ? freq + (freqEnd - freq) * (i / n) : freq;
      final ph = 2 * pi * f * t;
      out[i] = _env(i, n, attack: attack) *
          (sin(ph) + harmonics * sin(2 * ph) + harmonics * 0.5 * sin(3 * ph));
    }
    return out;
  }

  List<double> _thunk() {
    // Blade biting into wood: low thump + fibrous crack.
    final n = (_rate * 0.16).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      out[i] = _env(i, n, attack: 0.004) *
          (0.95 * sin(2 * pi * 150 * t) * exp(-t * 34) +
              0.5 * sin(2 * pi * 300 * t) * exp(-t * 60) +
              0.3 * (_rand.nextDouble() * 2 - 1) * exp(-t * 110));
    }
    return out;
  }

  List<double> _clang() {
    // Steel-on-steel clink: inharmonic partials with fast decay.
    final n = (_rate * 0.7).round();
    final out = List<double>.filled(n, 0);
    const partials = [2093.0, 2794.0, 3518.0, 4720.0];
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      double v = 0;
      for (int k = 0; k < partials.length; k++) {
        v += sin(2 * pi * partials[k] * t) * exp(-t * (9 + k * 7)) / (k + 1);
      }
      out[i] = _env(i, n, attack: 0.003) * v * 0.8;
    }
    return out;
  }

  List<double> _whoosh() {
    // Knife throw: filtered noise sweep, 0.22s.
    final n = (_rate * 0.22).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / _rate;
      final cut = 400 + 2600 * sin(pi * i / n); // sweeping brightness
      out[i] = _env(i, n, attack: 0.25) *
          (_rand.nextDouble() * 2 - 1) *
          (0.35 + 0.65 * sin(2 * pi * cut * t).abs()) *
          0.5;
    }
    return out;
  }

  List<double> _arp(List<double> freqs, double noteSecs, double gapSecs) {
    final out = <double>[];
    for (final f in freqs) {
      out.addAll(_tone(f, noteSecs, harmonics: 0.2));
      out.addAll(List<double>.filled((_rate * gapSecs).round(), 0));
    }
    return out;
  }

  List<double> _padChord(List<double> freqs, double secs) {
    final n = (_rate * secs).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      double v = 0;
      for (final f in freqs) {
        final t = i / _rate;
        v += sin(2 * pi * f * t) + 0.3 * sin(2 * pi * f * 2 * t);
      }
      v /= freqs.length * 1.3;
      final t = i / n;
      final swell = sin(pi * t.clamp(0.0, 1.0));
      out[i] = v * (0.35 + 0.65 * swell);
    }
    return out;
  }

  Uint8List _clip(String key, List<double> Function() build) =>
      _cache.putIfAbsent(key, () => _wav(build()));

  Uint8List _menuBytes() => _clip('music_menu', () {
        // Warm tavern loop: Am – F – C – G pads, 16s.
        final seq = [
          [220.0, 261.63, 329.63],
          [174.61, 220.0, 261.63],
          [261.63, 329.63, 392.0],
          [196.0, 246.94, 293.66],
        ];
        final out = <double>[];
        for (final chord in seq) {
          out.addAll(_padChord(chord, 4.0));
        }
        // A few plucked melody notes over the top.
        final notes = [440.0, 523.25, 587.33, 523.25];
        final n = (_rate * 16).round();
        final full = List<double>.from(out);
        for (int k = 0; k < notes.length; k++) {
          final start = (n * (k * 4 + 2) / 16).round();
          final tone = _tone(notes[k], 0.5, harmonics: 0.35);
          for (int i = 0; i < tone.length && start + i < n; i++) {
            full[start + i] += tone[i] * 0.3;
          }
        }
        return full;
      });

  Uint8List _gameBytes() => _clip('music_game', () {
        // Driving forge loop: low drum pulse + urgent plucks, 8s.
        final n = (_rate * 8).round();
        final out = List<double>.filled(n, 0);
        // Drum pulse: low thump every beat (120 bpm).
        final thump = _tone(90, 0.18, harmonics: 0.1);
        for (int b = 0; b < 16; b++) {
          final start = (n * b / 16).round();
          for (int i = 0; i < thump.length && start + i < n; i++) {
            out[start + i] += thump[i] * 0.55;
          }
        }
        // Pentatonic plucks.
        final plucks = [392.0, 440.0, 523.25, 440.0, 392.0, 329.63, 293.66, 329.63];
        for (int k = 0; k < plucks.length; k++) {
          final start = (n * k / plucks.length).round();
          final tone = _tone(plucks[k], 0.32, harmonics: 0.4);
          for (int i = 0; i < tone.length && start + i < n; i++) {
            out[start + i] += tone[i] * 0.32;
          }
        }
        return out;
      });

  // ------------------------------------------------------------------ SFX
  Future<void> _play(Uint8List bytes) async {
    if (!sfxOn || _disposed) return;
    try {
      await _sfx.play(BytesSource(bytes));
    } catch (_) {}
  }

  Future<void> click() => _play(_clip('click', () => _tone(1150, 0.06)));
  Future<void> throwKnife() => _play(_clip('throw', _whoosh));
  Future<void> knifeStick() => _play(_clip('stick', _thunk));
  Future<void> clink() => _play(_clip('clink', _clang));
  Future<void> dodge() =>
      _play(_clip('dodge', () => _tone(500, 0.12, freqEnd: 900)));
  Future<void> playerHit() =>
      _play(_clip('hit', () => _tone(140, 0.25, harmonics: 0.5)));
  Future<void> invalid() =>
      _play(_clip('invalid', () => _tone(150, 0.16, harmonics: 0.5)));
  Future<void> countdownTick() => _play(_clip('tick', () => _tone(880, 0.09)));
  Future<void> levelClear() => _play(_clip('clear',
      () => _arp([392.0, 523.25, 659.25, 783.99], 0.14, 0.03)));
  Future<void> win() => _play(_clip(
      'win', () => _arp([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.16, 0.03)));
  Future<void> gameOver() => _play(
      _clip('lose', () => _arp([392.0, 329.63, 261.63, 196.0], 0.22, 0.04)));
  Future<void> bossWarn() =>
      _play(_clip('bosswarn', () => _tone(220, 0.4, freqEnd: 110)));

  // ----------------------------------------------------------------- music
  Future<void> _startTrack(String track, Uint8List Function() bytes) async {
    if (_disposed) return;
    final gen = ++_musicGen;
    if (_currentTrack == track && !_pausedByLifecycle) {
      try {
        await _music.resume();
      } catch (_) {}
      return;
    }
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (gen != _musicGen || _disposed || !musicOn) return;
    _musicBusy = true;
    try {
      await _music.stop();
      if (gen != _musicGen || _disposed || !musicOn) return;
      _currentTrack = track;
      _pausedByLifecycle = false;
      await _music.play(BytesSource(bytes()));
    } catch (_) {
      if (gen == _musicGen) _currentTrack = null;
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> startMenuMusic() => _startTrack('menu', _menuBytes);
  Future<void> startGameMusic() => _startTrack('game', _gameBytes);

  Future<void> stopMusic() async {
    ++_musicGen;
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (_disposed) return;
    try {
      await _music.stop();
    } catch (_) {}
    _currentTrack = null;
    _pausedByLifecycle = false;
  }

  Future<void> onAppPaused() async {
    if (_disposed || _currentTrack == null) return;
    try {
      await _music.pause();
      _pausedByLifecycle = true;
    } catch (_) {}
  }

  Future<void> onAppResumed() async {
    if (_disposed || !musicOn || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    try {
      await _music.resume();
    } catch (_) {
      final track = _currentTrack;
      _currentTrack = null;
      if (track == 'menu') {
        await startMenuMusic();
      } else if (track == 'game') {
        await startGameMusic();
      }
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    try {
      await _sfx.dispose();
      await _music.dispose();
    } catch (_) {}
  }
}
