import 'package:objectbox/objectbox.dart';

@Entity()
class DailyChallengeState {
  @Id()
  int id = 0;

  /// Date string (yyyy-MM-dd, local time) of the last completion.
  String lastCompletedDate = '';

  int currentChallengeStreak = 0;
  int longestChallengeStreak = 0;
  int totalChallengesCompleted = 0;
}
