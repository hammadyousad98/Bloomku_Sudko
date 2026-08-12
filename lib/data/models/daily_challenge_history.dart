import 'package:objectbox/objectbox.dart';

/// One durable result per local calendar date (`yyyy-MM-dd`).
@Entity()
class DailyChallengeHistory {
  @Id()
  int id = 0;

  @Unique()
  String dateKey = '';

  bool completed = false;
  int bestTimeMs = 0;
  int bestScore = 0;
  int lowestMistakes = 0;
  int streakAtCompletion = 0;
  String shareGridData = '';
  int completionCount = 0;
  int firstCompletedAtMs = 0;
  int lastCompletedAtMs = 0;
}
