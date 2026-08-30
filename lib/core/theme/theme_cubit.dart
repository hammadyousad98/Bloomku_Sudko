import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart';
import 'theme_model.dart';
import '../../data/repositories/progress_repository.dart';
import '../constants/app_constants.dart';

class ThemeCubit extends Cubit<AppThemeData> {
  ThemeCubit(this._settingsRepo, this._progressRepo)
      : super(BloomkuThemes.blossom) {
    _loadSaved();
  }

  /// Fixed theme controller for isolated component previews and widget tests.
  ThemeCubit.preview(super.initialState)
      : _settingsRepo = null,
        _progressRepo = null;

  final SettingsRepository? _settingsRepo;
  final ProgressRepository? _progressRepo;

  void _loadSaved() {
    final savedIndex = _settingsRepo!.selectedThemeIndex;
    final index = isThemeUnlocked(savedIndex) ? savedIndex : 0;
    if (index != savedIndex) _settingsRepo.selectedThemeIndex = index;
    emit(BloomkuThemes.byIndex(index));
  }

  bool isThemeUnlocked(int index) =>
      index >= 0 &&
      index < campaignChapters.length &&
      _progressRepo!.isThemeUnlocked(campaignChapters[index].themeId);

  /// Switches to the theme at the given index and persists the choice.
  bool selectTheme(int index) {
    if (_settingsRepo == null || _progressRepo == null) return false;
    if (!isThemeUnlocked(index)) return false;
    _settingsRepo.selectedThemeIndex = index;
    emit(BloomkuThemes.byIndex(index));

    if (!AdService.isInGame) {
      AudioService.playMenuMusic(index);
    }
    return true;
  }
}
