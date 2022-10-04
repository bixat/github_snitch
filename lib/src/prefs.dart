import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static set(String key, String value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString(key, value);
  }

  static setLabel(String key, bool value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool(key, value);
  }

  static Future<bool> getLabel(String key) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    log("${pref.containsKey(key)} hhelo");
    return pref.containsKey(key);
  }

  static Future<String?> get(String key) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(key);
  }

  static Future<bool> checkIfExist(String key) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.containsKey(key);
  }
}
