import 'package:flutter/material.dart';
import 'app.dart';
import 'data/objectbox/objectbox.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';
import 'services/audio_service.dart';
import 'core/di/service_locator.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/reward_repository.dart';
import 'data/repositories/progress_repository.dart';

late ObjectBoxStore objectBoxStore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBoxStore = await ObjectBoxStore.create();
  setupServiceLocator();

  final adsRemoved = sl<ProgressRepository>().getProgress().adsRemoved;
  await AdService.initialize(adsRemoved: adsRemoved);
  await IapService.initialize();
  await AudioService.initialize(sl<SettingsRepository>());
  IapService.listenToPurchaseUpdates(sl<ProgressRepository>());

  // Check streak on every launch — resets if a day was missed
  sl<RewardRepository>().checkAndUpdateStreak();
  runApp(const BloomkuApp());
}
