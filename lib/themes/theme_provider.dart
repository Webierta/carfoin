import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  late bool _darkTheme;

  ThemeProvider({bool themePref = false}) {
    _darkTheme = themePref;
  }

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    notifyListeners();
  }
}
