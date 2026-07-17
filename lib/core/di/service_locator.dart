import 'package:get_it/get_it.dart';
import '../../main.dart'; // for objectBoxStore
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../theme/theme_cubit.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator() {
  sl.registerLazySingleton(
      () => ProgressRepository(objectBoxStore.progressBox));
  sl.registerLazySingleton(() => RewardRepository(objectBoxStore.rewardBox));
  sl.registerLazySingleton(
    () => DailyChallengeRepository(objectBoxStore.dailyChallengeBox),
  );
  sl.registerLazySingleton(
      () => SettingsRepository(objectBoxStore.settingsBox));
  sl.registerLazySingleton(() => ThemeCubit(sl<SettingsRepository>()));
}
