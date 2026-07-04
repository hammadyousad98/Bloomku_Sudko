import 'package:objectbox/objectbox.dart';
import '../models/settings_model.dart';

/// Repository for handling user settings.
class SettingsRepository {
  SettingsRepository(this._box);
  final Box<SettingsModel> _box;

  /// Returns the single SettingsModel record, creating it if absent.
  SettingsModel getSettings() {
    final existing = _box.getAll();
    if (existing.isNotEmpty) return existing.first;
    
    // New object MUST have id = 0 for ObjectBox to auto-assign
    final defaults = SettingsModel(); // id defaults to 0
    _box.put(defaults);
    return defaults;
  }

  void saveSettings(SettingsModel settings) {
    _box.put(settings);
  }

  double get musicVolume => getSettings().musicVolume;
  set musicVolume(double value) {
    final s = getSettings();
    s.musicVolume = value;
    saveSettings(s);
  }

  double get sfxVolume => getSettings().sfxVolume;
  set sfxVolume(double value) {
    final s = getSettings();
    s.sfxVolume = value;
    saveSettings(s);
  }

  int get selectedThemeIndex => getSettings().selectedThemeIndex;
  set selectedThemeIndex(int value) {
    final s = getSettings();
    s.selectedThemeIndex = value;
    saveSettings(s);
  }

  bool get vibrationEnabled => getSettings().vibrationEnabled;
  set vibrationEnabled(bool value) {
    final s = getSettings();
    s.vibrationEnabled = value;
    saveSettings(s);
  }
}
