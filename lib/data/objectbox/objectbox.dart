import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/player_progress.dart';
import '../models/daily_reward_state.dart';
import '../models/daily_challenge_state.dart';
import '../models/settings_model.dart';
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
}
