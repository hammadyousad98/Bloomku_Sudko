import 'package:objectbox/objectbox.dart';

/// Current small session objective and its unclaimed reward.
@Entity()
class SessionGoalState {
  @Id()
  int id = 0;

  String goalId = '';
  String goalType = '';
  int target = 0;
  int progress = 0;
  String rewardType = '';
  int rewardAmount = 0;
  int collectionRewardProgress = 0;
  bool completed = false;
  bool rewardClaimed = false;
  int startedAtMs = 0;
  int expiresAtMs = 0;
  String qualifyingPuzzleIdsJson = '[]';
}
