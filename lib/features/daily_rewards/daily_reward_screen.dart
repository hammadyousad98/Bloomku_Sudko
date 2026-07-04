import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/daily_reward_state.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/reward_repository.dart';
import 'daily_reward_cubit.dart';

// ---------------------------------------------------------------------------
// Entry point widget — creates and provisions the cubit
// ---------------------------------------------------------------------------

class DailyRewardScreen extends StatelessWidget {
  const DailyRewardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DailyRewardCubit(
        GetIt.I<RewardRepository>(),
        GetIt.I<ProgressRepository>(),
      )..loadState(),
      child: const _DailyRewardView(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main view
// ---------------------------------------------------------------------------

class _DailyRewardView extends StatelessWidget {
  const _DailyRewardView();

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.backgroundTop, theme.backgroundBottom],
              ),
            ),
          ),
          // Decorative particle dots
          const _ParticleBackground(),
          // Content
          SafeArea(
            child: BlocBuilder<DailyRewardCubit, DailyRewardCubitState>(
              builder: (context, state) {
                return Column(
                  children: [
                    _buildAppBar(context, theme),
                    Expanded(
                      child: _buildBody(context, theme, state),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  color: theme.textPrimary, size: 20),
            ),
          ),
          const Expanded(
            child: Text(
              'Daily Rewards',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 44), // mirror back button width
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, dynamic theme, DailyRewardCubitState state) {
    if (state is DailyRewardLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    DailyRewardState? rewardData;
    bool canClaim = false;
    bool justClaimed = false;
    DailyReward? claimedReward;

    if (state is DailyRewardAvailable) {
      rewardData = state.rewardState;
      canClaim = true;
    } else if (state is DailyRewardAlreadyClaimed) {
      rewardData = state.rewardState;
    } else if (state is DailyRewardClaimed) {
      rewardData = state.rewardState;
      justClaimed = true;
      claimedReward = state.reward;
    }

    if (rewardData == null) return const SizedBox.shrink();

    final streakDay = rewardData.currentStreakDay;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          // Streak indicator
          _StreakBadge(streakDay: streakDay),
          const SizedBox(height: 28),
          // Weekly calendar
          _WeeklyCalendar(
            currentStreakDay: streakDay,
            claimedToday: !canClaim,
            justClaimedDay: justClaimed ? streakDay : null,
          ),
          const SizedBox(height: 32),
          // Post-claim celebration
          if (justClaimed && claimedReward != null) ...[
            _ClaimCelebration(reward: claimedReward!)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0, duration: 400.ms),
            const SizedBox(height: 24),
          ],
          // Claim button
          _ClaimButton(
            canClaim: canClaim,
            justClaimed: justClaimed,
            streakDay: streakDay,
            onClaim: () =>
                context.read<DailyRewardCubit>().claimReward(),
          ),
          const SizedBox(height: 16),
          // Tomorrow preview
          if (!canClaim || justClaimed) ...[
            _TomorrowPreview(currentStreakDay: streakDay),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak Badge
// ---------------------------------------------------------------------------

class _StreakBadge extends StatelessWidget {
  final int streakDay;
  const _StreakBadge({required this.streakDay});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final hasStreak = streakDay > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: hasStreak
            ? theme.accentColor.withValues(alpha: 0.15)
            : theme.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: hasStreak
              ? theme.accentColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasStreak) ...[
            const Text('🔥', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(
              '$streakDay Day Streak!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: theme.accentColor,
              ),
            ),
          ] else
            Text(
              'Start your streak today!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.04, 1.04),
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}

// ---------------------------------------------------------------------------
// Weekly Calendar
// ---------------------------------------------------------------------------

class _WeeklyCalendar extends StatelessWidget {
  final int currentStreakDay;
  final bool claimedToday;
  final int? justClaimedDay;

  const _WeeklyCalendar({
    required this.currentStreakDay,
    required this.claimedToday,
    this.justClaimedDay,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final dayNumber = i + 1;
          final reward = kDailyRewards[i];
          final isPast = dayNumber < currentStreakDay;
          final isToday = dayNumber == currentStreakDay + (claimedToday ? 0 : 0);
          // isToday = next day to claim, which is currentStreakDay+1 when !claimed
          // or currentStreakDay when just claimed
          final isTodayClaimable = !claimedToday && dayNumber == currentStreakDay + 1;
          final isTodayClaimed = claimedToday && dayNumber == currentStreakDay;
          final isFuture = dayNumber > currentStreakDay + (claimedToday ? 0 : 1);

          return _DayCard(
            dayNumber: dayNumber,
            reward: reward,
            isPast: isPast,
            isClaimable: isTodayClaimable,
            isTodayClaimed: isTodayClaimed,
            isFuture: isFuture,
            isJustClaimed: justClaimedDay == dayNumber,
          ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(
                begin: 0.15,
                end: 0,
                duration: 300.ms,
                curve: Curves.easeOut,
              );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final int dayNumber;
  final DailyReward reward;
  final bool isPast;
  final bool isClaimable;
  final bool isTodayClaimed;
  final bool isFuture;
  final bool isJustClaimed;

  const _DayCard({
    required this.dayNumber,
    required this.reward,
    required this.isPast,
    required this.isClaimable,
    required this.isTodayClaimed,
    required this.isFuture,
    required this.isJustClaimed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;

    final isClaimed = isPast || isTodayClaimed || isJustClaimed;
    final opacity = isFuture ? 0.45 : 1.0;

    Widget card = Opacity(
      opacity: opacity,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isClaimed
              ? Colors.green.withValues(alpha: 0.12)
              : isClaimable
                  ? theme.accentColor.withValues(alpha: 0.15)
                  : theme.cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isClaimable
                ? theme.accentColor
                : isClaimed
                    ? Colors.green.withValues(alpha: 0.6)
                    : theme.cardColor.withValues(alpha: 0.3),
            width: isClaimable ? 2 : 1.5,
          ),
          boxShadow: isClaimable
              ? [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Day $dayNumber',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isClaimed
                    ? Colors.green.shade700
                    : isClaimable
                        ? theme.accentColor
                        : theme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            _rewardIcons(reward),
            const SizedBox(height: 10),
            if (isClaimed)
              const Text('✅', style: TextStyle(fontSize: 20))
            else if (isFuture)
              const Text('🔒', style: TextStyle(fontSize: 18))
            else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (isClaimable) {
      card = card
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 1400.ms, color: theme.accentColor.withValues(alpha: 0.25));
    }

    return card;
  }

  Widget _rewardIcons(DailyReward reward) {
    final items = <String>[];
    if (reward.hints > 0) items.add('💡×${reward.hints}');
    if (reward.extraLives > 0) items.add('❤️×${reward.extraLives}');
    if (reward.undos > 0) items.add('↩️×${reward.undos}');
    if (reward.bulbs > 0) items.add('🌟×${reward.bulbs}');

    return Column(
      children: items
          .map((t) => Text(t, style: const TextStyle(fontSize: 11)))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Claim Button
// ---------------------------------------------------------------------------

class _ClaimButton extends StatelessWidget {
  final bool canClaim;
  final bool justClaimed;
  final int streakDay;
  final VoidCallback onClaim;

  const _ClaimButton({
    required this.canClaim,
    required this.justClaimed,
    required this.streakDay,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final isActive = canClaim && !justClaimed;

    return SizedBox(
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    theme.accentColor,
                    theme.accentColor.withValues(alpha: 0.75),
                  ],
                )
              : null,
          color: isActive ? null : Colors.grey.shade300,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: theme.accentColor.withValues(alpha: 0.45),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: TextButton(
          onPressed: isActive ? onClaim : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Text(
            isActive ? "Claim Today's Reward!" : "Come back tomorrow ✓",
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey.shade600,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tomorrow Preview
// ---------------------------------------------------------------------------

class _TomorrowPreview extends StatelessWidget {
  final int currentStreakDay;
  const _TomorrowPreview({required this.currentStreakDay});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final tomorrowDay = (currentStreakDay % 7) + 1;
    final tomorrow = kDailyRewards[tomorrowDay - 1];

    final parts = <String>[];
    if (tomorrow.hints > 0) parts.add('💡 ${tomorrow.hints} Hint${tomorrow.hints > 1 ? "s" : ""}');
    if (tomorrow.extraLives > 0) parts.add('❤️ ${tomorrow.extraLives} Extra Life');
    if (tomorrow.undos > 0) parts.add('↩️ ${tomorrow.undos} Undo${tomorrow.undos > 1 ? "s" : ""}');
    if (tomorrow.bulbs > 0) parts.add('🌟 ${tomorrow.bulbs} Bulb${tomorrow.bulbs > 1 ? "s" : ""}');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.panelColor.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keep going! Day $tomorrowDay reward tomorrow:',
            style: TextStyle(
              fontSize: 13,
              color: theme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            children: parts
                .map((p) => Text(p, style: TextStyle(fontSize: 14, color: theme.textPrimary, fontWeight: FontWeight.w700)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Claim Celebration
// ---------------------------------------------------------------------------

class _ClaimCelebration extends StatelessWidget {
  final DailyReward reward;
  const _ClaimCelebration({required this.reward});

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final parts = <String>[];
    if (reward.hints > 0) parts.add('💡 +${reward.hints} Hint${reward.hints > 1 ? "s" : ""}');
    if (reward.extraLives > 0) parts.add('❤️ +${reward.extraLives} Extra Life');
    if (reward.undos > 0) parts.add('↩️ +${reward.undos} Undo${reward.undos > 1 ? "s" : ""}');
    if (reward.bulbs > 0) parts.add('🌟 +${reward.bulbs} Bulb${reward.bulbs > 1 ? "s" : ""}');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade400.withValues(alpha: 0.25),
            Colors.green.shade200.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade400.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 600.ms),
          const SizedBox(height: 8),
          Text(
            'Reward Claimed!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 10),
          ...parts.map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                p,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Particle Background Painter
// ---------------------------------------------------------------------------

class _ParticleBackground extends StatelessWidget {
  const _ParticleBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ParticlePainter(color: context.bloomkuTheme.accentColor),
      size: Size.infinite,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Color color;
  _ParticlePainter({required this.color});

  static final _positions = List.generate(28, (i) {
    final rng = math.Random(i * 13 + 7);
    return Offset(rng.nextDouble(), rng.nextDouble());
  });

  static final _sizes =
      List.generate(28, (i) => math.Random(i * 7 + 3).nextDouble() * 5 + 2);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _positions.length; i++) {
      final paint = Paint()
        ..color = color.withValues(alpha: 0.08 + (i % 5) * 0.015)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(_positions[i].dx * size.width, _positions[i].dy * size.height),
        _sizes[i],
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
