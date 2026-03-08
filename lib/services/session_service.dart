import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static Future<void> saveSession(String email, String teamId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool("loggedIn", true);
    await prefs.setString("email", email);
    await prefs.setString("teamId", teamId);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("loggedIn") ?? false;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> getSession() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "email": prefs.getString("email"),
      "teamId": prefs.getString("teamId"),
    };
  }
}
