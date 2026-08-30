import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/collection_repository.dart';
import '../../data/repositories/game_results_repository.dart';
import '../../data/repositories/progress_repository.dart';

class ChapterMapScreen extends StatefulWidget {
  const ChapterMapScreen({super.key});

  @override
  State<ChapterMapScreen> createState() => _ChapterMapScreenState();
}

class _ChapterMapScreenState extends State<ChapterMapScreen> {
  late final ProgressRepository _progress = GetIt.I<ProgressRepository>();
  late final GameResultsRepository _results = GetIt.I<GameResultsRepository>();
  late final CollectionRepository _collections =
      GetIt.I<CollectionRepository>();

  Future<void> _openLevel(int level) async {
    await context.push(
      '/game',
      extra: {'level': level, 'track': 'normal'},
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final progress = _progress.getProgress();
    final unlockedChapters = _progress.unlockedChapterIds();

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.backgroundTop, theme.backgroundBottom],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: theme.backgroundTop.withValues(alpha: 0.94),
                foregroundColor: theme.textPrimary,
                title: const Text(
                  'Chapter Journey',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        '⭐ ${_results.totalCampaignStars()}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverList.separated(
                  itemCount: campaignChapters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (context, index) {
                    final chapter = campaignChapters[index];
                    return _ChapterCard(
                      chapter: chapter,
                      unlocked: unlockedChapters.contains(chapter.id),
                      normalHighest: progress.normalHighest,
                      normalStars: _results.totalStarsForChapter(
                        chapter,
                        includeAlternativeTracks: false,
                      ),
                      allStars: _results.totalStarsForChapter(chapter),
                      collected:
                          _collections.progressFor(chapter.id).collectedCount,
                      starsForLevel: (level) => _results.starsForLevel(level),
                      onLevelTap: _openLevel,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({
    required this.chapter,
    required this.unlocked,
    required this.normalHighest,
    required this.normalStars,
    required this.allStars,
    required this.collected,
    required this.starsForLevel,
    required this.onLevelTap,
  });

  final ChapterDefinition chapter;
  final bool unlocked;
  final int normalHighest;
  final int normalStars;
  final int allStars;
  final int collected;
  final int Function(int level) starsForLevel;
  final ValueChanged<int> onLevelTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    final maxNormalStars = chapter.levelCount * 3;

    return AnimatedOpacity(
      opacity: unlocked ? 1 : 0.6,
      duration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: theme.accentColor.withValues(alpha: unlocked ? 0.25 : 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: theme.accentColor.withValues(alpha: 0.14),
                  child: unlocked
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            chapter.pathArtAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Text(
                              chapter.pathEmoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        )
                      : const Icon(Icons.lock_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.name,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        unlocked
                            ? 'Levels ${chapter.startLevel}–${chapter.endLevel}'
                            : 'Complete the previous chapter to unlock',
                        style: TextStyle(color: theme.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (unlocked)
                  Text(
                    '⭐ $normalStars/$maxNormalStars',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            if (unlocked) ...[
              const SizedBox(height: 16),
              _CollectibleStrip(chapter: chapter, collected: collected),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 14,
                children: [
                  for (var level = chapter.startLevel;
                      level <= chapter.endLevel;
                      level++)
                    _LevelNode(
                      level: level,
                      unlocked: level <= normalHighest,
                      current: level == normalHighest,
                      stars: starsForLevel(level),
                      onTap: () => onLevelTap(level),
                    ),
                ],
              ),
              if (allStars > normalStars) ...[
                const SizedBox(height: 14),
                Text(
                  '+${allStars - normalStars} bonus stars from Hard and Ultra Hard',
                  style: TextStyle(
                    color: theme.accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Chapter reward: ${chapter.completionReward.label}',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectibleStrip extends StatelessWidget {
  const _CollectibleStrip({required this.chapter, required this.collected});

  final ChapterDefinition chapter;
  final int collected;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restoration $collected/${chapter.collectibles.length}',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < chapter.collectibles.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i < collected
                            ? theme.accentColor.withValues(alpha: 0.18)
                            : theme.panelColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          i < collected ? chapter.collectibles[i].emoji : '·',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.unlocked,
    required this.current,
    required this.stars,
    required this.onTap,
  });

  final int level;
  final bool unlocked;
  final bool current;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.bloomkuTheme;
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: current
                  ? theme.accentColor
                  : unlocked
                      ? theme.panelColor
                      : theme.textSecondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: current
                    ? Colors.white
                    : theme.accentColor.withValues(alpha: 0.25),
                width: current ? 3 : 1,
              ),
              boxShadow: current
                  ? [
                      BoxShadow(
                        color: theme.accentColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: unlocked
                  ? Text(
                      '$level',
                      style: TextStyle(
                        color: current ? Colors.white : theme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Icon(Icons.lock_rounded,
                      size: 18, color: theme.textSecondary),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            List.generate(3, (i) => i < stars ? '★' : '☆').join(),
            style: TextStyle(
              color: stars > 0 ? Colors.amber.shade700 : theme.textSecondary,
              fontSize: 10,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}
