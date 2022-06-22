import 'package:shared_preferences/shared_preferences.dart';

const String keyByOrderCarterasPref = 'isByOrderCarteras';
const String keyConfirmDeleteCarteraPref = 'isConfirmDeleteCartera';
const String keyByOrderFondosPref = 'isByOrderFondos';
const String keyConfirmDeleteFondoPref = 'isConfirmDeleteFondo';
const String keyAutoUpdatePref = 'isAutoAudate';
const String keyConfirmDeletePref = 'isConfirmDelete';

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
    return true;
  }
}
