import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/audio_service.dart';
import '../../services/ad_service.dart';
import '../../services/app_services_bootstrap.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/game_session_repository.dart';
import '../../data/repositories/game_results_repository.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/daily_history_repository.dart';
import '../../data/repositories/session_goal_repository.dart';
import '../../core/analytics/onboarding_analytics.dart';
import '../../core/config/feature_flags.dart';
import '../../core/utils/puzzle_generator.dart';
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
  int _lastLifeLostToken = 0;
  bool _wasGuidedModeActive = false;
  final GlobalKey _gridKey = GlobalKey();
  final List<GlobalKey> _heartKeys = List.generate(3, (_) => GlobalKey());
  bool _blockGridInput = false;

  @override
  void initState() {
    super.initState();
    final progressRepo = GetIt.I<ProgressRepository>();
    final settingsRepo = GetIt.I<SettingsRepository>();
    final dailyChallengeRepo = GetIt.I<DailyChallengeRepository>();
    final sessionRepo = GetIt.I<GameSessionRepository>();
    final onboardingAnalytics = GetIt.I<OnboardingAnalytics>();
    _cubit = GameCubit(
      progressRepo,
      settingsRepo,
      dailyChallengeRepo,
      sessionRepo,
      onboardingAnalytics,
      GetIt.I<GameResultsRepository>(),
      GetIt.I<CollectionRepository>(),
      GetIt.I<DailyHistoryRepository>(),
      GetIt.I<SessionGoalRepository>(),
    );

    if (widget.isDailyChallenge) {
      _cubit.startDailyChallenge();
    } else {
      final pTrack = widget.track.toLowerCase() == 'hard'
          ? PuzzleTrack.hard
          : (widget.track.toLowerCase() == 'ultra'
              ? PuzzleTrack.ultraHard
              : PuzzleTrack.normal);

      _cubit.startLevel(widget.level, pTrack);
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

  Future<void> _openSettings() async {
    _cubit.pauseGame();
    await context.push('/settings');
    if (mounted) _cubit.resumeGame();
  }

  Future<void> _openPauseMenu() async {
    _cubit.pauseGame();
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _GardenPauseDialog(),
    );
    if (!mounted) return;
    if (action == 'menu') {
      _goToMenu();
    } else if (action == 'settings') {
      await _openSettings();
    } else {
      _cubit.resumeGame();
    }
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
    if (nextLevel > FeatureFlags.current.campaignMaxLevel) {
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
      _cubit.startLevel(_cubit.state.levelNumber, _cubit.state.activeTrack,
          forceRestart: true);
    }
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/backgrounds/main_menu_bg_v1.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
            Container(color: const Color(0xFF18300D).withValues(alpha: 0.10)),
            SafeArea(
              child: BlocConsumer<GameCubit, GameState>(
                listener: (context, state) {
                  if (_wasGuidedModeActive &&
                      !state.guidedModeActive &&
                      state.phase == GamePhase.levelComplete) {
                    _goToMenu();
                  }
                  _wasGuidedModeActive = state.guidedModeActive;

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
                    if (state.lifeLostTileIndex != null &&
                        state.lifeLostTargetHeartIndex != null) {
                      _playHeartbreakAnimation(state.lifeLostTileIndex!,
                          state.lifeLostTargetHeartIndex!);
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
                  final seconds =
                      (state.elapsed.inSeconds % 60).toString().padLeft(
                            2,
                            '0',
                          );

                  final config = PuzzleGenerator.configForLevel(
                    state.levelNumber,
                    state.activeTrack,
                  );

                  final mainContent = LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 720;
                      return Column(
                        children: [
                          TopBar(
                            level: state.levelNumber,
                            gridSize: state.puzzle.gridSize,
                            onSettings: _openPauseMenu,
                          ),
                          if (state.guidedModeActive &&
                              state.guidedInstructionText != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (state.levelNumber == 1 &&
                                      state.guidedStepIndex == 0 &&
                                      state.guidedTeachingMarker)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, bottom: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.school,
                                              size: 14,
                                              color: theme.accentColor),
                                          const SizedBox(width: 4),
                                          Text("Bloom School",
                                              style: TextStyle(
                                                  color: theme.accentColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (state.puzzle.solutionIndexes
                                                  .isNotEmpty)
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 6),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white24,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  child: Text(
                                                    state.guidedTeachingMarker
                                                        ? "Step 1 of ${state.puzzle.solutionIndexes.length + 1}"
                                                        : "Step ${state.guidedStepIndex + (state.levelNumber == 1 ? 2 : 1)} of ${state.puzzle.solutionIndexes.length + (state.levelNumber == 1 ? 1 : 0)}",
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold),
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
                                          onPressed: () =>
                                              _cubit.cancelGuidedTutorial(),
                                          child: const Text('Skip Tutorial',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                        ),
                                      ],
                                    ),
                                  )
                                      .animate()
                                      .fadeIn()
                                      .slideY(begin: -0.2, end: 0),
                                ],
                              ),
                            ),
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
                            hasMines:
                                state.activeTrack == PuzzleTrack.ultraHard &&
                                    state.puzzle.mineIndexes.isNotEmpty,
                            highlightedRule: state.guidedModeActive
                                ? (state.levelNumber == 1
                                    ? 'rowColumn'
                                    : (state.levelNumber == 2
                                        ? 'colorRegion'
                                        : 'noTouch'))
                                : null,
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
                                padding: EdgeInsets.fromLTRB(
                                  compact ? 7 : 10,
                                  3,
                                  compact ? 7 : 10,
                                  2,
                                ),
                                child: _buildPuzzleGrid(state, theme),
                              ),
                            ),
                          ),
                          const _InteractionHintBar(),
                          if (!state.guidedModeActive &&
                              FeatureFlags
                                  .current.lockedFlowerAutoMarkIconsAndZoom)
                            BottomButtons(
                              hintCount: state.hintCount,
                              bulbCount: state.bulbCount,
                              undoCount: state.undoCount,
                              autoMarkCount: state.autoMarkCount,
                              enabled: state.powersEnabled,
                              onHintTap: () => _cubit.useHint(),
                              onBulbTap: () => _cubit.useBulb(),
                              onUndoTap: () => _cubit.undoLast(),
                              onAutoMarkTap: () => _cubit.useAutoMark(),
                            ),
                          GameplayScoreBar(
                            score: state.score,
                            progress: state.targetCount == 0
                                ? 0
                                : state.placedCount / state.targetCount,
                          ),
                        ],
                      );
                    },
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
                      else if (state.guidedPreviewActive &&
                          state.guidedPreviewRule != null)
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
                          child: ListenableBuilder(
                            listenable: GetIt.I<AppServicesBootstrap>(),
                            builder: (context, _) {
                              final ads = GetIt.I<AppServicesBootstrap>().ads;
                              return GameOverOverlay(
                                state: state,
                                rewardedAdAvailable: ads.isReady,
                                onWatchAdForLife: () => AdService.showRewarded(
                                  RewardType.extraLife,
                                  onRewarded: _cubit.onRewardedAdCompleted,
                                  adsRemoved: GetIt.I<ProgressRepository>()
                                      .getProgress()
                                      .adsRemoved,
                                ),
                                onUseExtraLife: _cubit.useInventoryExtraLife,
                                onGiveUp: () => _cubit.giveUp(),
                                onTryAgain: _restartLevel,
                                onMenu: _goToMenu,
                              );
                            },
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
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.green.shade600,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      spreadRadius: 2)
                                ],
                              ),
                              child: Text(
                                state.guidedFeedbackText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                                .animate()
                                .scale(
                                    curve: Curves.easeOutBack, duration: 400.ms)
                                .fadeIn(),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
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
      onTileTap: (index) {
        if (!_blockGridInput) _cubit.onTileTap(index);
      },
      onTileLongPress: (index) {
        if (!_blockGridInput) _cubit.onTileLongPress(index);
      },
    );

    final framedGrid = AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/sprites/gameplay/board_frame.png',
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: grid,
          ),
        ],
      ),
    );

    if (state.puzzle.gridSize >= 10 &&
        FeatureFlags.current.lockedFlowerAutoMarkIconsAndZoom) {
      return ZoomablePuzzleBoard(
        key: ValueKey(
          '${state.mode.name}:${state.levelNumber}:${state.activeTrack.name}',
        ),
        onInputBlockedChanged: (blocked) => _blockGridInput = blocked,
        child: RepaintBoundary(child: framedGrid),
      );
    }

    return framedGrid;
  }
}

