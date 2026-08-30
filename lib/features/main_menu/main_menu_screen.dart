import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/feature_flags.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/service_locator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_cubit.dart';
import '../../core/theme/theme_model.dart';
import '../../data/models/player_progress.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/game_results_repository.dart';
import '../../data/repositories/game_session_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/session_goal_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../services/ad_service.dart';
import '../../services/app_services_bootstrap.dart';
import '../../services/audio_service.dart';
import '../../widgets/common/themed_icon.dart';
import 'main_menu_cubit.dart';

const _spriteRoot = 'assets/images/sprites/main_menu';
String _sprite(String name) => '$_spriteRoot/$name.png';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late final AppServicesBootstrap _bootstrap;
  bool _musicStarted = false;

  @override
  void initState() {
    super.initState();
    _bootstrap = sl<AppServicesBootstrap>();
    _bootstrap.addListener(_startMusicWhenReady);
    _startMusicWhenReady();
  }

  void _startMusicWhenReady() {
    if (_musicStarted || !_bootstrap.audio.isReady) return;
    _musicStarted = true;
    AudioService.playMenuMusic(sl<SettingsRepository>().selectedThemeIndex);
  }

  @override
  void dispose() {
    _bootstrap.removeListener(_startMusicWhenReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => MainMenuCubit(
          sl<ProgressRepository>(),
          sl<RewardRepository>(),
          sl<CollectionRepository>(),
          sl<GameResultsRepository>(),
          sl<DailyChallengeRepository>(),
          sl<SessionGoalRepository>(),
        ),
        child: const _MainMenuView(),
      );
}

class _MainMenuView extends StatelessWidget {
  const _MainMenuView();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF1C381E),
        body: BlocBuilder<MainMenuCubit, MainMenuState>(
          builder: (context, state) => Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/backgrounds/main_menu_bg_v1.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              SafeArea(
                child: ZendukoMainMenuCanvas(state: state),
              ),
            ],
          ),
        ),
      );
}

class ZendukoMainMenuCanvas extends StatelessWidget {
  const ZendukoMainMenuCanvas({super.key, required this.state});

