import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persists the time the application is actually in the foreground.
///
/// A record is closed whenever the app is paused or detached, so time while
/// the device is locked or the user is in another app is not counted.
class UsageTrackingService {
  UsageTrackingService._();

  static final UsageTrackingService instance = UsageTrackingService._();

  static const _totalActiveSecondsKey = 'total_active_seconds';
  static const _sessionsKey = 'usage_sessions';
  static const _maxStoredSessions = 200;

  DateTime? _activePeriodStartedAt;

  Future<void> initialize() async {
    // A previous process may have been killed without a lifecycle callback.
    // Do not count the elapsed time since then as active app time.
    _activePeriodStartedAt = null;
    await resume();
  }

  Future<void> resume() async {
    _activePeriodStartedAt ??= DateTime.now();
  }

  Future<void> pause() async {
    final startedAt = _activePeriodStartedAt;
    if (startedAt == null) return;

    final endedAt = DateTime.now();
    _activePeriodStartedAt = null;
    final durationSeconds = endedAt.difference(startedAt).inSeconds;
    if (durationSeconds <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final total = prefs.getInt(_totalActiveSecondsKey) ?? 0;
    await prefs.setInt(_totalActiveSecondsKey, total + durationSeconds);

    final sessions = _readSessions(prefs);
    sessions.add({
      'id': const Uuid().v4(),
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'activeSeconds': durationSeconds,
    });
    final retainedSessions = sessions.length > _maxStoredSessions
        ? sessions.sublist(sessions.length - _maxStoredSessions)
        : sessions;
    await prefs.setString(_sessionsKey, jsonEncode(retainedSessions));
  }

  Future<int> getTotalActiveSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalActiveSecondsKey) ?? 0;
  }

  List<Map<String, dynamic>> _readSessions(SharedPreferences prefs) {
    final raw = prefs.getString(_sessionsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
