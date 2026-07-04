import 'package:flutter/material.dart';

enum BloomkuTheme { blossom, ocean, forest, cosmos, peach }

/// All visual data for a single theme.
class AppThemeData {
  final BloomkuTheme id;
  final String displayName;
  final String objectIconPath;   // SVG asset path
  final String objectName;       // e.g. "Blossom", "Shell"
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color accentColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color panelColor;
  final List<Color> tileColors;  // list of N colors for grid regions
  final bool isDark;

  const AppThemeData({
    required this.id,
    required this.displayName,
    required this.objectIconPath,
    required this.objectName,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.accentColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardColor,
    required this.panelColor,
    required this.tileColors,
    required this.isDark,
  });
}

/// Registry of all 5 themes.
class BloomkuThemes {
  static const AppThemeData blossom = AppThemeData(
    id: BloomkuTheme.blossom,
    displayName: 'Blossom',
    objectIconPath: 'assets/icons/blossom.svg',
    objectName: 'Blossom',
    backgroundTop: Color(0xFFFFF5F7),
    backgroundBottom: Color(0xFFFFE8EE),
    accentColor: Color(0xFFE8829A),
    textPrimary: Color(0xFF3D2C35),
    textSecondary: Color(0xFF8A6A75),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFFFF0F3),
    isDark: false,
    tileColors: [
      Color(0xFFF4B8C8), Color(0xFFC8E6C4), Color(0xFFB3D9F2),
      Color(0xFFF7E4A0), Color(0xFFD4B8E8), Color(0xFFF9C9A0),
      Color(0xFFA8D4C8), Color(0xFFE8C4D4), Color(0xFFB8D4A8),
      Color(0xFFF0C8B8), Color(0xFFC4B8E8), Color(0xFFD4E8C4),
      Color(0xFFE8D4A8), Color(0xFFB8C8E8), Color(0xFFF4C4B8),
    ],
  );

  static const AppThemeData ocean = AppThemeData(
    id: BloomkuTheme.ocean,
    displayName: 'Ocean',
    objectIconPath: 'assets/icons/ocean.svg',
    objectName: 'Shell',
    backgroundTop: Color(0xFFF0F8FF),
    backgroundBottom: Color(0xFFE1F5FE),
    accentColor: Color(0xFF4FC3F7),
    textPrimary: Color(0xFF01579B),
    textSecondary: Color(0xFF0277BD),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFE3F2FD),
    isDark: false,
    tileColors: [
      Color(0xFF81D4FA), Color(0xFF4FC3F7), Color(0xFF29B6F6),
      Color(0xFF03A9F4), Color(0xFF039BE5), Color(0xFF0288D1),
      Color(0xFF0277BD), Color(0xFF01579B), Color(0xFFB3E5FC),
      Color(0xFFE1F5FE), Color(0xFF80D8FF), Color(0xFF40C4FF),
      Color(0xFF00B0FF), Color(0xFF0091EA), Color(0xFF84FFFF),
    ],
  );

  static const AppThemeData forest = AppThemeData(
    id: BloomkuTheme.forest,
    displayName: 'Forest',
    objectIconPath: 'assets/icons/forest.svg',
    objectName: 'Leaf',
    backgroundTop: Color(0xFFF1F8E9),
    backgroundBottom: Color(0xFFDCEDC8),
    accentColor: Color(0xFF8BC34A),
    textPrimary: Color(0xFF33691E),
    textSecondary: Color(0xFF558B2F),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFF1F8E9),
    isDark: false,
    tileColors: [
      Color(0xFFAED581), Color(0xFF8BC34A), Color(0xFF7CB342),
      Color(0xFF689F38), Color(0xFF558B2F), Color(0xFF33691E),
      Color(0xFFC5E1A5), Color(0xFFDCEDC8), Color(0xFFF1F8E9),
      Color(0xFFCCFF90), Color(0xFFB2FF59), Color(0xFF76FF03),
      Color(0xFF64DD17), Color(0xFFDCE775), Color(0xFFD4E157),
    ],
  );

  static const AppThemeData cosmos = AppThemeData(
    id: BloomkuTheme.cosmos,
    displayName: 'Cosmos',
    objectIconPath: 'assets/icons/cosmos.svg',
    objectName: 'Star',
    backgroundTop: Color(0xFF1A1A2E),
    backgroundBottom: Color(0xFF16213E),
    accentColor: Color(0xFFE94560),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    cardColor: Color(0xFF0F3460),
    panelColor: Color(0xFF2A2A4A),
    isDark: true,
    tileColors: [
      Color(0xFF301B3F), Color(0xFF3C415C), Color(0xFFB4A5A5),
      Color(0xFF151515), Color(0xFFE94560), Color(0xFF0F3460),
      Color(0xFF53354A), Color(0xFF903749), Color(0xFFE84545),
      Color(0xFF2B2E4A), Color(0xFF4C0027), Color(0xFF8B104E),
      Color(0xFF540E33), Color(0xFF341031), Color(0xFF6A097D),
    ],
  );

  static const AppThemeData peach = AppThemeData(
    id: BloomkuTheme.peach,
    displayName: 'Peach',
    objectIconPath: 'assets/icons/peach.svg',
    objectName: 'Peach',
    backgroundTop: Color(0xFFFFF3E0),
    backgroundBottom: Color(0xFFFFE0B2),
    accentColor: Color(0xFFFF9800),
    textPrimary: Color(0xFFE65100),
    textSecondary: Color(0xFFEF6C00),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFFFF3E0),
    isDark: false,
    tileColors: [
      Color(0xFFFFB74D), Color(0xFFFFA726), Color(0xFFFF9800),
      Color(0xFFFB8C00), Color(0xFFF57C00), Color(0xFFEF6C00),
      Color(0xFFFFCC80), Color(0xFFFFE0B2), Color(0xFFFFF3E0),
      Color(0xFFFFD180), Color(0xFFFFAB40), Color(0xFFFF9100),
      Color(0xFFFF6D00), Color(0xFFFFCCBC), Color(0xFFFFAB91),
    ],
  );

  static const List<AppThemeData> all = [blossom, ocean, forest, cosmos, peach];

  static AppThemeData byIndex(int index) => all[index % all.length];
}