  final MainMenuState state;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final scaleX = constraints.maxWidth / 1080;
          final scaleY = constraints.maxHeight / 1920;
          Widget position({
            required double left,
            required double top,
            required double width,
            required double height,
            required Widget child,
          }) =>
              _DesignPositioned(
                left: left,
                top: top,
                width: width,
                height: height,
                scaleX: scaleX,
                scaleY: scaleY,
                child: child,
              );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              position(
                left: 48,
                top: 42,
                width: 132,
                height: 132,
                child: _SpriteTap(
                  semanticLabel: 'Settings',
                  onTap: () => _pushAndRefresh(context, '/settings'),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _Sprite('settings_frame')),
                      const Positioned(
                        left: 25,
                        top: 25,
                        width: 82,
                        height: 82,
                        child: _Sprite('gear'),
                      ),
                    ],
                  ),
                ),
              ),
              position(
                left: 600,
                top: 54,
                width: 210,
                height: 108,
                child: _ResourceCounter(
                  icon: 'heart',
                  value: state.extraLives,
                  semanticLabel: 'Extra lives',
                  onTap: () => _showInventoryInfo(
                    context,
                    icon: 'heart',
                    title: 'Extra Lives',
                    description:
                        'Used when you run out of lives during a puzzle. Earn more from rewards and milestones.',
                  ),
                ),
              ),
              position(
                left: 830,
                top: 54,
                width: 232,
                height: 108,
                child: _ResourceCounter(
                  icon: 'auto_mark',
                  value: state.autoMarks,
                  semanticLabel: 'AutoMarks',
                  onTap: () => _showInventoryInfo(
                    context,
                    icon: 'auto_mark',
                    title: 'AutoMark',
                    description:
                        'Marks every empty cell touching a placed flower. Use it from the power bar during a puzzle.',
                  ),
                ),
              ),
              position(
                  left: 130,
                  top: 145,
                  width: 820,
                  height: 390,
                  child: const _ZendukoLogo()),
              position(
                  left: 35,
                  top: 570,
                  width: 760,
                  height: 510,
                  child: const _MascotChase()),
              position(
                left: 852,
                top: 610,
                width: 188,
                height: 250,
                child: _SpriteTap(
                  semanticLabel: 'Daily streak, day ${state.streakDay}',
                  onTap: () => _pushAndRefresh(context, '/rewards'),
                  child: _StreakMedallion(streak: state.streakDay),
                ),
              ),
              position(
                  left: 940,
                  top: 1005,
                  width: 88,
                  height: 82,
                  child: const _Sprite('corner_flower')),
              position(
                left: 130,
                top: 1090,
                width: 820,
                height: 290,
                child: _SpriteTap(
                  semanticLabel:
                      'Continue level ${state.campaignLevel}, ${state.chapterName}',
                  onTap: () => _playCurrentLevel(context),
                  child: _PrimaryAction(state: state),
                ),
              ),
              position(
                left: 80,
                top: 1390,
                width: 920,
                height: 250,
                child: _SpriteTap(
                  semanticLabel:
                      '${state.collectibleCount} of ${state.collectibleTarget} flowers restored',
                  onTap: () => _pushAndRefresh(context, '/chapters'),
                  child: _RestoredFlowers(state: state),
                ),
              ),
              position(
                left: 30,
                top: 1625,
                width: 320,
                height: 280,
                child: _NavigationButton(
                  kind: _NavigationKind.chapters,
                  onTap: () => _pushAndRefresh(context, '/chapters'),
                ),
              ),
              position(
                left: 380,
                top: 1625,
                width: 320,
                height: 280,
                child: _NavigationButton(
                  kind: _NavigationKind.daily,
                  showReady: state.dailyReady,
                  onTap: () => _pushAndRefresh(context, '/challenges'),
                ),
              ),
              position(
                left: 730,
                top: 1625,
                width: 320,
                height: 280,
                child: _NavigationButton(
                  kind: _NavigationKind.collection,
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => const ThemeSelectorSheet(),
                  ),
                ),
              ),
              if (state.streakFreezeUsed)
                position(
                  left: 280,
                  top: 1015,
                  width: 520,
                  height: 64,
                  child: const _GameToast(
                      label: 'Streak freeze saved your streak!'),
                ),
            ],
          );
        },
      );

  void _showInventoryInfo(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InventoryInfoSheet(
        icon: icon,
        title: title,
        description: description,
      ),
    );
  }

  Future<void> _pushAndRefresh(BuildContext context, String route) async {
    if (route == '/chapters' &&
        !FeatureFlags.current.chaptersAndWinExperience) {
      return;
    }
    if (route == '/challenges' &&
        !FeatureFlags.current.dailyCalendarFreezesNotificationsAndSharing) {
      route = '/rewards';
    }
    await context.push(route);
    if (context.mounted) context.read<MainMenuCubit>().loadData();
  }

  Future<void> _playCurrentLevel(BuildContext context) async {
    final progressRepository = sl<ProgressRepository>();
    final progress = progressRepository.getProgress();
    const activeTrack = PuzzleTrack.normal;
    final savedSession = sl<GameSessionRepository>().load(activeTrack);
    final level = savedSession != null &&
            progressRepository.isLevelUnlocked(
              savedSession.levelNumber,
              activeTrack,
            )
        ? savedSession.levelNumber
        : _highestFor(progress, activeTrack);

    if (level > FeatureFlags.current.campaignMaxLevel) {
      await _pushAndRefresh(context, '/chapters');
      return;
    }

    AdService.preloadGameBanners(adsRemoved: progress.adsRemoved);
    await context.push(
      '/game',
      extra: {'level': level, 'track': 'normal'},
    );
    if (context.mounted) context.read<MainMenuCubit>().loadData();
  }

  int _highestFor(PlayerProgress progress, PuzzleTrack track) =>
      switch (track) {
        PuzzleTrack.normal => progress.normalHighest,
        PuzzleTrack.hard => progress.hardHighest,
        PuzzleTrack.ultraHard => progress.ultraHighest,
      };
}

