import 'package:objectbox/objectbox.dart';

/// Restoration/collection progress for one campaign chapter.
@Entity()
class CollectionProgress {
  @Id()
  int id = 0;

  @Unique()
  String chapterId = '';

  String collectedObjectIdsJson = '[]';
  int collectedCount = 0;
  int targetCount = 10;
  bool chapterCompleted = false;
  bool completionRewardClaimed = false;
  int updatedAtMs = 0;
}
