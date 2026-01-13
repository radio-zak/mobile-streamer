import 'package:shared_preferences/shared_preferences.dart';

class StatisticsRepository {
  static const _installDateKey = 'install_date';
  static const _totalListeningTimeKey = 'total_listening_time';
  static const _longestSessionKey = 'longest_session';
  static const _shortestSessionKey = 'shortest_session';
  static const _weekdayListeningKey = 'weekday_listening';

  Future<void> saveInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_installDateKey)) {
      await prefs.setString(_installDateKey, DateTime.now().toIso8601String());
    }
  }

  Future<DateTime?> getInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_installDateKey);
    return dateString != null ? DateTime.parse(dateString) : null;
  }

  Future<void> saveTotalListeningTime(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalListeningTimeKey, seconds);
  }

  Future<int> getTotalListeningTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalListeningTimeKey) ?? 0;
  }

  Future<void> saveLongestSession(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_longestSessionKey, seconds);
  }

  Future<int> getLongestSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_longestSessionKey) ?? 0;
  }

  Future<void> saveShortestSession(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_shortestSessionKey, seconds);
  }

  Future<int> getShortestSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_shortestSessionKey) ?? 0;
  }

  Future<void> saveWeekdayListening(Map<int, int> weekdayData) async {
    final prefs = await SharedPreferences.getInstance();
    final stringData = weekdayData.map((key, value) => MapEntry(key.toString(), value.toString()));
    // SharedPreferences doesn't support saving maps directly, so we convert it to a list of strings
    final list = stringData.entries.map((e) => '${e.key}:${e.value}').toList();
    await prefs.setStringList(_weekdayListeningKey, list);
  }

  Future<Map<int, int>> getWeekdayListening() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_weekdayListeningKey);
    if (list == null) return {};
    return Map.fromEntries(list.map((e) {
      final parts = e.split(':');
      return MapEntry(int.parse(parts[0]), int.parse(parts[1]));
    }));
  }
}
