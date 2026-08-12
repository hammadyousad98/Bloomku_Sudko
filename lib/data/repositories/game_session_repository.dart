import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/puzzle_generator.dart';

class SavedGameSession {
  const SavedGameSession({
    required this.levelNumber,
    required this.tileStates,
    required this.placedCount,
    required this.moveHistory,
    required this.livesRemaining,
    required this.elapsedSeconds,
    required this.mistakeCount,
    this.autoMarksUsed = 0,
    this.autoMarkHistory = const [],
    this.actionHistory = const [],
  });

  final int levelNumber;
  final List<TileState> tileStates;
  final int placedCount;
  final List<int> moveHistory;
  final int livesRemaining;
  final int elapsedSeconds;
  final int mistakeCount;
  final int autoMarksUsed;
  final List<List<int>> autoMarkHistory;
  final List<String> actionHistory;

  Map<String, Object> toJson() => {
        'levelNumber': levelNumber,
        'tileStates': tileStates.map((state) => state.name).toList(),
        'placedCount': placedCount,
        'moveHistory': moveHistory,
        'livesRemaining': livesRemaining,
        'elapsedSeconds': elapsedSeconds,
        'mistakeCount': mistakeCount,
        'autoMarksUsed': autoMarksUsed,
        'autoMarkHistory': autoMarkHistory,
        'actionHistory': actionHistory,
      };

  static SavedGameSession? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;

    try {
      final tileNames = value['tileStates'] as List<dynamic>;
      return SavedGameSession(
        levelNumber: value['levelNumber'] as int,
        tileStates: tileNames
            .map((name) => TileState.values.byName(name as String))
            .toList(),
        placedCount: value['placedCount'] as int,
        moveHistory: (value['moveHistory'] as List<dynamic>).cast<int>(),
        livesRemaining: value['livesRemaining'] as int,
        elapsedSeconds: value['elapsedSeconds'] as int,
        mistakeCount: value['mistakeCount'] as int? ?? 0,
        autoMarksUsed: value['autoMarksUsed'] as int? ?? 0,
        autoMarkHistory:
            (value['autoMarkHistory'] as List<dynamic>? ?? const [])
                .map((batch) => (batch as List<dynamic>).cast<int>())
                .toList(),
        actionHistory: (value['actionHistory'] as List<dynamic>? ?? const [])
            .cast<String>(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Persists resumable campaign games independently from the app process.
class GameSessionRepository {
  GameSessionRepository(this._preferences);

  final SharedPreferences _preferences;

  static const _lastTrackKey = 'game.lastTrack';

  String _sessionKey(PuzzleTrack track) => 'game.session.${track.name}';

  SavedGameSession? load(PuzzleTrack track) {
    final encoded = _preferences.getString(_sessionKey(track));
    if (encoded == null) return null;
    try {
      return SavedGameSession.fromJson(jsonDecode(encoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(PuzzleTrack track, SavedGameSession session) =>
      _preferences.setString(_sessionKey(track), jsonEncode(session.toJson()));

  Future<void> clear(PuzzleTrack track) =>
      _preferences.remove(_sessionKey(track));

  PuzzleTrack get lastTrack {
    final name = _preferences.getString(_lastTrackKey);
    return PuzzleTrack.values
            .where((track) => track.name == name)
            .firstOrNull ??
        PuzzleTrack.normal;
  }

  Future<void> setLastTrack(PuzzleTrack track) =>
      _preferences.setString(_lastTrackKey, track.name);
}
