import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zendoku/core/analytics/onboarding_analytics.dart';
import 'package:zendoku/features/splash/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('mandatory splash target is four seconds', () {
    expect(mandatorySplashDuration, const Duration(seconds: 4));
  });

  test('onboarding analytics retain timestamps and repeated actions', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final analytics = OnboardingAnalytics(preferences);

    analytics.recordOnce('splash_started');
    analytics
        .record('tutorial_action', metadata: {'board': 1, 'action': 'tap'});
    analytics
        .record('tutorial_action', metadata: {'board': 1, 'action': 'tap'});
    analytics.record('tutorial_board_completed', metadata: {'board': 1});
    analytics.recordOnce('first_real_win', metadata: {'level': 1});
    analytics.recordOnce('first_real_win', metadata: {'level': 1});

    final events = analytics.events;
    expect(events.where((event) => event['event'] == 'tutorial_action'),
        hasLength(2));
    expect(events.where((event) => event['event'] == 'first_real_win'),
        hasLength(1));
    expect(
      events.every(
          (event) => event['timestampMs'] is int && event['elapsedMs'] is int),
      isTrue,
    );
  });
}
