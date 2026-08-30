import 'package:shared_preferences/shared_preferences.dart';

/// Ordered production rollout stages. A stage always includes every earlier
/// stage so partially enabled builds cannot expose UI before its data exists.
enum RolloutStage {
  dataMigrationAndResults(1),
  gameplayPowersAndZoom(2),
  startupAndTutorial(3),
  chaptersAndWinExperience(4),
  dailyRetention(5),
  sessionGoals(6);

  const RolloutStage(this.number);
  final int number;
}

class FeatureFlags {
  const FeatureFlags._(this.stage);

  static const preferencesKey = 'feature_rollout_stage';
  static const allEnabled = FeatureFlags._(RolloutStage.sessionGoals);

  static FeatureFlags current = allEnabled;

  final RolloutStage stage;

  factory FeatureFlags.forStage(RolloutStage stage) => FeatureFlags._(stage);

  factory FeatureFlags.fromPreferences(SharedPreferences preferences) {
    final requested = preferences.getInt(preferencesKey);
    final stage = RolloutStage.values.lastWhere(
      (candidate) => candidate.number <= (requested ?? 6),
      orElse: () => RolloutStage.dataMigrationAndResults,
    );
    return FeatureFlags._(stage);
  }

  static void configure(FeatureFlags flags) => current = flags;

  bool includes(RolloutStage required) => stage.number >= required.number;

  bool get dataMigrationAndResults =>
      includes(RolloutStage.dataMigrationAndResults);
  bool get lockedFlowerAutoMarkIconsAndZoom =>
      includes(RolloutStage.gameplayPowersAndZoom);
  bool get nonBlockingStartupAndTutorial =>
      includes(RolloutStage.startupAndTutorial);
  bool get chaptersAndWinExperience =>
      includes(RolloutStage.chaptersAndWinExperience);
  bool get dailyCalendarFreezesNotificationsAndSharing =>
      includes(RolloutStage.dailyRetention);
  bool get sessionGoalsAndEconomyBalancing =>
      includes(RolloutStage.sessionGoals);

  int get campaignMaxLevel => chaptersAndWinExperience ? 80 : 50;
}
