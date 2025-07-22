import 'package:flutter/material.dart';

/// Model that stores the state of the MOWIZ flow.
/// In the future the logic to fetch prices or create tickets can be
/// implemented here without touching the UI widgets.
class MowizModel extends ChangeNotifier {
  String? zone;
  String plate = '';
  int minutes = 0;

  /// Simple placeholder price calculation.
  double get price => minutes * 0.05;

  DateTime get finishTime => DateTime.now().add(Duration(minutes: minutes));

  void selectZone(String value) {
    zone = value;
    notifyListeners();
  }

  void setPlate(String value) {
    plate = value;
    notifyListeners();
  }

  void changeMinutes(int delta) {
    minutes = (minutes + delta).clamp(0, 24 * 60);
    notifyListeners();
  }

  void reset() {
    zone = null;
    plate = '';
    minutes = 0;
    notifyListeners();
  }
}
