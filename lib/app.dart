import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/theme_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_model.dart';
import 'core/di/service_locator.dart';
import 'services/audio_service.dart';

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
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(
              child: Text('Bloomku loading...'),
            ),
          ),
        ),
      ],
    );

    return BlocProvider<ThemeCubit>(
      create: (_) => sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, AppThemeData>(
        builder: (context, themeData) {
          return MaterialApp.router(
            title: 'Bloomku',
            theme: bloomkuFlutterTheme(themeData),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
