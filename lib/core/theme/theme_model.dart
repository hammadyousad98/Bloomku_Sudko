import 'package:flutter/material.dart';

enum BloomkuTheme { blossom, ocean, forest, cosmos, peach }

const List<Color> kBloomkuTileColors = [
  Color(0xFF57A8FB),
  Color(0xFFFFA661),
  Color(0xFF52D294),
  Color(0xFFAC81FB),
  Color(0xFFFFDB66),
  Color(0xFFFF87B8),
  Color(0xFFF22A77),
  Color(0xFF9CD12F),
  Color(0xFFD86F1F),
  Color(0xFFDA023D),
  Color(0xFF9707CD),
  Color(0xFF001DCC),
  Color(0xFF00D5FF),
  Color(0xFF7A4B2A),
  Color(0xFF00A896),
  Color(0xFF7F7F7F),
];

/// All visual data for a single theme.
class AppThemeData {
  final BloomkuTheme id;
  final String displayName;
  final List<String> objectIconPaths;
  final String objectName; // e.g. "Blossom", "Shell"
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color accentColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardColor;
  final Color panelColor;
  final List<Color> tileColors; // list of N colors for grid regions
  final bool isDark;

  const AppThemeData({
    required this.id,
    required this.displayName,
    required this.objectIconPaths,
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
    objectIconPaths: [
      'assets/icons/blossom.svg',
      'assets/icons/sunflower.svg',
      'assets/icons/daisy.svg',
    ],
    objectName: 'Blossom',
    backgroundTop: Color(0xFFFFF5F7),
    backgroundBottom: Color(0xFFFFE8EE),
    accentColor: Color(0xFFE8829A),
    textPrimary: Color(0xFF3D2C35),
    textSecondary: Color(0xFF8A6A75),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFFFF0F3),
    isDark: false,
    tileColors: kBloomkuTileColors,
  );

  static const AppThemeData ocean = AppThemeData(
    id: BloomkuTheme.ocean,
    displayName: 'Ocean',
    objectIconPaths: [
      'assets/icons/shell.svg',
      'assets/icons/starfish.svg',
      'assets/icons/wave.svg',
    ],
    objectName: 'Shell',
    backgroundTop: Color(0xFFF0F8FF),
    backgroundBottom: Color(0xFFE1F5FE),
    accentColor: Color(0xFF4FC3F7),
    textPrimary: Color(0xFF01579B),
    textSecondary: Color(0xFF0277BD),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFE3F2FD),
    isDark: false,
    tileColors: kBloomkuTileColors,
  );

  static const AppThemeData forest = AppThemeData(
    id: BloomkuTheme.forest,
    displayName: 'Forest',
    objectIconPaths: [
      'assets/icons/mushroom.svg',
      'assets/icons/tree.svg',
      'assets/icons/leaf.svg',
    ],
    objectName: 'Leaf',
    backgroundTop: Color(0xFFF1F8E9),
    backgroundBottom: Color(0xFFDCEDC8),
    accentColor: Color(0xFF8BC34A),
    textPrimary: Color(0xFF33691E),
    textSecondary: Color(0xFF558B2F),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFF1F8E9),
    isDark: false,
    tileColors: kBloomkuTileColors,
  );

  static const AppThemeData cosmos = AppThemeData(
    id: BloomkuTheme.cosmos,
    displayName: 'Cosmos',
    objectIconPaths: [
      'assets/icons/star.svg',
      'assets/icons/moon.svg',
      'assets/icons/planet.svg',
    ],
    objectName: 'Star',
    backgroundTop: Color(0xFF1A1A2E),
    backgroundBottom: Color(0xFF16213E),
    accentColor: Color(0xFFE94560),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB0B0B0),
    cardColor: Color(0xFF0F3460),
    panelColor: Color(0xFF2A2A4A),
    isDark: true,
    tileColors: kBloomkuTileColors,
  );

  static const AppThemeData peach = AppThemeData(
    id: BloomkuTheme.peach,
    displayName: 'Peach',
    objectIconPaths: [
      'assets/icons/peach.svg',
      'assets/icons/cherry.svg',
      'assets/icons/citrus.svg',
    ],
    objectName: 'Peach',
    backgroundTop: Color(0xFFFFF3E0),
    backgroundBottom: Color(0xFFFFE0B2),
    accentColor: Color(0xFFFF9800),
    textPrimary: Color(0xFFE65100),
    textSecondary: Color(0xFFEF6C00),
    cardColor: Color(0xFFFFFFFF),
    panelColor: Color(0xFFFFF3E0),
    isDark: false,
    tileColors: kBloomkuTileColors,
  );

  static const List<AppThemeData> all = [blossom, ocean, forest, cosmos, peach];

  static AppThemeData byIndex(int index) => all[index % all.length];
}
