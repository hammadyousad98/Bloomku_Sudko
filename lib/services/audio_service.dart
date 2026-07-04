import 'package:audioplayers/audioplayers.dart';
import '../data/repositories/settings_repository.dart';

class AudioService {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static final AudioPlayer _sfxPlayer   = AudioPlayer();

  static double _musicVolume = 0.8;
  static double _sfxVolume   = 0.8;

  static Future<void> initialize(SettingsRepository settings) async {
    final s = settings.getSettings();
    _musicVolume = s.musicVolume;
    _sfxVolume   = s.sfxVolume;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  static Future<void> playMenuMusic() async {
    if (_musicVolume <= 0) {
      await stopMusic();
      return;
    }
    await _musicPlayer.setVolume(_musicVolume);
    await _musicPlayer.play(AssetSource('audio/music/menu_music.mp3'));
  }

  static Future<void> playGameMusic() async {
    if (_musicVolume <= 0) {
      await stopMusic();
      return;
    }
    await _musicPlayer.setVolume(_musicVolume);
    await _musicPlayer.play(AssetSource('audio/music/game_music.mp3'));
  }

  static Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  static Future<void> _playSfx(String path) async {
    if (_sfxVolume <= 0) return;
    await _sfxPlayer.setVolume(_sfxVolume);
    await _sfxPlayer.play(AssetSource(path));
  }

  static Future<void> playPlaceObject() => _playSfx('audio/sfx/place_object.mp3');
  static Future<void> playPlaceMarker() => _playSfx('audio/sfx/place_marker.mp3');
  static Future<void> playError()       => _playSfx('audio/sfx/error.mp3');
  static Future<void> playWin()         => _playSfx('audio/sfx/win.mp3');
  static Future<void> playLose()        => _playSfx('audio/sfx/lose.mp3');
  static Future<void> playHint()        => _playSfx('audio/sfx/hint.mp3');
  static Future<void> playUndo()        => _playSfx('audio/sfx/undo.mp3');
  static Future<void> playRewardClaim() => _playSfx('audio/sfx/reward_claim.mp3');

  static void setMusicVolume(double v) {
    _musicVolume = v;
    if (v <= 0) {
      _musicPlayer.stop();
    } else {
      _musicPlayer.setVolume(v);
    }
  }

  static void setSfxVolume(double v) {
    _sfxVolume = v;
    _sfxPlayer.setVolume(v);
  }
}
