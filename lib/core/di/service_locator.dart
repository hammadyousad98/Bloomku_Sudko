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
import '../analytics/onboarding_analytics.dart';
import '../../services/ad_service.dart';
import '../../services/app_services_bootstrap.dart';
import '../../services/audio_service.dart';
import '../../services/iap_service.dart';
import '../../services/reminder_service.dart';
import '../../services/unity_migration_export_service.dart';
import '../config/feature_flags.dart';

final GetIt sl = GetIt.instance;

void setupServiceLocator(SharedPreferences preferences) {
  FeatureFlags.configure(FeatureFlags.fromPreferences(preferences));
  sl.registerSingleton<FeatureFlags>(FeatureFlags.current);
  sl.registerLazySingleton(() => ReminderService(preferences));
  sl.registerLazySingleton(() => OnboardingAnalytics(preferences));
  sl.registerLazySingleton(
      () => ProgressRepository(objectBoxStore.progressBox));
  sl.registerLazySingleton(
    () => RewardRepository(
      objectBoxStore.rewardBox,
      sl<ProgressRepository>(),
    ),
  );
  sl.registerLazySingleton(
    () => DailyChallengeRepository(
      objectBoxStore.dailyChallengeBox,
      sl<DailyHistoryRepository>(),
      sl<ProgressRepository>(),
    ),
  );
  sl.registerLazySingleton(
      () => SettingsRepository(objectBoxStore.settingsBox));
  sl.registerLazySingleton(() => GameSessionRepository(preferences));
  sl.registerLazySingleton(
    () => UnityMigrationExportService(
      objectBoxStore,
      sl<GameSessionRepository>(),
    ),
  );
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
  sl.registerLazySingleton(
    () => ThemeCubit(sl<SettingsRepository>(), sl<ProgressRepository>()),
  );
  sl.registerLazySingleton(
    () => AppServicesBootstrap(
      preferences: preferences,
      initializeAds: () async {
        final adsRemoved = sl<ProgressRepository>().getProgress().adsRemoved;
        await AdService.initialize(adsRemoved: adsRemoved);
        return true;
      },
      initializePurchases: () async {
        IapService.listenToPurchaseUpdates(sl<ProgressRepository>());
        return IapService.initialize();
      },
      initializeAudio: () async {
        await AudioService.initialize(sl<SettingsRepository>());
        return true;
      },
    ),
  );
}
