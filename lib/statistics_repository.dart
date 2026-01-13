import 'package:shared_preferences/shared_preferences.dart';

class StatisticsRepository {
  static const _installDateKey = 'install_date';

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
}
