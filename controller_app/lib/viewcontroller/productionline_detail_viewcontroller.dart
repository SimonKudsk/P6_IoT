import '../controller/pasteurization_base.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../model/line.dart';
import '../model/enum/LineStatus.dart';

class ProductionLineDetailViewController {
  final Line line;
  final ColorScheme colorScheme;

  final TextEditingController tempController;
  final TextEditingController amountController;
  final PasteurizationBase service;

  /// View Controller for the ProductionLineDetailScreen
  ProductionLineDetailViewController({
    required this.line,
    required this.colorScheme,
    required this.tempController,
    required this.amountController,
    required this.service,
  });

  /// Check if the line is enabled and available for inputs
  bool get inputsEnabled =>
      line.status == LineStatus.stopped || line.status == LineStatus.error;

  // Status getters for the line
  bool get isFilling => line.status == LineStatus.filling;
  bool get isHeating => line.status == LineStatus.heating;
  bool get isRunning => line.status == LineStatus.running;
  bool get isError => line.status == LineStatus.error;
  bool get isActive => isFilling || isHeating || isRunning;
  bool get canResetError => line.status == LineStatus.error;

  /// Button icon getter, depending on the line status
  IconData get buttonIcon => isActive ? Icons.stop : Icons.play_arrow;

  /// Button label getter, depending on the line status
  String get buttonLabel => isActive ? 'Deactivate' : 'Activate';

  /// Button background color getter, depending on the line status
  Color get buttonBackgroundColor => isActive ? colorScheme.error : colorScheme.primary;

  /// Button foreground color getter, depending on the line status
  Color get buttonForegroundColor => isActive ? colorScheme.onError : colorScheme.onPrimary;

  /// Status color getter, depending on the line status
  Color get statusColor {
    Color color = colorScheme.onSurfaceVariant;
    switch (line.status) {
      case LineStatus.filling:
        color = Colors.blue.shade600;
        break;
      case LineStatus.heating:
        color = Colors.orange.shade700;
        break;
      case LineStatus.stopped:
      case LineStatus.offline:
      case LineStatus.available:
        color = colorScheme.onSurfaceVariant;
        break;
      case LineStatus.error:
        color = colorScheme.error;
        break;
      case LineStatus.running:
        color = Colors.green.shade600;
        break;
    }
    return color;
  }

  /// Get the amount progress on flow or heating
  double? get amountProgress {
    if (line.targetAmount != null &&
        line.targetAmount! > 0 &&
        line.processedAmount != null) {
      return (line.processedAmount! / line.targetAmount!).clamp(0.0, 1.0);
    }
    return null;
  }

  /// Validate temperature input field
  String? validateTemp(String? value) {
    if (!inputsEnabled) return null;
    if (value == null || value.isEmpty) {
      return 'Please enter temperature';
    }
    final temp = double.tryParse(value);
    if (temp == null) return 'Invalid number';
    if (temp < 0 || temp > 150) return 'Temp must be 0-150°C';
    return null;
  }

  /// Validate amount input field
  String? validateAmount(String? value) {
    if (!inputsEnabled) return null;
    if (value == null || value.isEmpty) {
      return 'Please enter amount';
    }
    final normalized = value.replaceAll(',', '.');
    final amount = double.tryParse(normalized);
    if (amount == null) return 'Invalid number';
    if (amount <= 0) return 'Amount must be positive';
    return null;
  }

  /// Initial controller text values
  String get initialTempText =>
      line.targetTemp != null ? line.targetTemp!.toStringAsFixed(1) : '';

  String get initialAmountText =>
      line.targetAmount != null ? line.targetAmount!.toStringAsFixed(1) : '';

  /// Activate the line with the given temperature and amount
  void requestActivation(GlobalKey<FormState> formKey, BuildContext context) {
    if (formKey.currentState?.validate() ?? false) {
      final temp = double.tryParse(tempController.text) ?? 0.0;
      final amount = double.tryParse(amountController.text) ?? 0.0;
      service.activateLine(line.id, temp, amount);
    }
  }

  /// Deactivate the line
  void requestDeactivation() {
    service.deactivateLine(line.id);
  }

  /// Reset error state of the line
  void requestResetError() {
    if (line.name != "Error: Line not found" && line.status == LineStatus.error) {
      service.resetLineError(line.id);
    } else {
      print("Cannot reset error: Line '${line.id}' not found or not in error state.",);
    }
  }
}
