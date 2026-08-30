import 'dart:convert';
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppServiceKind { ads, purchases, audio }

enum AppServiceStatus { loading, ready, unavailable }

@immutable
class AppServiceState {
  const AppServiceState({
    this.status = AppServiceStatus.loading,
    this.error,
  });

  final AppServiceStatus status;
  final String? error;

  bool get isReady => status == AppServiceStatus.ready;
  bool get isLoading => status == AppServiceStatus.loading;
  bool get isUnavailable => status == AppServiceStatus.unavailable;
}

@immutable
class AppServiceInitializationFailure {
  const AppServiceInitializationFailure({
    required this.service,
    required this.message,
    required this.occurredAt,
  });

  final AppServiceKind service;
  final String message;
  final DateTime occurredAt;

  Map<String, Object> toJson() => {
        'service': service.name,
        'message': message,
        'occurredAt': occurredAt.toIso8601String(),
      };
}

typedef AppServiceInitializer = Future<bool> Function();

/// Starts optional platform services after Flutter has rendered its first frame.
/// A failure in one service never blocks the other services or local gameplay.
class AppServicesBootstrap extends ChangeNotifier {
  AppServicesBootstrap({
    required SharedPreferences preferences,
    required AppServiceInitializer initializeAds,
    required AppServiceInitializer initializePurchases,
    required AppServiceInitializer initializeAudio,
  })  : _preferences = preferences,
        _initializeAds = initializeAds,
        _initializePurchases = initializePurchases,
        _initializeAudio = initializeAudio;

  static const _failureLogKey = 'app_services_initialization_failures';
  static const _maxPersistedFailures = 20;

  final SharedPreferences _preferences;
  final AppServiceInitializer _initializeAds;
  final AppServiceInitializer _initializePurchases;
  final AppServiceInitializer _initializeAudio;
  final Map<AppServiceKind, AppServiceState> _states = {
    for (final service in AppServiceKind.values)
      service: const AppServiceState(),
  };
  final List<AppServiceInitializationFailure> _failures = [];
  Future<void>? _startup;

  AppServiceState stateFor(AppServiceKind service) => _states[service]!;
  AppServiceState get ads => stateFor(AppServiceKind.ads);
  AppServiceState get purchases => stateFor(AppServiceKind.purchases);
  AppServiceState get audio => stateFor(AppServiceKind.audio);
  List<AppServiceInitializationFailure> get failures =>
      List.unmodifiable(_failures);

  /// Idempotently launches every initializer concurrently.
  Future<void> start() => _startup ??= Future.wait<void>([
        _run(AppServiceKind.ads, _initializeAds),
        _run(AppServiceKind.purchases, _initializePurchases),
        _run(AppServiceKind.audio, _initializeAudio),
      ]);

  Future<void> _run(
    AppServiceKind service,
    AppServiceInitializer initializer,
  ) async {
    try {
      final available = await initializer();
      _states[service] = AppServiceState(
        status:
            available ? AppServiceStatus.ready : AppServiceStatus.unavailable,
        error: available ? null : '${service.name} is unavailable',
      );
      if (!available) {
        _recordFailure(service, '${service.name} is unavailable');
      }
    } catch (error, stackTrace) {
      final message = error.toString();
      _states[service] = AppServiceState(
        status: AppServiceStatus.unavailable,
        error: message,
      );
      _recordFailure(service, message);
      debugPrint('Failed to initialize ${service.name}: $error\n$stackTrace');
    } finally {
      notifyListeners();
    }
  }

  void _recordFailure(AppServiceKind service, String message) {
    final failure = AppServiceInitializationFailure(
      service: service,
      message: message,
      occurredAt: DateTime.now(),
    );
    _failures.add(failure);

    final persisted = _preferences.getStringList(_failureLogKey) ?? <String>[];
    persisted.add(jsonEncode(failure.toJson()));
    if (persisted.length > _maxPersistedFailures) {
      persisted.removeRange(0, persisted.length - _maxPersistedFailures);
    }
    _preferences
        .setStringList(_failureLogKey, persisted)
        .catchError((_) => false);
  }
}

/// Defers optional platform services until Flutter has rendered its first
/// frame. Gameplay remains available even when any initializer fails.
void startAppServicesAfterFirstFrame(
  AppServicesBootstrap bootstrap, {
  Future<void> Function()? initializeOptionalServices,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(bootstrap.start());
    if (initializeOptionalServices != null) {
      unawaited(initializeOptionalServices());
    }
  });
}
