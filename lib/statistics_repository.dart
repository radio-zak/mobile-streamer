import 'package:shared_preferences/shared_preferences.dart';

class StatisticsRepository {
  static const _installDateKey = 'install_date';
  static const _totalListeningTimeKey = 'total_listening_time';

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
}
