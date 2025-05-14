import '../controller/pasteurization_base.dart';
import 'package:flutter/foundation.dart';

/// Persisted app‑wide settings.
class AppSettings extends ChangeNotifier {
  bool _useSimulation = false;

  bool get useSimulation => _useSimulation;

  set useSimulation(bool value) {
    if (value == _useSimulation) return;
    _useSimulation = value;
    notifyListeners();
  }
}
