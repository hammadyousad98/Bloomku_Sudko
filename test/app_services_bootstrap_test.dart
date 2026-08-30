import 'dart:async';

import 'package:zendoku/services/app_services_bootstrap.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts ads, purchases, and audio concurrently', () async {
    final preferences = await SharedPreferences.getInstance();
    final ads = Completer<bool>();
    final purchases = Completer<bool>();
    final audio = Completer<bool>();
    final started = <AppServiceKind>[];
    final bootstrap = AppServicesBootstrap(
      preferences: preferences,
      initializeAds: () {
        started.add(AppServiceKind.ads);
        return ads.future;
      },
      initializePurchases: () {
        started.add(AppServiceKind.purchases);
        return purchases.future;
      },
      initializeAudio: () {
        started.add(AppServiceKind.audio);
        return audio.future;
      },
    );

    final startup = bootstrap.start();
    expect(started, AppServiceKind.values);
    expect(bootstrap.ads.isLoading, isTrue);
    expect(bootstrap.purchases.isLoading, isTrue);
    expect(bootstrap.audio.isLoading, isTrue);

    ads.complete(true);
    purchases.complete(true);
    audio.complete(true);
    await startup;

    expect(bootstrap.ads.isReady, isTrue);
    expect(bootstrap.purchases.isReady, isTrue);
    expect(bootstrap.audio.isReady, isTrue);
  });

  test('isolates and records failures without blocking other services',
      () async {
    final preferences = await SharedPreferences.getInstance();
    final bootstrap = AppServicesBootstrap(
      preferences: preferences,
      initializeAds: () async => throw StateError('ads failed'),
      initializePurchases: () async => false,
      initializeAudio: () async => true,
    );

    await bootstrap.start();

    expect(bootstrap.ads.isUnavailable, isTrue);
    expect(bootstrap.purchases.isUnavailable, isTrue);
    expect(bootstrap.audio.isReady, isTrue);
    expect(bootstrap.failures, hasLength(2));
    expect(
      preferences.getStringList('app_services_initialization_failures'),
      hasLength(2),
    );
  });

  test('start is idempotent', () async {
    final preferences = await SharedPreferences.getInstance();
    var calls = 0;
    Future<bool> initialize() async {
      calls++;
      return true;
    }

    final bootstrap = AppServicesBootstrap(
      preferences: preferences,
      initializeAds: initialize,
      initializePurchases: initialize,
      initializeAudio: initialize,
    );

    await Future.wait([bootstrap.start(), bootstrap.start()]);

    expect(calls, 3);
  });

  testWidgets('initializers do not run until after the first rendered frame',
      (tester) async {
    final preferences = await SharedPreferences.getInstance();
    var calls = 0;
    final bootstrap = AppServicesBootstrap(
      preferences: preferences,
      initializeAds: () async {
        calls++;
        return false;
      },
      initializePurchases: () async {
        calls++;
        return false;
      },
      initializeAudio: () async {
        calls++;
        return true;
      },
    );

    startAppServicesAfterFirstFrame(bootstrap);
    expect(calls, 0);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(calls, 3);
    expect(bootstrap.ads.isUnavailable, isTrue);
    expect(bootstrap.audio.isReady, isTrue);
  });
}
