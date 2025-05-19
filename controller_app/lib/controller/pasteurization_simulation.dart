import 'dart:async';
import 'dart:math';
import '../model/enum/LineStatus.dart';
import '../model/line.dart';
import 'pasteurization_base.dart';

class PasteurizationSimulation extends PasteurizationBase {
  final List<Line> _lines = [
    Line(id: 'line_a', name: 'Line A', currentTemp: 20.0),
    Line(id: 'line_b', name: 'Line B', currentTemp: 20.0),
    Line(id: 'line_c', name: 'Line C', currentTemp: 20.0),
  ];

  @override
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


// Activate line
  @override
  void activateLine(String lineId, double temp, double amount) {
    // Check if already disposed
    if (_isDisposed) return;

    // Check if line exists
    final line = getLineById(lineId);
    if (line == null) return;

    // Check if line is already in use - if not, start it
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
  }

// Deactivate line
  @override
  void deactivateLine(String lineId) {
    // Check if already stopped
    if (_isDisposed) return;
    final line = getLineById(lineId);

    // Check if line exists
    if (line == null) return;

    // Stop line if running
    if (line.status != LineStatus.stopped) {
      print("Deactivating ${line.name} (Status was ${line.statusString}).");
      line.status = LineStatus.stopped;
      notifyListeners();
    }
  }

// --- Data Simulation Loop ---
  void _startSimulation() {
    if (_simulationTimer != null && _simulationTimer!.isActive) return;

    // Start simulation timer
    _simulationTimer = Timer.periodic(_simulationInterval, (timer) {
      // Check if stopped
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      // Simulate each line
      bool changed = false; // Track if any state changed to notify listeners
      for (var line in _lines) {
        // Skip if line is not in use
        double? previousTemp = line.currentTemp;
        LineStatus previousStatus = line.status;
        double? previousAmount = line.processedAmount;

        final double timeDelta = _simulationInterval.inMilliseconds / 1000.0;

        switch (line.status) {
        /// Filling phase
          case LineStatus.filling:
            _simulateFilling(line, timeDelta);
            break;
        /// Heating phase
          case LineStatus.heating:
            _simulateHeating(line, timeDelta);
            break;
        /// Offline
          case LineStatus.offline:
          // Simulate offline state
            line.currentTemp = null;
            line.processedAmount = null;
            break;
        /// Error / stop state
          case LineStatus.stopped:
          case LineStatus.error:
            _simulateCooling(line, timeDelta);
            break;
          case LineStatus.running:
            line.status = LineStatus.stopped;
            changed = true;
            break;
          case LineStatus.available:
            line.status = LineStatus.available;
        }

        // --- Max temperature ---
        _maxTemperature(line);

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

  // --- Helper Functions for Simulation Phases ---
  /// Generates a random fill rate between min and max.
  double _generateFillRate() {
    final range = _fillRateMaxLitersPerSec - _fillRateMinLitersPerSec;
    return _fillRateMinLitersPerSec + _random.nextDouble() * range;
  }

  /// Simulates the filling phase for a line.
  void _simulateFilling(Line line, double timeDelta) {
    if ((line.processedAmount ?? 0) < (line.targetAmount ?? 0)) {
      final fillRate = _generateFillRate();
      final amountToAdd = fillRate * timeDelta;
      line.processedAmount = (line.processedAmount ?? 0) + amountToAdd;
      line.processedAmount =
          min(line.processedAmount!, line.targetAmount ?? line.processedAmount!);
      // Check if filling is complete
      if (line.targetAmount != null && line.processedAmount! >= line.targetAmount!) {
        line.status = LineStatus.heating;
        print("${line.name}: Filling complete (${line.processedAmount?.toStringAsFixed(1)}L). Starting heating.");
      }
    } else {
      line.status = LineStatus.heating;
    }
  }

  /// Simulates the heating phase for a line.
  void _simulateHeating(Line line, double timeDelta) {
    if (line.currentTemp != null && line.targetTemp != null && line.currentTemp! < line.targetTemp!) {
      final tempDiff = line.targetTemp! - line.currentTemp!;
      if (tempDiff.abs() <= _completionThreshold) {
        line.currentTemp = line.targetTemp;
        line.status = LineStatus.stopped;
        print("${line.name}: Heating complete (Reached ${line.currentTemp?.toStringAsFixed(1)}°C). Process finished.");
      } else {
        final tempChange = tempDiff * _heatingFactor * timeDelta;
        line.currentTemp = (line.currentTemp ?? 0) + tempChange;
      }
    } else {
      line.currentTemp = line.targetTemp;
      line.status = LineStatus.stopped;
      print("${line.name}: Already at/above target temp (${line.currentTemp?.toStringAsFixed(1)}°C). Finishing.");
    }
  }

  /// Simulates cooling towards ambient temperature for a line.
  void _simulateCooling(Line line, double timeDelta) {
    if (line.currentTemp != null && (line.currentTemp! - ambientTemp).abs() > 0.1) {
      final tempDiff = ambientTemp - line.currentTemp!;
      final tempChange = tempDiff * _coolingFactor * timeDelta;
      line.currentTemp = (line.currentTemp ?? 0) + tempChange;
      if ((tempChange > 0 && line.currentTemp! > ambientTemp) ||
          (tempChange < 0 && line.currentTemp! < ambientTemp)) {
        line.currentTemp = ambientTemp;
      }
    } else if (line.currentTemp != null && line.currentTemp != ambientTemp) {
      line.currentTemp = ambientTemp;
    }
  }

  /// Sets the limit of line temperature to a maximum of 150 degrees
  void _maxTemperature(Line line) {
    if (line.currentTemp != null) {
      line.currentTemp = line.currentTemp!.clamp(0.0, 150.0);
    }
  }
}