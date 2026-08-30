import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_model.dart';
import 'core/di/service_locator.dart';
import 'core/router/app_router.dart';
import 'services/audio_service.dart';
import 'services/ad_service.dart';
import 'services/app_services_bootstrap.dart';
import 'data/repositories/progress_repository.dart';

class BloomkuApp extends StatefulWidget {
  const BloomkuApp({super.key});

  @override
  State<BloomkuApp> createState() => _BloomkuAppState();
}

class _BloomkuAppState extends State<BloomkuApp> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onPause: () => AudioService.stopMusic(),
      onResume: () {
        final location =
            AppRouter.router.routeInformationProvider.value.uri.path;
        final progress = sl<ProgressRepository>().getProgress();
        final mayShowAppOpenAd = location != '/splash' &&
            location != '/tutorial' &&
            progress.tutorialSeen;
        if (!mayShowAppOpenAd || !sl<AppServicesBootstrap>().ads.isReady) {
          return;
        }
        AdService.showAppOpenAdIfAvailable(adsRemoved: progress.adsRemoved);
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    AudioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, AppThemeData>(
        builder: (context, themeData) {
          return MaterialApp.router(
            title: 'Bloomku',
            theme: bloomkuFlutterTheme(themeData),
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
