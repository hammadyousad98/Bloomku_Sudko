import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/features/main_menu/main_menu_cubit.dart';
import 'package:zendoku/features/main_menu/main_menu_screen.dart';

void main() {
  const state = MainMenuState(
    hints: 5,
    extraLives: 5,
    undos: 5,
    bulbs: 5,
    autoMarks: 3,
    cosmeticCurrency: 250,
    streakDay: 7,
    canClaimToday: true,
    campaignLevel: 14,
    chapterName: 'Blossom Garden',
    gridSize: 7,
    collectibleCount: 6,
    collectibleTarget: 10,
    nextMilestone: 'Lavender',
    chapterStars: 31,
    dailyReady: true,
    streakFreezeUsed: false,
    sessionGoalTitle: 'Finish without a mistake',
    sessionGoalProgress: 0,
    sessionGoalTarget: 1,
    sessionGoalCompleted: false,
    sessionGoalReward: '+20 cosmetic petals',
  );

  testWidgets('sprite main menu exposes live values and every primary action',
      (tester) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ZendukoMainMenuCanvas(state: state)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    for (final semanticsLabel in [
      'Settings',
      'Extra lives: 5',
      'AutoMarks: 3',
      'Daily streak, day 7',
      'Continue level 14, Blossom Garden',
      '6 of 10 flowers restored',
      'CHAPTERS',
      'DAILY',
      'COLLECTION',
    ]) {
      expect(
        find.bySemanticsLabel(semanticsLabel),
        findsOneWidget,
        reason: 'Missing $semanticsLabel',
      );
    }
    expect(find.text('READY'), findsWidgets);
    expect(find.bySemanticsLabel('Petals: 250'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
