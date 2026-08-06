import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../core/constants/ad_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/settings_repository.dart';
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
import 'widgets/heartbreak_animation.dart';
import 'widgets/guided_rule_preview.dart';
import 'widgets/guided_recap_overlay.dart';

class GameScreen extends StatefulWidget {
  final int level;
  final String track;
  final bool isDailyChallenge;

  const GameScreen({
    super.key,
    required this.level,
    required this.track,
    this.isDailyChallenge = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late GameCubit _cubit;
  bool _isShowingTutorial = false;
  int _lastLifeLostToken = 0;
  bool _wasGuidedModeActive = false;
  final GlobalKey _gridKey = GlobalKey();
  final List<GlobalKey> _heartKeys = List.generate(3, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    final progressRepo = GetIt.I<ProgressRepository>();
    final settingsRepo = GetIt.I<SettingsRepository>();
    final dailyChallengeRepo = GetIt.I<DailyChallengeRepository>();
    _cubit = GameCubit(progressRepo, settingsRepo, dailyChallengeRepo);

    if (widget.isDailyChallenge) {
      _cubit.startDailyChallenge();
    } else {
      final pTrack = widget.track.toLowerCase() == 'hard'
          ? PuzzleTrack.hard
          : (widget.track.toLowerCase() == 'ultra'
              ? PuzzleTrack.ultraHard
              : PuzzleTrack.normal);

      if (widget.level == 1 &&
          pTrack == PuzzleTrack.normal &&
          !progressRepo.getProgress().guidedTutorialSeen) {
        _cubit.startGuidedTutorial();
      } else {
        _cubit.startLevel(widget.level, pTrack);
      }
    }
    AudioService.stopMusic();
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
    if (_cubit.state.guidedModeActive) {
      _cubit.advanceGuidedLevel();
      return;
    }

    if (_cubit.state.mode == GameMode.dailyChallenge) {
      _goToMenu();
      return;
    }

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
    if (_cubit.state.mode == GameMode.dailyChallenge) {
      _cubit.startDailyChallenge();
    } else {
      _cubit.startLevel(_cubit.state.levelNumber, _cubit.state.activeTrack, forceRestart: true);
    }
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
      case 'mine':
        slide = TutorialCubit.getMineRule();
        break;
      // Obsolete rule cases (rowColumn, colorRegion, noTouch) have been superseded
      // by the guided tutorial walkthrough and are no longer fired here.
      default:
        _isShowingTutorial = false;
        return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RuleTutorialDialog.show(context, slide).then((_) {
        _isShowingTutorial = false;
        _cubit.dismissNextRuleTutorial(ruleKey);
      });
    });
  }

