import 'package:objectbox/objectbox.dart';

@Entity()
class PlayerProgress {
  @Id()
  int id = 0;

  /// Highest level unlocked on Normal track (1–50)
  int normalHighest = 1;

  /// Highest level unlocked on Hard track (1–50)
  int hardHighest = 16;

  /// Highest level unlocked on Ultra Hard track (1–50)
  int ultraHighest = 31;

  /// Total hints owned
  int hints = 3;

  /// Total extra lives owned
  int extraLives = 2;

  /// Total undos owned
  int undos = 5;

  /// Total bulbs owned
  int bulbs = 1;

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

  /// Whether the remove ads IAP has been purchased
  bool adsRemoved = false;

  /// Total levels completed (for interstitial ad trigger — show every 2)
  int levelsCompletedCount = 0;
}