class _DesignPositioned extends StatelessWidget {
  const _DesignPositioned({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.scaleX,
    required this.scaleY,
    required this.child,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final double scaleX;
  final double scaleY;
  final Widget child;

  @override
  Widget build(BuildContext context) => Positioned(
        left: left * scaleX,
        top: top * scaleY,
        width: width * scaleX,
        height: height * scaleX,
        child: FittedBox(
          fit: BoxFit.fill,
          child: SizedBox(width: width, height: height, child: child),
        ),
      );
}

class _ZendukoLogo extends StatelessWidget {
  const _ZendukoLogo();

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: const [
          Positioned(
              left: 22,
              top: 105,
              width: 780,
              height: 270,
              child: _Sprite('logo_plaque')),
          Positioned(
              left: 205,
              top: 32,
              width: 190,
              height: 122,
              child: _Sprite('logo_leaf_left')),
          Positioned(
              left: 505,
              top: 27,
              width: 170,
              height: 126,
              child: _Sprite('logo_leaf_right')),
          Positioned(
              left: 298,
              top: 0,
              width: 230,
              height: 138,
              child: _Sprite('logo_lotus')),
          Positioned(
              left: 88,
              top: 152,
              width: 650,
              height: 156,
              child: _Sprite('logo_wordmark')),
        ],
      );
}

class _ResourceCounter extends StatelessWidget {
  const _ResourceCounter({
    required this.icon,
    required this.value,
    required this.semanticLabel,
    required this.onTap,
  });

  final String icon;
  final int value;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SpriteTap(
        semanticLabel: '$semanticLabel: $value',
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            children: [
              const Positioned.fill(child: _Sprite('hud_pill')),
              Positioned(
                  left: 16,
                  top: 16,
                  width: 76,
                  height: 76,
                  child: _Sprite(icon)),
              Positioned(
                left: 93,
                top: 9,
                width: constraints.maxWidth - 106,
                height: 88,
                child: _GameText('$value', fontSize: 48),
              ),
            ],
          ),
        ),
      );
}

class _StreakMedallion extends StatelessWidget {
  const _StreakMedallion({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
              left: 15,
              top: 74,
              width: 158,
              height: 176,
              child: _Sprite('streak_medal')),
          const Positioned(
              left: 42,
              top: 0,
              width: 116,
              height: 196,
              child: _FlickeringFlame()),
          Positioned(
              left: 47,
              top: 132,
              width: 94,
              height: 76,
              child: _GameText('$streak', fontSize: 54)),
        ],
      );
}

class _FlickeringFlame extends StatefulWidget {
  const _FlickeringFlame();

  @override
  State<_FlickeringFlame> createState() => _FlickeringFlameState();
}

class _FlickeringFlameState extends State<_FlickeringFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        child: const _Sprite('flame'),
        builder: (context, child) => Transform.scale(
          alignment: Alignment.bottomCenter,
          scaleX: 0.97 + _controller.value * 0.05,
          scaleY: 0.94 + _controller.value * 0.08,
          child: child,
        ),
      );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.state});

  final MainMenuState state;

  @override
  Widget build(BuildContext context) => Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
              left: 60,
              top: 0,
              width: 700,
              height: 184,
              child: _Sprite('green_button')),
          const Positioned(
              left: 170,
              top: 49,
              width: 480,
              height: 105,
              child: _Sprite('continue_word')),
          const Positioned(
              left: 88,
              top: 176,
              width: 644,
              height: 112,
              child: _Sprite('level_ribbon')),
          Positioned(
            left: 118,
            top: 194,
            width: 584,
            height: 68,
            child: _GameText(
              'Level ${state.campaignLevel}  •  ${state.chapterName}',
              fontSize: 33,
            ),
          ),
        ],
      );
}

class _RestoredFlowers extends StatelessWidget {
  const _RestoredFlowers({required this.state});

  final MainMenuState state;

