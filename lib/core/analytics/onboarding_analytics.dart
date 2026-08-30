import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingAnalytics {
  OnboardingAnalytics(this._preferences);

  final SharedPreferences _preferences;

  static const _eventLogKey = 'analytics.onboarding.events';
  static const _startKey = 'analytics.onboarding.started_at_ms';

  void record(String event, {Map<String, Object?> metadata = const {}}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (!_preferences.containsKey(_startKey)) {
      _preferences.setInt(_startKey, now);
    }
    final startedAt = _preferences.getInt(_startKey) ?? now;
    final entries = _readEntries()
      ..add({
        'event': event,
        'timestampMs': now,
        'elapsedMs': now - startedAt,
        if (metadata.isNotEmpty) 'metadata': metadata,
      });
    if (entries.length > 120) entries.removeRange(0, entries.length - 120);
    _preferences.setString(_eventLogKey, jsonEncode(entries));
    _preferences.setInt('analytics.onboarding.$event.last_ms', now);
    debugPrint('onboarding_analytics: $event elapsed=${now - startedAt}ms');
  }

  void recordOnce(String event, {Map<String, Object?> metadata = const {}}) {
    final key = 'analytics.onboarding.$event.first_ms';
    if (_preferences.containsKey(key)) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    _preferences.setInt(key, now);
    record(event, metadata: metadata);
  }

  List<Map<String, Object?>> get events => List.unmodifiable(_readEntries());

  List<Map<String, Object?>> _readEntries() {
    final encoded = _preferences.getString(_eventLogKey);
    if (encoded == null) return [];
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map((entry) => Map<String, Object?>.from(entry as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
