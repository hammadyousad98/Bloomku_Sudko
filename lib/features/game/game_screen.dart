import 'package:flutter/material.dart';
import '../../services/audio_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/progress_repository.dart';
import '../../core/utils/puzzle_generator.dart';
import '../tutorial/tutorial_cubit.dart';
import '../tutorial/tutorial_screen.dart';
import 'cubit/game_cubit.dart';
import 'cubit/game_state.dart';
import 'widgets/top_bar.dart';
import 'widgets/progress_row.dart';
import 'widgets/rules_panel.dart';
import 'widgets/difficulty_bar.dart';
import 'widgets/puzzle_grid.dart';
import 'widgets/bottom_buttons.dart';
import 'widgets/win_overlay.dart';
import 'widgets/game_over_overlay.dart';
import '../../widgets/ads/banner_ad_widget.dart';

class GameScreen extends StatefulWidget {
  final int level;
  final String track;

  const GameScreen({
    super.key,
    required this.level,
    required this.track,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameCubit _cubit;
  bool _isShowingTutorial = false;

  @override
  void initState() {
    super.initState();
    final progressRepo = GetIt.I<ProgressRepository>();
    _cubit = GameCubit(progressRepo, null, null);

    final pTrack = widget.track.toLowerCase() == 'hard'
        ? PuzzleTrack.hard
        : (widget.track.toLowerCase() == 'ultra'
            ? PuzzleTrack.ultraHard
            : PuzzleTrack.normal);

    _cubit.startLevel(widget.level, pTrack);
    AudioService.playGameMusic();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _goToLevels() {
    Navigator.of(context).pop();
  }

  void _startNextLevel() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(level: widget.level + 1, track: widget.track),
      ),
    );
  }

  void _restartLevel() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            GameScreen(level: widget.level, track: widget.track),
      ),
    );
  }

  void _showPendingTutorials(GameState state) {
    if (_isShowingTutorial || state.pendingRuleTutorials.isEmpty) return;
    _isShowingTutorial = true;

    final ruleKey = state.pendingRuleTutorials.first;
    final config = PuzzleGenerator.configForLevel(
        state.levelNumber, state.activeTrack);

    TutorialSlide slide;
    switch (ruleKey) {
      case 'diagonal':
        slide = TutorialCubit.getFullDiagonalRule();
        break;
      case 'minDistance':
        slide = TutorialCubit.getMinDistanceRule(config.minDistance);
        break;
      case 'knightMove':
        slide = TutorialCubit.getKnightsMoveRule();
        break;
      default:
        _isShowingTutorial = false;
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RuleTutorialDialog.show(context, slide).then((_) {
        _isShowingTutorial = false;
        _cubit.dismissNextRuleTutorial();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: theme.backgroundTop,
        body: SafeArea(
          child: BlocConsumer<GameCubit, GameState>(
            listener: (context, state) {
              // Show pending rule tutorials as dialogs
              if (state.pendingRuleTutorials.isNotEmpty) {
                _showPendingTutorials(state);
              }
            },
            builder: (context, state) {
              if (state.phase == GamePhase.loading) {
                return const Center(child: CircularProgressIndicator());
              }

              final minutes = state.elapsed.inMinutes;
              final seconds =
                  (state.elapsed.inSeconds % 60).toString().padLeft(2, '0');

              final config = PuzzleGenerator.configForLevel(
                  state.levelNumber, state.activeTrack);

              final mainContent = Column(
                children: [
                  TopBar(
                      level: state.levelNumber,
                      gridSize: state.puzzle.gridSize),
                  ProgressRow(
                    placedCount: state.placedCount,
                    totalCount: state.targetCount,
                    lives: state.livesRemaining,
                    score: state.score,
                    timerText: "$minutes:$seconds",
                  ),
                  RulesPanel(
                    blockFullDiagonal: config.blockFullDiagonal,
                    blockMinDistance: config.blockMinDistance,
                    minDistance: config.minDistance,
                    blockKnightMove: config.blockKnightMove,
                  ),
                  DifficultyBar(
                    highestUnlockedLevel: 16,
                    currentTrack: state.activeTrack.name,
                    onTrackSelected: (newTrack) {
                      final pTrack = newTrack.toLowerCase() == 'hard'
                          ? PuzzleTrack.hard
                          : (newTrack.toLowerCase() == 'ultra'
                              ? PuzzleTrack.ultraHard
                              : PuzzleTrack.normal);
                      _cubit.switchTrack(pTrack);
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: PuzzleGrid(
                          gridSize: state.puzzle.gridSize,
                          states: state.tileStates,
                          colorMap: state.puzzle.colorMap
                              .map((c) =>
                                  theme.tileColors[c % theme.tileColors.length])
                              .toList(),
                          onTileTap: (index) => _cubit.onTileTap(index),
                        ),
                      ),
                    ),
                  ),
                  BottomButtons(
                    hintCount: state.hintCount,
                    bulbCount: state.bulbCount,
                    undoCount: state.undoCount,
                    onHintTap: () => _cubit.useHint(),
                    onBulbTap: () => _cubit.useBulb(),
                    onUndoTap: () => _cubit.undoLast(),
                  ),
                  const BannerAdWidget(),
                ],
              );

              return Stack(
                children: [
                  mainContent,

                  // Overlays
                  if (state.phase == GamePhase.levelComplete)
                    Positioned.fill(
                      child: WinOverlay(
                        state: state,
                        onNextLevel: _startNextLevel,
                        onLevels: _goToLevels,
                      ),
                    )
                  else if (state.phase == GamePhase.gameOver ||
                      state.phase == GamePhase.reviveOffer)
                    Positioned.fill(
                      child: GameOverOverlay(
                        state: state,
                        onGiveUp: () => _cubit.giveUp(),
                        onTryAgain: _restartLevel,
                        onLevels: _goToLevels,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