  void _playHeartbreakAnimation(int tileIndex, int targetHeartIndex) {
    if (targetHeartIndex < 0 || targetHeartIndex >= _heartKeys.length) return;
    
    final gridContext = _gridKey.currentContext;
    final heartContext = _heartKeys[targetHeartIndex].currentContext;
    if (gridContext == null || heartContext == null) return;

    final gridBox = gridContext.findRenderObject() as RenderBox;
    final heartBox = heartContext.findRenderObject() as RenderBox;

    final gridSize = _cubit.state.puzzle.gridSize;
    final cellWidth = (gridBox.size.width - (gridSize - 1) * 4.0) / gridSize;
    final cellHeight = (gridBox.size.height - (gridSize - 1) * 4.0) / gridSize;
    
    final row = tileIndex ~/ gridSize;
    final col = tileIndex % gridSize;
    
    final startOffset = gridBox.localToGlobal(
      Offset(
        col * (cellWidth + 4.0) + cellWidth / 2,
        row * (cellHeight + 4.0) + cellHeight / 2,
      ),
    );

    final endOffset = heartBox.localToGlobal(
      heartBox.size.center(Offset.zero),
    );

    showHeartbreakAnimation(context, startOffset, endOffset);
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
              if (_wasGuidedModeActive && !state.guidedModeActive && state.phase == GamePhase.levelComplete) {
                _goToMenu();
              }
              _wasGuidedModeActive = state.guidedModeActive;

              // Show pending rule tutorials as dialogs
              if (state.pendingRuleTutorials.isNotEmpty) {
                _showPendingTutorials(state);
              }
              
              if (state.rewardMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.rewardMessage!),
                    duration: const Duration(seconds: 2),
                  ),
                );
                _cubit.clearRewardMessage();
              }

              if (state.lifeLostToken > _lastLifeLostToken) {
                _lastLifeLostToken = state.lifeLostToken;
                if (state.lifeLostTileIndex != null && state.lifeLostTargetHeartIndex != null) {
                  _playHeartbreakAnimation(state.lifeLostTileIndex!, state.lifeLostTargetHeartIndex!);
                }
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
                  onRetry: _restartLevel,
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
                  if (state.guidedModeActive && state.guidedInstructionText != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.levelNumber == 1 && state.guidedStepIndex == 0 && state.guidedTeachingMarker)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.school, size: 14, color: theme.accentColor),
                                  const SizedBox(width: 4),
                                  Text("Bloom School", style: TextStyle(color: theme.accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ).animate().fadeIn().slideX(begin: -0.2),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: theme.accentColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(4),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (state.puzzle.solutionIndexes.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white24,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            state.guidedTeachingMarker 
                                                ? "Step 1 of ${state.puzzle.solutionIndexes.length + 1}" 
                                                : "Step ${state.guidedStepIndex + (state.levelNumber == 1 ? 2 : 1)} of ${state.puzzle.solutionIndexes.length + (state.levelNumber == 1 ? 1 : 0)}",
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      Text(
                                        state.guidedInstructionText!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _cubit.cancelGuidedTutorial(),
                                  child: const Text('Skip Tutorial', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                        ],
                      ),
                    ),
                  if (AdConstants.showTopBannerAd && !state.guidedModeActive)
                    BannerAdWidget(adUnitId: AdConstants.topBannerUnitId),
                  ProgressRow(
                    placedCount: state.placedCount,
                    totalCount: state.targetCount,
                    lives: state.livesRemaining,
                    score: state.score,
                    timerText: "$minutes:$seconds",
                    heartKeys: _heartKeys,
                  ),
                  RulesPanel(
                    blockFullDiagonal: config.blockFullDiagonal,
                    blockMinDistance: config.blockMinDistance,
                    minDistance: config.minDistance,
                    blockKnightMove: config.blockKnightMove,
                    hasMines: state.activeTrack == PuzzleTrack.ultraHard && state.puzzle.mineIndexes.isNotEmpty,
                    highlightedRule: state.guidedModeActive ? (state.levelNumber == 1 ? 'rowColumn' : (state.levelNumber == 2 ? 'colorRegion' : 'noTouch')) : null,
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
                  if (!state.guidedModeActive)
                    BottomButtons(
                      hintCount: state.hintCount,
                      bulbCount: state.bulbCount,
                      undoCount: state.undoCount,
                      onHintTap: () => _cubit.useHint(),
                      onBulbTap: () => _cubit.useBulb(),
                      onUndoTap: () => _cubit.undoLast(),
                    ),
                  if (AdConstants.showBottomBannerAd && !state.guidedModeActive)
                    BannerAdWidget(adUnitId: AdConstants.bottomBannerUnitId),
                ],
              );

              return Stack(
                children: [
                  mainContent,

                  // Overlays
                  if (state.showGuidedRecap)
                    Positioned.fill(
                      child: GuidedRecapOverlay(
                        onLetPlay: () {
                          _cubit.cancelGuidedRecap();
                          _goToMenu();
                        },
                      ),
                    )
                  else if (state.guidedPreviewActive && state.guidedPreviewRule != null)
                    Positioned.fill(
                      child: GuidedRulePreview(
                        rule: state.guidedPreviewRule!,
                        onComplete: () => _cubit.finishGuidedPreview(),
                      ),
                    )
                  else if (state.phase == GamePhase.levelComplete)
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
                        onWatchAdForLife: () => AdService.showRewarded(
                          RewardType.extraLife,
                          onRewarded: _cubit.onRewardedAdCompleted,
                          adsRemoved: GetIt.I<ProgressRepository>()
                              .getProgress()
                              .adsRemoved,
                        ),
                        onGiveUp: () => _cubit.giveUp(),
                        onTryAgain: _restartLevel,
                        onMenu: _goToMenu,
                      ),
                    ),
                  
                  // Feedback Toast
                  if (state.guidedFeedbackText != null)
                    Positioned(
                      top: 140,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, spreadRadius: 2)],
                          ),
                          child: Text(
                            state.guidedFeedbackText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms).fadeIn(),
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
      gridKey: _gridKey,
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
      mineTileIndex: state.mineTileIndex,
      tutorialHighlightIndexes: state.tutorialHighlightIndexes,
      guidedModeActive: state.guidedModeActive,
      guidedInteractableIndex: state.guidedInteractableIndex,
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
