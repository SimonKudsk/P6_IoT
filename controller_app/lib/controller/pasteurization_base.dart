import 'package:flutter/foundation.dart';

import '../model/enum/LineStatus.dart';
import '../model/line.dart';
import 'pasteurization_controller.dart'; // provides the Line class & statuses

/// Common interface for both simulation and MQTT interactions.
abstract class PasteurizationBase extends ChangeNotifier {
  /// List all production lines (updated via notifyListeners).
  List<Line> get lines;

  /// Default implementation to retrieve a line by its ID.
  @protected
  Line? getLineById(String id) {
    try {
      return lines.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Begin a new job on the given line.
  void activateLine(String lineId, double temp, double amount);

  /// Stop the current job on the given line, if any.
  void deactivateLine(String lineId);

  /// Default implementation to reset a line in error state.
  @protected
  void resetLineError(String lineId) {
    final line = getLineById(lineId);
    if (line?.status == LineStatus.error) {
      line!.status = LineStatus.stopped;
      line.errorMsg = null;
      notifyListeners();
    }
  }
}