class _InteractionHintBar extends StatelessWidget {
  const _InteractionHintBar();

  @override
  Widget build(BuildContext context) => Container(
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFFDFA4),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFF8A4D1E), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: const Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '☘  Tap to plant  •  Hold for X  ☘',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w800,
                color: Color(0xFF70401E),
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
}

class _GardenPauseDialog extends StatelessWidget {
  const _GardenPauseDialog();

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFDFA4),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0xFF9C5A20), width: 5),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black45, blurRadius: 20, offset: Offset(0, 9)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSED',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: Color(0xFF5A2B14),
                ),
              ),
              const SizedBox(height: 20),
              _PauseAction(
                  label: 'RESUME',
                  onTap: () => Navigator.pop(context, 'resume')),
              const SizedBox(height: 10),
              _PauseAction(
                  label: 'SETTINGS',
                  onTap: () => Navigator.pop(context, 'settings')),
              const SizedBox(height: 10),
              _PauseAction(
                  label: 'MAIN MENU',
                  onTap: () => Navigator.pop(context, 'menu')),
            ],
          ),
        ),
      );
}

class _PauseAction extends StatelessWidget {
  const _PauseAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6FA912),
            foregroundColor: const Color(0xFFFFF0C7),
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFF4B7210), width: 2),
            ),
          ),
          child:
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      );
}