  @override
  Widget build(BuildContext context) {
    final target = state.collectibleTarget.clamp(1, 10);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
            left: 10,
            top: 0,
            width: 900,
            height: 230,
            child: _Sprite('progress_panel')),
        const Positioned(
          left: 230,
          top: 25,
          width: 460,
          height: 42,
          child: _PanelText('Restored Flowers', fontSize: 34),
        ),
        for (var index = 0; index < target; index++)
          Positioned(
            left: 48 + index * (824 / target),
            top: 78,
            width: math.min(68, 760 / target),
            height: math.min(68, 760 / target),
            child: _CollectionFlower(
              index: index,
              restored: index < state.collectibleCount,
            ),
          ),
        const Positioned(
            left: 405,
            top: 181,
            width: 110,
            height: 62,
            child: _Sprite('count_badge')),
        Positioned(
          left: 405,
          top: 185,
          width: 110,
          height: 50,
          child: _GameText(
            '${state.collectibleCount} / ${state.collectibleTarget}',
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}

class _CollectionFlower extends StatelessWidget {
  const _CollectionFlower({required this.index, required this.restored});

  final int index;
  final bool restored;

  static const _assets = [
    'flower_pink',
    'flower_yellow',
    'flower_purple',
    'flower_pink',
    'flower_white',
    'flower_blue',
  ];

  @override
  Widget build(BuildContext context) {
    Widget flower = _Sprite(_assets[index % _assets.length]);
    if (!restored) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFF4A210B),
          BlendMode.srcIn,
        ),
        child: flower,
      );
    }
    if (index % _assets.length == 3) {
      flower = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFFFF6A35),
          BlendMode.modulate,
        ),
        child: flower,
      );
    }
    return flower;
  }
}

enum _NavigationKind { chapters, daily, collection }

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.kind,
    required this.onTap,
    this.showReady = false,
  });

  final _NavigationKind kind;
  final VoidCallback onTap;
  final bool showReady;

  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      _NavigationKind.chapters => 'CHAPTERS',
      _NavigationKind.daily => 'DAILY',
      _NavigationKind.collection => 'COLLECTION',
    };
    return _SpriteTap(
      semanticLabel: label,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
              left: 15,
              top: 104,
              width: 290,
              height: 150,
              child: _Sprite('nav_base')),
          if (kind == _NavigationKind.chapters)
            const Positioned(
                left: 65,
                top: 2,
                width: 190,
                height: 150,
                child: _Sprite('book')),
          if (kind == _NavigationKind.daily) ...[
            const Positioned(
                left: 80,
                top: 2,
                width: 160,
                height: 150,
                child: _Sprite('calendar')),
            const Positioned(
                left: 125,
                top: 42,
                width: 72,
                height: 72,
                child: _Sprite('daily_flower')),
            if (showReady) ...[
              const Positioned(
                  left: 198,
                  top: 12,
                  width: 100,
                  height: 62,
                  child: _Sprite('ready_badge')),
              const Positioned(
                  left: 202,
                  top: 19,
                  width: 92,
                  height: 45,
                  child: _GameText('READY', fontSize: 22)),
            ],
          ],
          if (kind == _NavigationKind.collection)
            const Positioned(
                left: 70,
                top: 0,
                width: 180,
                height: 156,
                child: _Sprite('chest')),
          Positioned(
            left: 12,
            top: 160,
            width: 296,
            height: 62,
            child: _GameText(
              label,
              fontSize: kind == _NavigationKind.collection ? 29 : 34,
            ),
          ),
        ],
      ),
    );
  }
}

class _MascotChase extends StatefulWidget {
  const _MascotChase();

  @override
  State<_MascotChase> createState() => _MascotChaseState();
}

class _MascotChaseState extends State<_MascotChase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value * math.pi * 2;
          final mascotX = 45 + math.sin(t) * 38;
          final mascotY = 145 + math.sin(t * 2) * 18;
          final blueX = 510 + math.cos(t) * 70;
          final blueY = 100 + math.sin(t * 2) * 58;
          final orangeX = 625 + math.cos(t + 1.9) * 40;
          final orangeY = 165 + math.sin(t * 1.7 + 1.2) * 76;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 330 + math.sin(t) * 20,
                top: 90 + math.cos(t * 1.4) * 32,
                width: 92,
                child: Transform.rotate(
                  angle: math.sin(t) * 0.14,
                  child: const Opacity(
                      opacity: 0.75, child: _Sprite('falling_petals')),
                ),
              ),
              Positioned(
                left: mascotX,
                top: mascotY,
                width: 304,
                child: Transform.rotate(
                  angle: math.sin(t * 2) * 0.045,
                  child: const _Sprite('mascot'),
                ),
              ),
              Positioned(
                left: blueX,
                top: blueY,
                width: 105,
                child: Transform.rotate(
                  angle: math.sin(t * 2) * 0.18,
                  child: Transform.scale(
                    scaleX: 0.82 + math.sin(t * 7).abs() * 0.18,
                    child: const _Sprite('butterfly_blue'),
                  ),
                ),
              ),
              Positioned(
                left: orangeX,
                top: orangeY,
                width: 65,
                child: Transform.rotate(
                  angle: math.cos(t * 1.7) * 0.22,
                  child: Transform.scale(
                    scaleX: 0.8 + math.sin(t * 8 + 0.8).abs() * 0.2,
                    child: const _Sprite('butterfly_orange'),
                  ),
                ),
              ),
            ],
          );
        },
      );
}

