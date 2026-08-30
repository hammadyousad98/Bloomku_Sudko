import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/daily_challenge_config.dart';
import '../../core/utils/puzzle_generator.dart';
import '../../data/repositories/daily_challenge_repository.dart';
import '../../data/repositories/daily_history_repository.dart';
import '../../services/reminder_service.dart';
import '../game/widgets/rules_panel.dart';
import 'daily_challenge_cubit.dart';
import 'daily_share_card.dart';

class DailyChallengesScreen extends StatelessWidget {
  const DailyChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DailyChallengeCubit(
        GetIt.I<DailyChallengeRepository>(),
        GetIt.I<DailyHistoryRepository>(),
      )..loadState(),
      child: const _DailyChallengeView(),
    );
  }
}

class _DailyChallengeView extends StatelessWidget {
  const _DailyChallengeView();

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.backgroundTop, theme.backgroundBottom],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _ChallengeAppBar(onBack: () => context.pop()),
                Expanded(
                  child: BlocBuilder<DailyChallengeCubit,
                      DailyChallengeCubitState>(
                    builder: (context, state) {
                      return switch (state) {
                        DailyChallengeLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        DailyChallengeNotPlayed() =>
                          _NotPlayedContent(state: state),
                        DailyChallengeCompleted() =>
                          _CompletedContent(state: state),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeAppBar extends StatelessWidget {
  const _ChallengeAppBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: theme.textPrimary,
                size: 20,
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'Daily Challenge',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _NotPlayedContent extends StatelessWidget {
  const _NotPlayedContent({required this.state});

  final DailyChallengeNotPlayed state;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final config = PuzzleGenerator.configForLevel(
      state.challenge.level,
      state.challenge.track,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          _StreakPill(streak: state.currentChallengeStreak),
          const SizedBox(height: 14),
          _MonthlyCalendar(days: state.calendarDays),
          const SizedBox(height: 14),
          const _ReminderOptInCard(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 58)),
                const SizedBox(height: 8),
                Text(
                  "Today's Puzzle",
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${config.gridSize} × ${config.gridSize}  •  '
                  '${_trackLabel(state.challenge.track)}',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Rules',
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                RulesPanel(
                  blockFullDiagonal: config.blockFullDiagonal,
                  blockMinDistance: config.blockMinDistance,
                  minDistance: config.minDistance,
                  blockKnightMove: config.blockKnightMove,
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Complete it today to earn '
                      '${_completionRewardText(state.challenge)}.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _PrimaryButton(
                    label: 'Play',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _openDailyChallenge(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedContent extends StatelessWidget {
  const _CompletedContent({required this.state});

  final DailyChallengeCompleted state;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        children: [
          _StreakPill(streak: state.currentChallengeStreak),
          const SizedBox(height: 14),
          _MonthlyCalendar(days: state.calendarDays),
          const SizedBox(height: 14),
          const _ReminderOptInCard(),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 54,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Challenge Complete!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Best ${_formatMilliseconds(state.result.bestTimeMs)} · '
                  '${state.result.lowestMistakes} mistakes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'NEXT PUZZLE IN',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatCountdown(state.timeUntilNextChallenge),
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Current streak',
                        value: '${state.currentChallengeStreak}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: 'Longest streak',
                        value: '${state.longestChallengeStreak}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _PrimaryButton(
                  label: 'Replay',
                  icon: Icons.replay_rounded,
                  onPressed: () => _openDailyChallenge(context),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await SharePlus.instance.share(
                        ShareParams(
                          text: buildDailyShareText(
                            date: DateTime.now(),
                            challenge: state.challenge,
                            result: state.result,
                          ),
                          subject: 'Zenduko Daily Challenge',
                        ),
                      );
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.textPrimary,
                      side: BorderSide(
                        color: theme.textPrimary.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyCalendar extends StatelessWidget {
  const _MonthlyCalendar({required this.days});

  final List<DailyCalendarDay> days;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    if (days.isEmpty) return const SizedBox.shrink();
    final leading = days.first.date.weekday - 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(days.first.date),
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final label in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: leading + days.length,
            itemBuilder: (context, index) {
              if (index < leading) return const SizedBox.shrink();
              final day = days[index - leading];
              final (color, icon) = switch (day.status) {
                DailyCalendarStatus.completed => (Colors.green, '✓'),
                DailyCalendarStatus.missed => (Colors.red.shade300, '·'),
                DailyCalendarStatus.today => (theme.accentColor, '${day.date.day}'),
                DailyCalendarStatus.future =>
                  (theme.textSecondary.withValues(alpha: 0.25), '${day.date.day}'),
              };
              return Tooltip(
                message: day.bestTimeMs > 0
                    ? 'Best ${_formatMilliseconds(day.bestTimeMs)}'
                    : day.status.name,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: day.status == DailyCalendarStatus.today
                        ? Border.all(color: color, width: 2)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '✓ completed   · missed   ◯ today',
            style: TextStyle(color: theme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _ReminderOptInCard extends StatefulWidget {
  const _ReminderOptInCard();

  @override
  State<_ReminderOptInCard> createState() => _ReminderOptInCardState();
}

class _ReminderOptInCardState extends State<_ReminderOptInCard> {
  late final ReminderService _reminders = GetIt.I<ReminderService>();
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    if (_reminders.isEnabled) {
      setState(() => _busy = true);
      await _reminders.disable();
      if (mounted) setState(() => _busy = false);
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Enable a daily reminder?'),
            content: const Text(
              'Zendoku will send one respectful reminder at 7:00 PM. '
              'You can turn it off here at any time.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enable'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    final enabled = await _reminders.enableAfterExplicitPrompt();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification permission was not granted.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Material(
      color: theme.cardColor.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        onTap: _toggle,
        leading: Icon(Icons.notifications_none_rounded, color: theme.accentColor),
        title: const Text('Daily reminder'),
        subtitle: Text(
          _reminders.isEnabled ? 'Enabled for 7:00 PM' : 'Off by default',
        ),
        trailing: _busy
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Switch(value: _reminders.isEnabled, onChanged: (_) => _toggle()),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
      decoration: BoxDecoration(
        color: theme.accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: theme.accentColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 21)),
          const SizedBox(width: 8),
          Text(
            streak == 1 ? '1 Day Streak' : '$streak Day Streak',
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.backgroundTop.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accentColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

Future<void> _openDailyChallenge(BuildContext context) async {
  await context.push(
    '/game',
    extra: <String, Object?>{'isDailyChallenge': true},
  );
  if (context.mounted) {
    context.read<DailyChallengeCubit>().loadState();
  }
}

String _trackLabel(PuzzleTrack track) {
  return switch (track) {
    PuzzleTrack.normal => 'Normal',
    PuzzleTrack.hard => 'Hard',
    PuzzleTrack.ultraHard => 'Ultra Hard',
  };
}

String _formatCountdown(Duration duration) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final hours = safeDuration.inHours.toString().padLeft(2, '0');
  final minutes = (safeDuration.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (safeDuration.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatMilliseconds(int milliseconds) {
  final duration = Duration(milliseconds: milliseconds);
  final minutes = duration.inMinutes;
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _completionRewardText(DailyChallengeDay day) {
  final rewards = <String>[
    if (day.hintReward > 0)
      '+${day.hintReward} ${day.hintReward == 1 ? 'hint' : 'hints'}',
    if (day.bulbReward > 0)
      '+${day.bulbReward} ${day.bulbReward == 1 ? 'row solve' : 'row solves'}',
    if (day.undoReward > 0)
      '+${day.undoReward} ${day.undoReward == 1 ? 'undo' : 'undos'}',
    if (day.extraLifeReward > 0)
      '+${day.extraLifeReward} '
          '${day.extraLifeReward == 1 ? 'extra life' : 'extra lives'}',
    if (day.autoMarkReward > 0)
      '+${day.autoMarkReward} AutoMark${day.autoMarkReward == 1 ? '' : 's'}',
  ];

  if (rewards.length == 1) return rewards.single;
  if (rewards.length == 2) return '${rewards.first} and ${rewards.last}';
  return '${rewards.take(rewards.length - 1).join(', ')}, and ${rewards.last}';
}
