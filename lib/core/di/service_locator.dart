import 'package:get_it/get_it.dart';
import '../../main.dart'; // for objectBoxStore
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/game_session_repository.dart';
import '../../data/repositories/game_results_repository.dart';
import '../../data/repositories/daily_history_repository.dart';
import '../../data/repositories/session_goal_repository.dart';
import '../../data/repositories/collection_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/theme_cubit.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator(SharedPreferences preferences) {
  sl.registerLazySingleton(
      () => ProgressRepository(objectBoxStore.progressBox));
  sl.registerLazySingleton(() => RewardRepository(objectBoxStore.rewardBox));
  sl.registerLazySingleton(
    () => DailyChallengeRepository(objectBoxStore.dailyChallengeBox),
  );
  sl.registerLazySingleton(
      () => SettingsRepository(objectBoxStore.settingsBox));
  sl.registerLazySingleton(() => GameSessionRepository(preferences));
  sl.registerLazySingleton(
    () => GameResultsRepository(
      objectBoxStore.levelResultBox,
      objectBoxStore.puzzleResultBox,
    ),
  );
  sl.registerLazySingleton(
    () => DailyHistoryRepository(objectBoxStore.dailyHistoryBox),
  );
  sl.registerLazySingleton(
    () => SessionGoalRepository(objectBoxStore.sessionGoalBox),
  );
  sl.registerLazySingleton(
    () => CollectionRepository(objectBoxStore.collectionBox),
  );
  sl.registerLazySingleton(() => ThemeCubit(sl<SettingsRepository>()));
}
