import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart';
import 'theme_model.dart';

class ThemeCubit extends Cubit<AppThemeData> {
  ThemeCubit(this._settingsRepo) : super(BloomkuThemes.blossom) {
    _loadSaved();
  }

  final SettingsRepository _settingsRepo;

  void _loadSaved() {
    final index = _settingsRepo.selectedThemeIndex;
    emit(BloomkuThemes.byIndex(index));
  }

  /// Switches to the theme at the given index and persists the choice.
  void selectTheme(int index) {
    _settingsRepo.selectedThemeIndex = index;
    emit(BloomkuThemes.byIndex(index));
    
    if (!AdService.isInGame) {
      AudioService.playMenuMusic(index);
    }
  }
}
