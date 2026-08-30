import 'dart:convert';

import 'package:objectbox/objectbox.dart';

import '../models/collection_progress.dart';
import '../../core/constants/app_constants.dart';

class CollectionRepository {
  CollectionRepository(this._box);

  final Box<CollectionProgress> _box;

  CollectionProgress progressFor(String chapterId) {
    for (final progress in _box.getAll()) {
      if (progress.chapterId == chapterId) return progress;
    }
    final progress = CollectionProgress()..chapterId = chapterId;
    _box.put(progress);
    return progress;
  }

  CollectionProgress collect(String chapterId, String objectId) {
    final progress = progressFor(chapterId);
    final ids = _decodeIds(progress.collectedObjectIdsJson);
    if (ids.length >= progress.targetCount) return progress;
    if (!ids.add(objectId)) return progress;
    final sorted = ids.toList()..sort();
    progress.collectedObjectIdsJson = jsonEncode(sorted);
    progress.collectedCount = ids.length;
    progress.chapterCompleted = progress.collectedCount >= progress.targetCount;
    progress.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    _box.put(progress);
    return progress;
  }

  CollectionProgress collectForPuzzle({
    required ChapterDefinition chapter,
    required int levelNumber,
    required PuzzleTrack track,
  }) {
    final chapterOffset = levelNumber - chapter.startLevel;
    final milestone =
        (chapterOffset * chapter.collectibles.length ~/ chapter.levelCount)
            .clamp(0, chapter.collectibles.length - 1);
    final sourceId = track == PuzzleTrack.normal
        ? chapter.collectibles[milestone].id
        : '${track.name}:$levelNumber';
    return collect(chapter.id, sourceId);
  }

  bool claimChapterReward(String chapterId) {
    final progress = progressFor(chapterId);
    if (!progress.chapterCompleted || progress.completionRewardClaimed) {
      return false;
    }
    progress.completionRewardClaimed = true;
    _box.put(progress);
    return true;
  }

  Set<String> _decodeIds(String value) {
    try {
      return (jsonDecode(value) as List<dynamic>).cast<String>().toSet();
    } on FormatException {
      return <String>{};
    } on TypeError {
      return <String>{};
    }
  }
}
