import 'dart:async';       // For Timer
import 'dart:math';         // For Random and min/max functions
import 'package:flutter/foundation.dart'; // For ChangeNotifier



enum LineStatus { stopped, running, filling, heating, error }

class Line {
  final String id;
  String name;
  LineStatus status;
  double targetTemp;
  double targetAmount;
  double currentTemp;
  double processedAmount;

  Line({
    required this.id,
    required this.name,
    this.status = LineStatus.stopped,
    this.targetTemp = 72.0,
    this.targetAmount = 0.0,
    this.currentTemp = 10.0,
    this.processedAmount= 0.0,
});

  String get statusString {
    switch (status) {
      case LineStatus.stopped: return "Stopped";
      case LineStatus.running: return "Running";
      case LineStatus.filling: return "Filling";
      case LineStatus.heating: return "Heating";
      case LineStatus.error: return "Error";

    }
  }
}

class PasteurizationSimulation extends ChangeNotifier {
  final List<Line> _lines = [
    Line(id: 'line_a', name: 'Line A', currentTemp: 20.0),//example of added starting temp
    Line(id: 'line_b', name: 'Line B', currentTemp: 20.0),
    Line(id: 'line_c', name: 'Line C', currentTemp: 20.0),
  ];

  List<Line> get lines => List.unmodifiable(_lines);

  Timer? _simulationTimer;
  final Random _random = Random();
  bool _isDisposed = false;

  // --- Simulation Parameters ---
  final double ambientTemp = 20.0;        // Ambient temperature for cooling
  final double _coolingFactor = 0.05;     // How quickly lines cool down
  final double _heatingFactor = 0.15;     // How quickly lines heat up
  final double _completionThreshold = 0.2; // Temp difference threshold to consider heating complete
  final double _fillRateMinLitersPerSec = 5.0;
  final double _fillRateMaxLitersPerSec = 15.0;
  final Duration _simulationInterval = const Duration(seconds: 1);



  PasteurizationSimulation() {
    _startSimulation();
  }
  @override
  void dispose() {
    _isDisposed = true;
    print("Disposing PasteurizationSimulation...");
    _simulationTimer?.cancel();
    super.dispose();
  }

  Line getLineById(String id) {
    try {
      return _lines.firstWhere((line) => line.id == id);
    } catch (e) {
      print("Error: Line with ID $id not found.");

      return Line(
          id: id,
          name: "Error: Line not found",
          status: LineStatus.error,
          currentTemp: 0.0,
          targetTemp: 0.0,
          targetAmount: 0.0,
          processedAmount: 0.0
      );
    }
  }


// Activate line
  void activateLine(String lineId, double temp, double amount) {
    if (_isDisposed) return;
    try {
      final line = getLineById(lineId);
      if (line.name == "Error: Line not found") return;

      if (line.status == LineStatus.stopped || line.status == LineStatus.error) {
        line.targetTemp = temp;
        line.targetAmount = amount;
        line.processedAmount = 0;
        line.status = LineStatus.filling;
        print("Activated ${line.name}: Target ${amount}L, ${temp}C. Starting fill.");
        notifyListeners();
      } else {
        print("Cannot activate ${line.name}: Already in progress (Status: ${line.statusString}).");
      }
    } catch (e) {
      print("Error activating line $lineId: $e");
    }
  }

// Deactivate line
  void deactivateLine(String lineId) {
    if (_isDisposed) return;
    try {
      final line = getLineById(lineId);
      if (line.name == "Error: Line not found") return;

      if (line.status != LineStatus.stopped) {
        print("Deactivating ${line.name} (Status was ${line.statusString}).");
        line.status = LineStatus.stopped;
        notifyListeners();
      }
    } catch (e) {
      print("Error deactivating line $lineId: $e");
    }
  }

// Reset Error Method
  void resetLineError(String lineId) {
    if (_isDisposed) return;
    final line = getLineById(lineId);

    if (line.name != "Error: Line not found" &&
        line.status == LineStatus.error) {
      print("Resetting error state for ${line.name}.");
      line.status = LineStatus.stopped;
      notifyListeners();
    } else if (line.name != "Error: Line not found") {
      print("Line ${line.name} is not in an error state. Cannot reset error.");
    }
  }


// --- Data Simulation Loop ---
  void _startSimulation() {
    if (_simulationTimer != null && _simulationTimer!.isActive) return;

    _simulationTimer = Timer.periodic(_simulationInterval, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      bool changed = false; // Track if any state changed to notify listeners
      for (var line in _lines) {
        double previousTemp = line.currentTemp; // Store previous state for change detection
        LineStatus previousStatus = line.status;
        double previousAmount = line.processedAmount;


        final double timeDelta = _simulationInterval.inMilliseconds / 1000.0;

        switch (line.status) {
          case LineStatus.filling:
            if (line.processedAmount < line.targetAmount) {

              double fillRateRange = _fillRateMaxLitersPerSec - _fillRateMinLitersPerSec;
              double currentFillRate = _fillRateMinLitersPerSec + _random.nextDouble() * fillRateRange;
              double amountToAdd = currentFillRate * timeDelta;

              line.processedAmount += amountToAdd;
              line.processedAmount = min(line.processedAmount, line.targetAmount);

              // Check if filling is complete
              if (line.processedAmount >= line.targetAmount) {
                line.status = LineStatus.heating;
                print("${line.name}: Filling complete (${line.processedAmount.toStringAsFixed(1)}L). Starting heating.");
              }
            } else {

              line.status = LineStatus.heating;
            }
            break;

          case LineStatus.heating:
            if (line.currentTemp < line.targetTemp) {
              double tempDiff = line.targetTemp - line.currentTemp;

              // Check if close enough to target
              if (tempDiff.abs() <= _completionThreshold) {
                line.currentTemp = line.targetTemp;
                line.status = LineStatus.stopped;
                print("${line.name}: Heating complete (Reached ${line.currentTemp.toStringAsFixed(1)}°C). Process finished.");
              } else {

                double tempChange = tempDiff * _heatingFactor * timeDelta;
                line.currentTemp += tempChange;
              }
            } else {
              // Already at or above target temp
              line.currentTemp = line.targetTemp;
              line.status = LineStatus.stopped;
              print("${line.name}: Already at/above target temp (${line.currentTemp.toStringAsFixed(1)}°C). Finishing.");
            }
            break;

          case LineStatus.stopped:
          case LineStatus.error:
          // Cool down towards ambient temperature
            if ((line.currentTemp - ambientTemp).abs() > 0.1) {
              double tempDiff = ambientTemp - line.currentTemp;
              double tempChange = tempDiff * _coolingFactor * timeDelta;
              line.currentTemp += tempChange;

              if ((tempChange > 0 && line.currentTemp > ambientTemp) || (tempChange < 0 && line.currentTemp < ambientTemp)) {
                line.currentTemp = ambientTemp;
              }
            } else if (line.currentTemp != ambientTemp) {
              line.currentTemp = ambientTemp;
            }
            break;
          case LineStatus.running:
            line.status = LineStatus.stopped;
        changed = true;
        break;
        }

        // --- Clamp Temperature (Safety Net) ---
        line.currentTemp = line.currentTemp.clamp(0.0, 150.0);

        // --- Check if anything actually changed for this line ---
        if (line.currentTemp != previousTemp ||
            line.status != previousStatus ||
            line.processedAmount != previousAmount) {
          changed = true;
        }

      }

      // Notify UI only if any line's state actually changed during this tick
      if (changed && !_isDisposed) {
        notifyListeners();
      }
    });
  }
}