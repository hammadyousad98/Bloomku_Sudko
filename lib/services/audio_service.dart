import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/repositories/settings_repository.dart';

class AudioService {
  static final AudioPlayer _musicPlayer = AudioPlayer();

  // Round-robin SFX pool — prevents rapid successive sounds from cutting
  // each other off on the same AudioPlayer instance.
  static const int _sfxPoolSize = 3;
  static final List<AudioPlayer> _sfxPool =
      List.generate(_sfxPoolSize, (_) => AudioPlayer());
  static int _sfxPoolIndex = 0;

  static List<String> _currentMenuPlaylist = [];
  static int _currentMenuTrackIndex = 0;
  static StreamSubscription<void>? _menuMusicCompleteSub;
  static final Map<int, List<String>> _menuPlaylistsCache = {};

  static double _musicVolume = 0.8;
  static double _sfxVolume = 0.8;

  static Future<void> initialize(SettingsRepository settings) async {
    final s = settings.getSettings();
    _musicVolume = s.musicVolume;
    _sfxVolume = s.sfxVolume;

    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  static Future<List<String>> _getTracksForTheme(int themeIndex) async {
    if (_menuPlaylistsCache.containsKey(themeIndex)) {
      return _menuPlaylistsCache[themeIndex]!;
    }

    final themeNames = ['Blossom', 'Ocean', 'Forest', 'Cosmos', 'Peach'];
    if (themeIndex < 0 || themeIndex >= themeNames.length) return [];

    final themeName = themeNames[themeIndex];
    final prefix = 'assets/audio/music/$themeName/';

    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final tracks =
          manifest.listAssets().where((key) => key.startsWith(prefix)).toList();
      tracks.sort(); // Sort alphabetically for sequential playback

      _menuPlaylistsCache[themeIndex] = tracks;
      return tracks;
    } catch (_) {
      return [];
    }
  }

  static Future<void> playMenuMusic(int themeIndex) async {
    await _menuMusicCompleteSub?.cancel();
    _menuMusicCompleteSub = null;

    _currentMenuPlaylist = await _getTracksForTheme(themeIndex);
    if (_currentMenuPlaylist.isEmpty) return;

    _currentMenuTrackIndex = Random().nextInt(_currentMenuPlaylist.length);

    await _musicPlayer.setReleaseMode(ReleaseMode.stop);
    await _playCurrentMenuTrack();

    _menuMusicCompleteSub = _musicPlayer.onPlayerComplete.listen((_) {
      _currentMenuTrackIndex =
          (_currentMenuTrackIndex + 1) % _currentMenuPlaylist.length;
      _playCurrentMenuTrack();
    });
  }

  static Future<void> _playCurrentMenuTrack() async {
    if (_musicVolume <= 0) return;
    await _musicPlayer.setVolume(_musicVolume);

    final fullPath = _currentMenuPlaylist[_currentMenuTrackIndex];
    final assetPath =
        fullPath.startsWith('assets/') ? fullPath.substring(7) : fullPath;
    await _musicPlayer.play(AssetSource(assetPath));
  }

  static Future<void> stopMusic() async {
    await _menuMusicCompleteSub?.cancel();
    _menuMusicCompleteSub = null;
    await _musicPlayer.stop();
  }

  static Future<void> _playSfx(String path) async {
    if (_sfxVolume <= 0) return;
    // Advance to next player in the pool
    _sfxPoolIndex = (_sfxPoolIndex + 1) % _sfxPoolSize;
    final player = _sfxPool[_sfxPoolIndex];
    await player.setVolume(_sfxVolume);
    await player.play(AssetSource(path));
  }

  static Future<void> playPlaceObject() =>
      _playSfx('audio/sfx/place_object.mp3');
  static Future<void> playPlaceMarker() =>
      _playSfx('audio/sfx/place_marker.mp3');
  static Future<void> playError() => _playSfx('audio/sfx/error.mp3');

  /// Plays a mine-detonation sound effect.
  /// Falls back to two rapid error sounds until a dedicated explosion asset
  /// (e.g. 'audio/sfx/mine_explosion.mp3') is added to the project.
  static Future<void> playMineExplosion() async {
    await playError();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await playError();
  }

  static Future<void> playWin() => _playSfx('audio/sfx/win.mp3');
  static Future<void> playLose() => _playSfx('audio/sfx/lose.mp3');
  static Future<void> playHint() => _playSfx('audio/sfx/hint.mp3');
  static Future<void> playUndo() => _playSfx('audio/sfx/undo.mp3');
  static Future<void> playRewardClaim() =>
      _playSfx('audio/sfx/reward_claim.mp3');

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
    for (final p in _sfxPool) {
      p.setVolume(v);
    }
  }

  static Future<void> dispose() async {
    await _menuMusicCompleteSub?.cancel();
    await _musicPlayer.dispose();
    for (final p in _sfxPool) {
      await p.dispose();
    }
  }
}
