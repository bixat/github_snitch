import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static set(String key, String value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString(key, value);
  }

  static remove(String key) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.remove(key);
  }

  static setLabel(String key, bool value) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setBool(key, value);
  }

  static Future<bool> labelExist(String key) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.containsKey(key);
  }

  static Future<String?> get(String key) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getString(key);
  }

  static Future<Set<String>> getKeys() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.getKeys();
  }

  static Future<bool> checkIfExist(String key) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    return pref.containsKey(key);
  }
}
