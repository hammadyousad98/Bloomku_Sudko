import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zendoku/features/game/widgets/bottom_buttons.dart';

void main() {
  testWidgets('all custom power SVG assets render with tinting',
      (tester) async {
    const assets = [
      'assets/icons/powers/hint.svg',
      'assets/icons/powers/undo.svg',
      'assets/icons/powers/solve_row.svg',
      'assets/icons/powers/auto_mark.svg',
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              for (final asset in assets)
                PowerButtonIcon(assetPath: asset, color: Colors.teal),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(PowerButtonIcon), findsNWidgets(4));
  });
}
