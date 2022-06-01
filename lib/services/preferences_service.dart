import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static Future<bool> saveBool(String key, bool value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setBool(key, value);
  }

  static Future<bool> getBool(String key) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.containsKey(key)) {
      return sharedPreferences.getBool(key) ?? true;
    }
    return false;
  }
}
