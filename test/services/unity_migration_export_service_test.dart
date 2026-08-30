import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/core/utils/puzzle_generator.dart';
import 'package:zendoku/data/models/collection_progress.dart';
import 'package:zendoku/data/models/daily_challenge_history.dart';
import 'package:zendoku/data/models/level_result.dart';
import 'package:zendoku/data/models/player_progress.dart';
import 'package:zendoku/data/models/settings_model.dart';
import 'package:zendoku/services/unity_migration_export_service.dart';

void main() {
  test('maps ObjectBox data to the Unity schema without losing inventory', () {
    final progress = PlayerProgress()
      ..normalHighest = 34
      ..hardHighest = 20
      ..ultraHighest = 31
      ..hints = 8
      ..bulbs = 4
      ..undos = 7
      ..extraLives = 3
      ..autoMarks = 11
      ..streakFreezes = 2
      ..adsRemoved = true
      ..tutorialBoardsCompleted = 2
      ..tutorialRewardClaimsMask = 3
      ..unlockedThemeIdsJson = '["theme_blossom_garden","theme_ocean_cove"]';
    final settings = SettingsModel()
      ..musicVolume = 0.5
      ..sfxVolume = 0.7
      ..selectedThemeIndex = 1
      ..vibrationEnabled = false;
    final level = LevelResult()
      ..levelNumber = 14
      ..track = 'hard'
      ..bestTimeMs = 42000
      ..highestStars = 3
      ..completionCount = 2;
    final daily = DailyChallengeHistory()
      ..dateKey = '2026-08-15'
      ..completed = true
      ..bestTimeMs = 31000
      ..streakAtCompletion = 7;
    final collection = CollectionProgress()
      ..chapterId = 'blossom_garden'
      ..collectedObjectIdsJson = '["rose","tulip"]'
      ..targetCount = 10;

    final payload = UnityMigrationMapper.build(
      migrationId: 'fixture-1',
      progress: progress,
      settings: settings,
      levels: [level],
      dailyHistory: [daily],
      collections: [collection],
      activeTrack: PuzzleTrack.normal,
      activeSession: null,
    );

    final unityProgress = payload['Progress']! as Map<String, Object?>;
    expect(payload['MigrationId'], 'fixture-1');
    expect(unityProgress['NormalHighest'], 34);
    expect(unityProgress['Hints'], 8);
    expect(unityProgress['SolveRows'], 4);
    expect(unityProgress['ExtraLives'], 3);
    expect(unityProgress['AutoMarks'], 11);
    expect(unityProgress['AdsRemoved'], isTrue);
    expect(unityProgress['Tutorial'], {
      'BoardsCompleted': [true, true, false],
      'RewardsClaimed': [true, true, false],
    });
    expect((unityProgress['Levels']! as List).first['Difficulty'], 1);
    expect((unityProgress['DailyHistory']! as List).first['BestSeconds'], 31.0);
    expect((unityProgress['Collections']! as List).first['CollectedIds'], ['rose', 'tulip']);

    final unitySettings = payload['Settings']! as Map<String, Object?>;
    expect(unitySettings['SelectedThemeId'], 'theme_ocean_cove');
    expect(unitySettings['HapticsEnabled'], isFalse);
  });
}
