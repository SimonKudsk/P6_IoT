import 'package:flutter/material.dart';
import '../controller/pasteurization_base.dart';
import '../model/line.dart';
import '../model/enum/LineStatus.dart';

/// ViewController for the Lines screen
class ProductionLinesScreenViewController {
  final PasteurizationBase service;

  ProductionLinesScreenViewController(this.service);

  /// The list of lines to display
  List<Line> get lines => service.lines;

  /// Returns an icon for the given line status
  IconData getStatusIcon(Line line) {
    switch (line.status) {
      case LineStatus.filling:
        return Icons.water_drop_outlined;
      case LineStatus.heating:
        return Icons.thermostat_auto_outlined;
      case LineStatus.stopped:
        return Icons.stop_circle_outlined;
      case LineStatus.offline:
        return Icons.signal_wifi_off;
      case LineStatus.error:
        return Icons.error;
      case LineStatus.running:
        return Icons.play_circle_fill;
      case LineStatus.available:
        return Icons.check_circle_outline;
      }
  }

  /// Returns a color for the given line status
  Color getStatusColor(Line line, ColorScheme colorScheme) {
    switch (line.status) {
      case LineStatus.filling:
        return Colors.blue.shade600;
      case LineStatus.heating:
        return Colors.orange.shade700;
      case LineStatus.stopped:
      case LineStatus.offline:
      case LineStatus.available:
        return colorScheme.onSurfaceVariant;
      case LineStatus.error:
        return colorScheme.error;
      case LineStatus.running:
        return Colors.green.shade600;
      }
  }

  /// Builds the subtitle text for the list tile
  String subtitle(Line line) {
    final amountTarget = line.targetAmount?.toStringAsFixed(1) ?? '-';
    return 'Status: ${line.statusString} | Temp: ${line.displayTemp}°C | '
        'Amount: ${line.displayAmount}/$amountTarget L';
  }

  /// Handles selection logic for tapping a line
  String? computeNewSelection(String? currentSelection, String tappedId, bool isSecondary) {
    if (currentSelection == tappedId && isSecondary) {
      return null;
    }
    return tappedId;
  }
}
