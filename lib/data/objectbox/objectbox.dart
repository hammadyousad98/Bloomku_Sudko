import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/player_progress.dart';
import '../models/daily_reward_state.dart';
import '../models/daily_challenge_state.dart';
import '../models/settings_model.dart';
import '../models/level_result.dart';
import '../models/daily_challenge_history.dart';
import '../models/session_goal_state.dart';
import '../models/collection_progress.dart';
import 'objectbox.g.dart';

/// Singleton wrapper around the ObjectBox Store.
class ObjectBoxStore {
  late final Store store;

  ObjectBoxStore._create(this.store);

  /// Opens or creates the ObjectBox store. Call once in main().
  static Future<ObjectBoxStore> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, 'objectbox'));
    return ObjectBoxStore._create(store);
  }

  Box<PlayerProgress> get progressBox => store.box<PlayerProgress>();
  Box<DailyRewardState> get rewardBox => store.box<DailyRewardState>();
  Box<DailyChallengeState> get dailyChallengeBox =>
      store.box<DailyChallengeState>();
  Box<SettingsModel> get settingsBox => store.box<SettingsModel>();
  Box<LevelResult> get levelResultBox => store.box<LevelResult>();
  Box<PuzzleResult> get puzzleResultBox => store.box<PuzzleResult>();
  Box<DailyChallengeHistory> get dailyHistoryBox =>
      store.box<DailyChallengeHistory>();
  Box<SessionGoalState> get sessionGoalBox => store.box<SessionGoalState>();
  Box<CollectionProgress> get collectionBox => store.box<CollectionProgress>();
}
