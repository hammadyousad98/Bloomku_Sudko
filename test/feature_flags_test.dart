import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zendoku/core/config/feature_flags.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('rollout stages enable features cumulatively in the required order', () {
    final stageTwo =
        FeatureFlags.forStage(RolloutStage.gameplayPowersAndZoom);
    expect(stageTwo.dataMigrationAndResults, isTrue);
    expect(stageTwo.lockedFlowerAutoMarkIconsAndZoom, isTrue);
    expect(stageTwo.nonBlockingStartupAndTutorial, isFalse);
    expect(stageTwo.sessionGoalsAndEconomyBalancing, isFalse);
    expect(stageTwo.campaignMaxLevel, 50);

    final complete = FeatureFlags.allEnabled;
    expect(complete.chaptersAndWinExperience, isTrue);
    expect(complete.dailyCalendarFreezesNotificationsAndSharing, isTrue);
    expect(complete.sessionGoalsAndEconomyBalancing, isTrue);
    expect(complete.campaignMaxLevel, 80);
  });

  test('rollout stage can be remotely persisted and defaults to enabled',
      () async {
    SharedPreferences.setMockInitialValues({FeatureFlags.preferencesKey: 4});
    var preferences = await SharedPreferences.getInstance();
    final stageFour = FeatureFlags.fromPreferences(preferences);
    expect(stageFour.chaptersAndWinExperience, isTrue);
    expect(stageFour.dailyCalendarFreezesNotificationsAndSharing, isFalse);

    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    expect(
      FeatureFlags.fromPreferences(preferences)
          .sessionGoalsAndEconomyBalancing,
      isTrue,
    );
  });
}
