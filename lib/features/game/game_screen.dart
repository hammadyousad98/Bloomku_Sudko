import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../core/constants/ad_constants.dart';
import '../../core/constants/app_constants.dart';
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

  const GameScreen({super.key, required this.level, required this.track});

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
    AdService.isInGame = true;
  }

  @override
  void dispose() {
    AdService.isInGame = false;
    _cubit.close();
    super.dispose();
  }

  void _goToMenu() {
    context.go('/menu');
  }

  void _startNextLevel() {
    final nextLevel = _cubit.state.levelNumber + 1;
    if (nextLevel > maxLevelCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You completed every level!')),
      );
      return;
    }

    _cubit.startLevel(nextLevel, _cubit.state.activeTrack);
  }

  void _restartLevel() {
    _cubit.startLevel(_cubit.state.levelNumber, _cubit.state.activeTrack);
  }

  void _showPendingTutorials(GameState state) {
    if (_isShowingTutorial || state.pendingRuleTutorials.isEmpty) return;
    _isShowingTutorial = true;

    final ruleKey = state.pendingRuleTutorials.first;
    final config = PuzzleGenerator.configForLevel(
      state.levelNumber,
      state.activeTrack,
    );

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

              if (state.phase == GamePhase.generationError) {
                return _GenerationErrorView(
                  message: state.statusMessage ??
                      "Couldn't generate this level. Please try again.",
                  onRetry: () => _cubit.startLevel(
                    state.levelNumber,
                    state.activeTrack,
                  ),
                  onMenu: _goToMenu,
                );
              }

              final minutes = state.elapsed.inMinutes;
              final seconds = (state.elapsed.inSeconds % 60).toString().padLeft(
                    2,
                    '0',
                  );

              final config = PuzzleGenerator.configForLevel(
                state.levelNumber,
                state.activeTrack,
              );

              final mainContent = Column(
                children: [
                  TopBar(
                    level: state.levelNumber,
                    gridSize: state.puzzle.gridSize,
                  ),
                  if (AdConstants.showTopBannerAd)
                    BannerAdWidget(adUnitId: AdConstants.topBannerUnitId),
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
                    showDifficultyBar: state.showDifficultyBar,
                    showUltraTab: state.showUltraTab,
                    currentTrack: state.activeTrack,
                    onTrackSelected: _cubit.switchTrack,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildPuzzleGrid(state, theme),
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
                  if (AdConstants.showBottomBannerAd)
                    BannerAdWidget(adUnitId: AdConstants.bottomBannerUnitId),
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
                        onMenu: _goToMenu,
                      ),
                    )
                  else if (state.phase == GamePhase.gameOver ||
                      state.phase == GamePhase.reviveOffer)
                    Positioned.fill(
                      child: GameOverOverlay(
                        state: state,
                        onGiveUp: () => _cubit.giveUp(),
                        onTryAgain: _restartLevel,
                        onMenu: _goToMenu,
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

  Widget _buildPuzzleGrid(GameState state, dynamic theme) {
    final grid = PuzzleGrid(
      gridSize: state.puzzle.gridSize,
      states: state.tileStates,
      colorRegions: state.puzzle.colorMap,
      colorMap: List<Color>.from(
        state.puzzle.colorMap.map(
          (c) => theme.tileColors[c % theme.tileColors.length],
        ),
      ),
      errorTileIndex: state.errorTileIndex,
      hintTileIndex: state.hintTileIndex,
      onTileSingleTap: (index) => _cubit.onTileSingleTap(index),
      onTileDoubleTap: (index) => _cubit.onTileDoubleTap(index),
    );

    if (state.puzzle.gridSize >= 10) {
      return RepaintBoundary(child: grid);
    }

    return grid;
  }
}

class _GenerationErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  const _GenerationErrorView({
    required this.message,
    required this.onRetry,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh_rounded, size: 48, color: theme.accentColor),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onMenu,
                  child: const Text('Menu'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
