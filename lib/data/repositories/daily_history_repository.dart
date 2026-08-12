import 'package:intl/intl.dart';
import 'package:objectbox/objectbox.dart';

import '../models/daily_challenge_history.dart';

class DailyHistoryRepository {
  DailyHistoryRepository(this._box);

  final Box<DailyChallengeHistory> _box;

  static String dateKey(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date.toLocal());

  DailyChallengeHistory? resultForDate(DateTime date) {
    final key = dateKey(date);
    for (final result in _box.getAll()) {
      if (result.dateKey == key) return result;
    }
    return null;
  }

  List<DailyChallengeHistory> resultsForMonth(int year, int month) {
    final prefix = '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}-';
    final results = _box.getAll()
      ..removeWhere((result) => !result.dateKey.startsWith(prefix))
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    return results;
  }

  DailyChallengeHistory recordCompletion({
    required DateTime date,
    required int elapsedMs,
    required int score,
    required int mistakes,
    required int streak,
    required String shareGridData,
  }) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final result = resultForDate(date) ??
        (DailyChallengeHistory()
          ..dateKey = dateKey(date)
          ..firstCompletedAtMs = nowMs);
    result.completed = true;
    result.completionCount += 1;
    if (elapsedMs > 0 &&
        (result.bestTimeMs == 0 || elapsedMs < result.bestTimeMs)) {
      result.bestTimeMs = elapsedMs;
      result.shareGridData = shareGridData;
    } else if (result.shareGridData.isEmpty) {
      result.shareGridData = shareGridData;
    }
    if (score > result.bestScore) result.bestScore = score;
    if (result.completionCount == 1 || mistakes < result.lowestMistakes) {
      result.lowestMistakes = mistakes;
    }
    result.streakAtCompletion = streak;
    result.lastCompletedAtMs = nowMs;
    _box.put(result);
    return result;
  }
}
