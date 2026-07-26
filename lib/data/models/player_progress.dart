import 'package:objectbox/objectbox.dart';

@Entity()
class PlayerProgress {
  @Id()
  int id = 0;

  /// Next playable level on Normal track (1-50, or 51 when complete)
  int normalHighest = 1;

  /// Next playable level on Hard track (1-50, or 51 when complete)
  int hardHighest = 16;

  /// Next playable level on Ultra Hard track (1-50, or 51 when complete)
  int ultraHighest = 31;

  /// Total hints owned
  int hints = 5;

  /// Total extra lives owned
  int extraLives = 2;

  /// Total undos owned
  int undos = 5;

  /// Total bulbs owned
  int bulbs = 5;

  /// Has the main tutorial been seen?
  bool tutorialSeen = false;

  /// Level number where the last rule tutorial was shown (to avoid repeat)
  int lastRuleTutorialLevel = 0;

  /// Whether the diagonal rule tutorial has been shown
  bool diagonalRuleSeen = false;

  /// Whether the min-distance rule tutorial has been shown
  bool minDistanceRuleSeen = false;

  /// Whether the knight-move rule tutorial has been shown
  bool knightMoveRuleSeen = false;

  /// Whether the landmine rule tutorial has been shown
  bool mineRuleSeen = false;

  bool rowColumnRuleSeen = false;
  bool colorRegionRuleSeen = false;
  bool noTouchRuleSeen = false;

  /// Master ad-removal switch. When true, all ads are suppressed: both Game
  /// banner placements and the interstitial gate in GameCubit._onLevelComplete.
  ///
  /// Normally flipped by the Remove Ads IAP flow in IapService and Settings'
  /// _PurchasesSection. For testing, load progress through ProgressRepository,
  /// edit this field, then call ProgressRepository.saveProgress(...).
  bool adsRemoved = false;

  /// Total levels completed (for interstitial ad trigger — show every 2)
  int levelsCompletedCount = 0;
}