class ZoomablePuzzleBoard extends StatefulWidget {
  const ZoomablePuzzleBoard({
    super.key,
    required this.child,
    required this.onInputBlockedChanged,
  });

  final Widget child;
  final ValueChanged<bool> onInputBlockedChanged;

  @override
  State<ZoomablePuzzleBoard> createState() => ZoomablePuzzleBoardState();
}

class ZoomablePuzzleBoardState extends State<ZoomablePuzzleBoard> {
  final TransformationController _controller = TransformationController();
  Matrix4 _interactionStartMatrix = Matrix4.identity();
  DateTime? _lastPointerDown;
  Offset? _lastPointerPosition;
  Timer? _unblockTimer;
  bool _gestureChanged = false;
  final Set<int> _activePointers = {};

  Matrix4 get transformation => _controller.value.clone();

  @override
  void dispose() {
    _unblockTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _isTransformed {
    final identity = Matrix4.identity().storage;
    final current = _controller.value.storage;
    for (var index = 0; index < current.length; index++) {
      if ((current[index] - identity[index]).abs() > 0.001) return true;
    }
    return false;
  }

  void _blockInput([Duration duration = const Duration(milliseconds: 140)]) {
    _unblockTimer?.cancel();
    widget.onInputBlockedChanged(true);
    _unblockTimer = Timer(duration, () {
      widget.onInputBlockedChanged(false);
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    final isFirstPointer = _activePointers.isEmpty;
    _activePointers.add(event.pointer);
    if (!isFirstPointer) return;
    final now = DateTime.now();
    final previous = _lastPointerDown;
    final previousPosition = _lastPointerPosition;
    _lastPointerDown = now;
    _lastPointerPosition = event.localPosition;
    if (previous != null &&
        previousPosition != null &&
        now.difference(previous) < const Duration(milliseconds: 320) &&
        (event.localPosition - previousPosition).distance < 28 &&
        _isTransformed) {
      _blockInput(const Duration(milliseconds: 220));
      _controller.value = Matrix4.identity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRect(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _handlePointerDown,
          onPointerUp: (event) => _activePointers.remove(event.pointer),
          onPointerCancel: (event) => _activePointers.remove(event.pointer),
          child: InteractiveViewer(
            transformationController: _controller,
            minScale: 1,
            maxScale: 3.5,
            panEnabled: true,
            scaleEnabled: true,
            boundaryMargin: EdgeInsets.zero,
            clipBehavior: Clip.hardEdge,
            onInteractionStart: (details) {
              _interactionStartMatrix = _controller.value.clone();
              _gestureChanged = false;
            },
            onInteractionUpdate: (details) {
              if (details.pointerCount < 2) {
                _controller.value = _interactionStartMatrix.clone();
                return;
              }
              _gestureChanged = true;
              widget.onInputBlockedChanged(true);
            },
            onInteractionEnd: (details) {
              if (_gestureChanged) _blockInput();
            },
            child: widget.child,
          ),
        ),
      ),
    );
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
