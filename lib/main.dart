import 'package:flutter/material.dart';
import 'app.dart';
import 'data/objectbox/objectbox.dart';
import 'services/app_services_bootstrap.dart';
import 'core/di/service_locator.dart';
import 'data/repositories/reward_repository.dart';
import 'data/repositories/session_goal_repository.dart';
import 'services/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

late ObjectBoxStore objectBoxStore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBoxStore = await ObjectBoxStore.create();
  final preferences = await SharedPreferences.getInstance();
  setupServiceLocator(preferences);

  // Check streak on every launch — resets if a day was missed
  sl<RewardRepository>().checkAndUpdateStreak();
  sl<SessionGoalRepository>().ensureActive();
  runApp(const BloomkuApp());

  startAppServicesAfterFirstFrame(
    sl<AppServicesBootstrap>(),
    initializeOptionalServices: () =>
        sl<ReminderService>().rescheduleIfEnabled(),
  );
}
