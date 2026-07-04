import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/audio_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SettingsState extends Equatable {
  final double musicVolume;
  final double sfxVolume;
  final bool vibrationEnabled;
  final int selectedThemeIndex;

  const SettingsState({
    required this.musicVolume,
    required this.sfxVolume,
    required this.vibrationEnabled,
    required this.selectedThemeIndex,
  });

  SettingsState copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? vibrationEnabled,
    int? selectedThemeIndex,
  }) {
    return SettingsState(
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      selectedThemeIndex: selectedThemeIndex ?? this.selectedThemeIndex,
    );
  }

  @override
  List<Object?> get props =>
      [musicVolume, sfxVolume, vibrationEnabled, selectedThemeIndex];
}

// ---------------------------------------------------------------------------
// Cubit
// ---------------------------------------------------------------------------

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._settingsRepo)
      : super(const SettingsState(
          musicVolume: 0.8,
          sfxVolume: 0.8,
          vibrationEnabled: true,
          selectedThemeIndex: 0,
        ));

  final SettingsRepository _settingsRepo;

  void loadSettings() {
    final s = _settingsRepo.getSettings();
    emit(SettingsState(
      musicVolume: s.musicVolume,
      sfxVolume: s.sfxVolume,
      vibrationEnabled: s.vibrationEnabled,
      selectedThemeIndex: s.selectedThemeIndex,
    ));
  }

  void updateMusicVolume(double v) {
    _settingsRepo.musicVolume = v;
    emit(state.copyWith(musicVolume: v));
    AudioService.setMusicVolume(v);
  }

  void updateSfxVolume(double v) {
    _settingsRepo.sfxVolume = v;
    emit(state.copyWith(sfxVolume: v));
    AudioService.setSfxVolume(v);
  }

  void toggleVibration() {
    final newVal = !state.vibrationEnabled;
    _settingsRepo.vibrationEnabled = newVal;
    emit(state.copyWith(vibrationEnabled: newVal));
  }

  void selectTheme(int index) {
    _settingsRepo.selectedThemeIndex = index;
    emit(state.copyWith(selectedThemeIndex: index));
  }
}
