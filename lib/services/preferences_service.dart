import 'package:carfoin/utils/konstantes.dart';
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
    return true;
  }

  static Future<bool> saveDateExchange(String key, int value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setInt(key, value);
  }

  static Future<int> getDateExchange(String key) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.containsKey(key)) {
      return sharedPreferences.getInt(key) ?? dateExchangeInit;
    }
    return dateExchangeInit;
  }

  static Future<bool> saveRateExchange(String key, double value) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    return await sharedPreferences.setDouble(key, value);
  }

  static Future<double> getRateExchange(String key) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (sharedPreferences.containsKey(key)) {
      return sharedPreferences.getDouble(key) ?? rateExchangeInit;
    }
    return rateExchangeInit;
  }
}
