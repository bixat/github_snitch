import 'package:flutter/material.dart';

extension RemoveLastLine on String {
  String removeLastLine() {
    int index = lastIndexOf('\n');
    if (index != -1) {
      return substring(0, index);
    }
    return this;
  }
}

extension BuildContextExtension on BuildContext {
  Color get primaryColor => Theme.of(this).primaryColor;
  Color get accentColor => Theme.of(this).colorScheme.secondary;
  Color get backgroundColor => Theme.of(this).colorScheme.background;

  Future push(Widget child) {
    return Navigator.push(
        this,
        MaterialPageRoute(
          builder: (context) => child,
        ));
  }

  void pop() {
    Navigator.pop(this);
  }
}