class _Sprite extends StatelessWidget {
  const _Sprite(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Image.asset(
        _sprite(name),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        gaplessPlayback: true,
      );
}

class _GameText extends StatelessWidget {
  const _GameText(this.text, {required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Stack(
          children: [
            ExcludeSemantics(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  height: 1,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = math.max(2.2, fontSize * 0.065)
                    ..color = const Color(0xFF4B2918),
                ),
              ),
            ),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: fontSize,
                height: 1,
                color: const Color(0xFFFFF2CF),
                shadows: const [
                  Shadow(
                      color: Color(0xAA6A3518),
                      offset: Offset(0, 3),
                      blurRadius: 1),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PanelText extends StatelessWidget {
  const _PanelText(this.text, {required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.w800,
              fontSize: fontSize,
              height: 1,
              color: const Color(0xFF6A371A),
            ),
          ),
        ),
      );
}

class _SpriteTap extends StatefulWidget {
  const _SpriteTap({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_SpriteTap> createState() => _SpriteTapState();
}

class _SpriteTapState extends State<_SpriteTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
      );
}

class _GameToast extends StatelessWidget {
  const _GameToast({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE86B2D16),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: const Color(0xFFFFD67A), width: 3),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 12, offset: Offset(0, 6))
          ],
        ),
        child: Center(child: _GameText(label, fontSize: 25)),
      );
}

class _InventoryInfoSheet extends StatelessWidget {
  const _InventoryInfoSheet({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          decoration: const BoxDecoration(
            color: Color(0xFFF8E5B9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(color: Color(0xFFD5973D), width: 4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox.square(dimension: 64, child: _Sprite(icon)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B321B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        height: 1.35,
                        color: Color(0xFF754D34),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class ThemeSelectorSheet extends StatelessWidget {
  const ThemeSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.bloomkuTheme;
    return SafeArea(
      top: false,
      child: Container(
        height: 330,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        decoration: const BoxDecoration(
          color: Color(0xFFF8E5B9),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: Color(0xFFD5973D), width: 4)),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF7A4325).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'THEME COLLECTION',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                fontSize: 21,
                color: Color(0xFF5B321B),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: BloomkuThemes.all.length,
                itemBuilder: (context, index) {
                  final theme = BloomkuThemes.all[index];
                  final isActive = activeTheme.id == theme.id;
                  final isLocked = !sl<ProgressRepository>()
                      .isThemeUnlocked(campaignChapters[index].themeId);
                  return GestureDetector(
                    onTap: isLocked
                        ? null
                        : () {
                            context.read<ThemeCubit>().selectTheme(index);
                            Navigator.of(context).pop();
                          },
                    child: Container(
                      width: 132,
                      margin: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [theme.backgroundTop, theme.backgroundBottom],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFDA8A27)
                              : const Color(0xFF9A683C),
                          width: isActive ? 4 : 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ThemedIcon(
                                  iconPath: theme.objectIconPaths.first,
                                  size: 52,
                                  color: theme.accentColor,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  theme.displayName,
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isLocked)
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(19),
                                ),
                                child: const Icon(Icons.lock_rounded,
                                    color: Colors.white, size: 34),
                              ),
                            ),
                          if (isActive)
                            const Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.check_circle,
                                  color: Color(0xFF4F921E)),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
