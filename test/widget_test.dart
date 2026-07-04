import 'package:flutter_test/flutter_test.dart';
import 'package:bloomku/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BloomkuApp());

    // Verify that our app loads.
    expect(find.text('Bloomku loading...'), findsOneWidget);
  });
}
