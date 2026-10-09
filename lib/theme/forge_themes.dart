import 'package:flutter/material.dart';

/// Blade Toss visual catalog — the Forge design world.
///
/// Physical workshop materials: woods, forged steel, brass/copper, leather.
/// No neon, no cyberpunk. Every entry is a real workshop palette.
class ForgeThemeDef {
  final String id;
  final String name;
  final Color woodDark; // backdrop / UI panels
  final Color woodMid;
  final Color woodDeep;
  final Color accent; // brass / copper / steel trim
  final Color accentLight;
  final Color accentDark;
  final Color ivory; // text
  final Color boardLight; // default target face
  final Color boardDark;
  final Color ring; // growth rings
  final Color bark;
  final Color steel; // default blade
  final Color steelDark;
  final Color grip; // default handle
  final Color gripDark;
  final Color shot; // enemy projectile

  const ForgeThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.woodDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.boardLight,
    required this.boardDark,
    required this.ring,
    required this.bark,
    required this.steel,
    required this.steelDark,
    required this.grip,
    required this.gripDark,
    required this.shot,
  });
}

class ForgeThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'oakforge',
    'ember',
    'steelhall',
    'tavern',
  ];

  static const List<ForgeThemeDef> all = [
    ForgeThemeDef(
      id: 'oakforge',
      name: 'Oak Forge',
      woodDark: Color(0xFF2E2118),
      woodMid: Color(0xFF4A3524),
      woodDeep: Color(0xFF1A120C),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EFE0),
      boardLight: Color(0xFFE3B871),
      boardDark: Color(0xFFB98A48),
      ring: Color(0xFF9A6E34),
      bark: Color(0xFF5C3A21),
      steel: Color(0xFFDDE3EA),
      steelDark: Color(0xFF9AA4B0),
      grip: Color(0xFF4A2F1B),
      gripDark: Color(0xFF2E1C10),
      shot: Color(0xFFD64545),
    ),
    ForgeThemeDef(
      id: 'ember',
      name: 'Ember Hearth',
      woodDark: Color(0xFF2B1512),
      woodMid: Color(0xFF462420),
      woodDeep: Color(0xFF160A08),
      accent: Color(0xFFE0783C),
      accentLight: Color(0xFFF2A96B),
      accentDark: Color(0xFF9A4E22),
      ivory: Color(0xFFF7EFE2),
      boardLight: Color(0xFFDF9E5C),
      boardDark: Color(0xFFB0763A),
      ring: Color(0xFF965E28),
      bark: Color(0xFF5A2E1A),
      steel: Color(0xFFE8D9C2),
      steelDark: Color(0xFFA89478),
      grip: Color(0xFF3A2318),
      gripDark: Color(0xFF241410),
      shot: Color(0xFFFF5A3C),
    ),
    ForgeThemeDef(
      id: 'steelhall',
      name: 'Steel Hall',
      woodDark: Color(0xFF1E2126),
      woodMid: Color(0xFF33373E),
      woodDeep: Color(0xFF101216),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      ivory: Color(0xFFF2F0E8),
      boardLight: Color(0xFFD9C49A),
      boardDark: Color(0xFFAE9A6E),
      ring: Color(0xFF8F7A52),
      bark: Color(0xFF4E4438),
      steel: Color(0xFFEFF4FA),
      steelDark: Color(0xFFAAB4C2),
      grip: Color(0xFF22262C),
      gripDark: Color(0xFF121418),
      shot: Color(0xFFE05252),
    ),
    ForgeThemeDef(
      id: 'tavern',
      name: 'Rustic Tavern',
      woodDark: Color(0xFF3A2416),
      woodMid: Color(0xFF5E3B20),
      woodDeep: Color(0xFF201209),
      accent: Color(0xFFB87333),
      accentLight: Color(0xFFE09E5A),
      accentDark: Color(0xFF7E4F22),
      ivory: Color(0xFFF6F0E0),
      boardLight: Color(0xFFEBBE78),
      boardDark: Color(0xFFC08F4E),
      ring: Color(0xFFA37335),
      bark: Color(0xFF654222),
      steel: Color(0xFFD8DFE8),
      steelDark: Color(0xFF98A1AD),
      grip: Color(0xFF6E3B1E),
      gripDark: Color(0xFF482512),
      shot: Color(0xFFD94F4F),
    ),
    ForgeThemeDef(
      id: 'nightanvil',
      name: 'Night Anvil',
      woodDark: Color(0xFF141821),
      woodMid: Color(0xFF232A38),
      woodDeep: Color(0xFF0A0D13),
      accent: Color(0xFF7FA8D9),
      accentLight: Color(0xFFAECBEE),
      accentDark: Color(0xFF4E6E96),
      ivory: Color(0xFFEEF2F7),
      boardLight: Color(0xFFC9A86E),
      boardDark: Color(0xFF9C7F4E),
      ring: Color(0xFF7E6338),
      bark: Color(0xFF3E352A),
      steel: Color(0xFFDCE8F5),
      steelDark: Color(0xFF8FA0B8),
      grip: Color(0xFF2A2438),
      gripDark: Color(0xFF171320),
      shot: Color(0xFFE05555),
    ),
    ForgeThemeDef(
      id: 'copperworks',
      name: 'Copperworks',
      woodDark: Color(0xFF2A1D14),
      woodMid: Color(0xFF453023),
      woodDeep: Color(0xFF171009),
      accent: Color(0xFFC77B4A),
      accentLight: Color(0xFFE8A878),
      accentDark: Color(0xFF8A5228),
      ivory: Color(0xFFF7F0E2),
      boardLight: Color(0xFFE0B46E),
      boardDark: Color(0xFFB38846),
      ring: Color(0xFF92682E),
      bark: Color(0xFF59391E),
      steel: Color(0xFFEAD9C4),
      steelDark: Color(0xFFA89478),
      grip: Color(0xFF54301A),
      gripDark: Color(0xFF371E10),
      shot: Color(0xFFD94A4A),
    ),
    ForgeThemeDef(
      id: 'forestden',
      name: 'Forest Den',
      woodDark: Color(0xFF22281A),
      woodMid: Color(0xFF3A422A),
      woodDeep: Color(0xFF12150C),
      accent: Color(0xFFA3B86B),
      accentLight: Color(0xFFC9D896),
      accentDark: Color(0xFF6E8240),
      ivory: Color(0xFFF1F0DE),
      boardLight: Color(0xFFD8B474),
      boardDark: Color(0xFFAD8C52),
      ring: Color(0xFF8C6C38),
      bark: Color(0xFF4A3E26),
      steel: Color(0xFFDDE3EA),
      steelDark: Color(0xFF9AA4B0),
      grip: Color(0xFF3E4A24),
      gripDark: Color(0xFF262E16),
      shot: Color(0xFFD64545),
    ),
    ForgeThemeDef(
      id: 'ironworks',
      name: 'Ironworks',
      woodDark: Color(0xFF1C1A18),
      woodMid: Color(0xFF322E2A),
      woodDeep: Color(0xFF0E0D0B),
      accent: Color(0xFF8E9299),
      accentLight: Color(0xFFBCC1C9),
      accentDark: Color(0xFF5C6066),
      ivory: Color(0xFFF0EEE8),
      boardLight: Color(0xFFCFA968),
      boardDark: Color(0xFFA37F44),
      ring: Color(0xFF82622E),
      bark: Color(0xFF443820),
      steel: Color(0xFFEBF0F6),
      steelDark: Color(0xFFA6AEBB),
      grip: Color(0xFF3A2A1C),
      gripDark: Color(0xFF241A12),
      shot: Color(0xFFE05252),
    ),
    ForgeThemeDef(
      id: 'brassforge',
      name: 'Brass Forge',
      woodDark: Color(0xFF2C2210),
      woodMid: Color(0xFF4A3A1C),
      woodDeep: Color(0xFF181106),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      ivory: Color(0xFFF8F1DE),
      boardLight: Color(0xFFE6BE72),
      boardDark: Color(0xFFBA944E),
      ring: Color(0xFF977436),
      bark: Color(0xFF5E4522),
      steel: Color(0xFFEDE4C8),
      steelDark: Color(0xFFA89A74),
      grip: Color(0xFF4E3A14),
      gripDark: Color(0xFF32250C),
      shot: Color(0xFFD94F4F),
    ),
    ForgeThemeDef(
      id: 'slatearmory',
      name: 'Slate Armory',
      woodDark: Color(0xFF23262B),
      woodMid: Color(0xFF3A3E45),
      woodDeep: Color(0xFF121417),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF2F0E8),
      boardLight: Color(0xFFD4B678),
      boardDark: Color(0xFFA98E56),
      ring: Color(0xFF88703C),
      bark: Color(0xFF4C4534),
      steel: Color(0xFFE4EAF2),
      steelDark: Color(0xFF9CA6B4),
      grip: Color(0xFF2E3438),
      gripDark: Color(0xFF1C2023),
      shot: Color(0xFFE05555),
    ),
    ForgeThemeDef(
      id: 'crimsonforge',
      name: 'Crimson Forge',
      woodDark: Color(0xFF2E1216),
      woodMid: Color(0xFF4C2028),
      woodDeep: Color(0xFF180A0D),
      accent: Color(0xFFD48A4A),
      accentLight: Color(0xFFECB178),
      accentDark: Color(0xFF945828),
      ivory: Color(0xFFF8F0E4),
      boardLight: Color(0xFFDEA862),
      boardDark: Color(0xFFB37E40),
      ring: Color(0xFF92612C),
      bark: Color(0xFF552F1A),
      steel: Color(0xFFE8DFD2),
      steelDark: Color(0xFFA39880),
      grip: Color(0xFF4A1E22),
      gripDark: Color(0xFF2E1216),
      shot: Color(0xFFFF4A3C),
    ),
    ForgeThemeDef(
      id: 'whitesmith',
      name: 'Whitesmith',
      woodDark: Color(0xFFE4D6BC),
      woodMid: Color(0xFFF0E4CC),
      woodDeep: Color(0xFFBCA87E),
      accent: Color(0xFF2E5A88),
      accentLight: Color(0xFF5E8AC0),
      accentDark: Color(0xFF1E3A5C),
      ivory: Color(0xFF2E2118),
      boardLight: Color(0xFFEBBE78),
      boardDark: Color(0xFFC08F4E),
      ring: Color(0xFFA37335),
      bark: Color(0xFF654222),
      steel: Color(0xFFF2F5F9),
      steelDark: Color(0xFFAAB4C2),
      grip: Color(0xFF2E5A88),
      gripDark: Color(0xFF1E3A5C),
      shot: Color(0xFFC0392B),
    ),
  ];

  static ForgeThemeDef byId(String id, {ForgeThemeDef? custom}) {
    if (id == 'custom') return custom ?? all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

/// Blade styles. 0-3 = FREE, 4+ = PRO. Index drives the painter variant.
class BladeStyles {
  static const names = [
    'Classic Thrower',
    'Kitchen Knife',
    'Hunting Bowie',
    'Stiletto',
    'Cleaver',
    'Kunai',
    'Hatchet',
    'Dagger',
    'Machete',
    'Kris',
  ];
  static const descriptions = [
    'Balanced throwing knife, leather wrap grip',
    'Chef\'s blade on a riveted wood handle',
    'Heavy clipped blade, stag-style grip',
    'Slim needle point, dark wrapped hilt',
    'Butcher\'s cleaver, brass rivets',
    'Leaf blade with ring pommel',
    'Small camp hatchet, hickory handle',
    'Double-edged dagger, brass guard',
    'Long brush blade, cord-wrapped grip',
    'Wavy ceremonial blade, carved hilt',
  ];

  /// Indices free players may use.
  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;
}

/// Target styles. 0-3 = FREE, 4+ = PRO. Index drives the painter variant.
class TargetStyles {
  static const names = [
    'Oak Round',
    'Birch Round',
    'Walnut Round',
    'Cherry Round',
    'Maple Round',
    'Charred Log',
    'Painted Rings',
    'Burl Target',
  ];
  static const descriptions = [
    'Fresh-cut oak with bold grain',
    'Pale birch, fine tight rings',
    'Dark walnut, rich depth',
    'Warm cherry with soft glow',
    'Light maple, clean face',
    'Fire-charred log, rough bark',
    'Classic painted ring target',
    'Knotted burl with wild grain',
  ];

  /// Indices free players may use.
  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;
}
