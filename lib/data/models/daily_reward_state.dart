import 'package:objectbox/objectbox.dart';

@Entity()
class DailyRewardState {
  @Id()
  int id = 0;

  /// Current streak day (1–7). Resets to 0 if a day is missed.
  int currentStreakDay = 0;

  /// Date string (yyyy-MM-dd) of the last claim. Empty if never claimed.
  String lastClaimDate = '';

  /// Whether today's reward has been claimed
  bool claimedToday = false;

  String lastFreezeUsedDate = '';
}
