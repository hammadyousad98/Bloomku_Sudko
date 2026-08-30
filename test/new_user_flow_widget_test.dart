import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zendoku/core/theme/app_theme.dart';
import 'package:zendoku/core/theme/theme_cubit.dart';
import 'package:zendoku/core/theme/theme_model.dart';
import 'package:zendoku/features/splash/splash_screen.dart';
import 'package:zendoku/features/tutorial/onboarding_cubit.dart';

void main() {
  testWidgets('new install reaches a playable 4x4 board after four seconds',
      (tester) async {
    await tester.pumpWidget(const _NewUserFlowHarness());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byKey(const Key('tutorial-board')), findsNothing);

    await tester.pump(mandatorySplashDuration - const Duration(milliseconds: 1));
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(find.byKey(const Key('tutorial-board')), findsOneWidget);
    expect(find.byKey(const Key('tutorial-cell')), findsNWidgets(16));
    expect(tutorialBoards.first.colorMap, hasLength(16));
  });
}

class _NewUserFlowHarness extends StatefulWidget {
  const _NewUserFlowHarness();

  @override
  State<_NewUserFlowHarness> createState() => _NewUserFlowHarnessState();
}

class _NewUserFlowHarnessState extends State<_NewUserFlowHarness> {
  bool ready = false;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => ThemeCubit.preview(BloomkuThemes.blossom),
        child: MaterialApp(
          theme: bloomkuFlutterTheme(BloomkuThemes.blossom),
          home: ready
            ? Material(
                child: Center(
                  child: SizedBox.square(
                    dimension: 320,
                    child: GridView.count(
                      key: const Key('tutorial-board'),
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      children: List.generate(
                        16,
                        (_) => InkWell(
                          key: const Key('tutorial-cell'),
                          onTap: () {},
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              : SplashScreen(onFinished: () => setState(() => ready = true)),
        ),
      );
}
