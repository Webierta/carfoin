import 'package:flutter/material.dart';

class PreferencesProvider with ChangeNotifier {
  bool? _storage;

  bool get storage => _storage ?? false;

  set storage(bool value) {
    _storage = value;
    notifyListeners();
  }
}
