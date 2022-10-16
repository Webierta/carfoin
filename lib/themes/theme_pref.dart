import 'package:shared_preferences/shared_preferences.dart';

class ThemePref {
  static const keyThemePref = 'THEME';

  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyThemePref) ?? false;
  }

  setTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(keyThemePref, value);
  }
}
