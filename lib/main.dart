import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/iap_service.dart';
import 'services/settings_service.dart';
import 'theme/forge_art.dart';
import 'theme/forge_themes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final settings = ForgeSettings();
  await settings.load();
  final audio = ForgeAudio();
  audio.configure(
    musicOn: settings.musicOn,
    sfxOn: settings.sfxOn,
    volume: settings.volume,
  );
  final store = StoreService();
  // Fire-and-forget: the Pro screen renders an honest "after store setup"
  // state until real products are queryable; never blocks the splash.
  unawaited(store.init());
  runApp(BladeTossApp(settings: settings, audio: audio, store: store));
}

class BladeTossApp extends StatefulWidget {
  final ForgeSettings settings;
  final ForgeAudio audio;
  final StoreService store;
  const BladeTossApp({
    super.key,
    required this.settings,
    required this.audio,
    required this.store,
  });

  @override
  State<BladeTossApp> createState() => _BladeTossAppState();
}

class _BladeTossAppState extends State<BladeTossApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.audio.dispose();
    widget.store.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause (not stop) on interruption so music resumes exactly where it
    // left off; game screens additionally freeze their engines.
    if (state == AppLifecycleState.paused) {
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.settings,
      builder: (_, _) => MaterialApp(
        title: 'Blade Toss',
        debugShowCheckedModeBanner: false,
        theme: Forge.theme(ForgeThemes.byId(
          widget.settings.themeId,
          custom: widget.settings.customTheme,
        )),
        home: SplashScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }
}
