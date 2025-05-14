import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../model/enum/LineStatus.dart';
import '../model/line.dart';
import '../controller/pasteurization_base.dart';

class ProductionLineDetailScreen extends StatefulWidget {
  static const routeName = '/line-detail';
  final String lineId;

  const ProductionLineDetailScreen({super.key, required this.lineId});

  @override
  State<ProductionLineDetailScreen> createState() =>
      _ProductionLineDetailScreenState();
}

class _ProductionLineDetailScreenState
    extends State<ProductionLineDetailScreen> {
  // Controllers, keys, state variables...
  final _tempController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _controllersInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize controllers based on the *initial* line data
    // We only do this if they haven't been initialized yet to avoid
    // overriding user input if the widget rebuilds.
    if (!_controllersInitialized) {
      final simulation =
          context.read<PasteurizationBase>();
      final line = simulation.getLineById(widget.lineId);
      if (line?.name != "Error: Line not found") {

        _tempController.text =
            line!.targetTemp != null ? line.targetTemp!.toStringAsFixed(1) : '';
        _amountController.text =
            line.targetAmount != null ? line.targetAmount!.toStringAsFixed(1) : '';
        _controllersInitialized = true;
      }
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Action methods interacting with the service
  void _requestActivation(BuildContext context) {
    // Pass context if needed outside build
    if (_formKey.currentState?.validate() ?? false) {
      final temp = double.tryParse(_tempController.text) ?? 0.0;
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      // Use context.read for actions inside callbacks
      context.read<PasteurizationBase>().activateLine(
        widget.lineId,
        temp,
        amount,
      );
    }
  }

  void _requestDeactivation(BuildContext context) {
    // Pass context if needed outside build
    // Use context.read for actions inside callbacks
    context.read<PasteurizationBase>().deactivateLine(widget.lineId);
  }

  void _resetError(BuildContext context, Line line) {
    // Pass context and line data
    // Use context.read for actions inside callbacks
    final service = context.read<PasteurizationBase>();
    if (line.name != "Error: Line not found" &&
        line.status == LineStatus.error) {
      service.resetLineError(widget.lineId);

      if (!mounted) return;
    } else {
      print(
        "Cannot reset error: Line '${widget.lineId}' not found or not in error state.",
      );

      if (!mounted) return;
    }
  }

  // Build method for Detail Screen
  @override
  Widget build(BuildContext context) {
    final simulation = context.watch<PasteurizationBase>();
    final line = simulation.getLineById(widget.lineId);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Handle case where the line ID might be invalid
    if (line?.name == "Error: Line not found" || line == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: const Center(child: Text("Line details not found.")),
      );
    }
    // --- Determine Control States ---
    // Inputs should only be enabled when the line is ready for activation
    final bool inputsEnabled =
        line!.status == LineStatus.stopped || line.status == LineStatus.error;
    // Determine if the line is currently in any active state for progress bar
    final bool isFilling = line.status == LineStatus.filling;
    final bool isHeating = line.status == LineStatus.heating;
    final bool isRunning = line.status == LineStatus.running;
    final bool isError = line.status == LineStatus.error;
    final bool isActive =
        isFilling || isHeating || isRunning; // Combined active states

    // Determine if the reset error button should be shown
    final bool canResetError = line.status == LineStatus.error;

    // Button Properties
    IconData buttonIcon;
    String buttonLabel;
    Color buttonBackgroundColor;
    Color buttonForegroundColor;
    VoidCallback buttonAction;

    if (isActive) {
      // If line is active button should be for Deactivation
      buttonIcon = Icons.stop;
      buttonLabel = 'Deactivate';
      buttonBackgroundColor = colorScheme.error;
      buttonForegroundColor = colorScheme.onError;
      buttonAction = () => _requestDeactivation(context);
    } else {
      // If line is stopped button should be for Activation
      buttonIcon = Icons.play_arrow;
      buttonLabel = 'Activate';
      buttonBackgroundColor = colorScheme.primary;
      buttonForegroundColor = colorScheme.onPrimary;
      buttonAction = () => _requestActivation(context);

    }


    //  Determine Status Color
    Color statusColor = colorScheme.onSurfaceVariant;
    switch (line.status) {
      case LineStatus.filling:
        statusColor = Colors.blue.shade600;
        break;
      case LineStatus.heating:
        statusColor = Colors.orange.shade700;
        break;
      case LineStatus.stopped:
        statusColor = colorScheme.onSurfaceVariant;
        break;
      case LineStatus.error:
        statusColor = colorScheme.error;
        break;
      case LineStatus.running:
        statusColor = Colors.green.shade600;
        break;
    }

    // --- Calculate Amount Progress ---
    double? amountProgress;
    if (line.targetAmount != null &&
        line.targetAmount! > 0 &&
        line.processedAmount != null) {
      amountProgress =
          (line.processedAmount! / line.targetAmount!).clamp(0.0, 1.0);
    }
    // --- End Progress Calculation ---


    // Build the main content widget
    Widget content = Material(
      color: colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Status Display
              Text(
                'Line Status: ${line.statusString}',
                style: textTheme.titleLarge?.copyWith(
                  color: isError ? colorScheme.error : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Current Temp: ${line.displayTemp}°C (Target: ${line.targetTemp?.toStringAsFixed(1) ?? '-'}°C)',
              ),
              Text(
                'Processed Amount: ${line.displayAmount} / ${line.targetAmount?.toStringAsFixed(1) ?? '-'} L',
              ),
              // Show target amount too

              // Progress Indicator
              Visibility(
                // Show only if line is active AND progress is calculable
                visible: isActive && amountProgress != null,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: LinearProgressIndicator(
                    value: amountProgress,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              // Add space even if progress bar is not visible to maintain layout consistency
              if (!(isActive && amountProgress != null))
                const SizedBox(height: 12.0 + 6.0 + 4.0),
              const SizedBox(height: 16),


              // --- Control Panel Section ---
              Text('Control Panel', style: textTheme.titleMedium),
              const Divider(),
              const SizedBox(height: 16),

              // --- Input Fields ---
              TextFormField(
                controller: _tempController,
                decoration: InputDecoration(
                  labelText: 'Target Temperature (°C)',
                  border: const OutlineInputBorder(),
                  suffixText: '°C',
                  filled: !inputsEnabled,

                  fillColor: !inputsEnabled ? Colors.grey.shade200 : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                  // Allow one decimal place
                ],
                validator: (value) {
                  // Validation is checked on activation attempt
                  if (!inputsEnabled) return null;
                  if (value == null || value.isEmpty) {
                    return 'Please enter temperature';
                  }
                  final temp = double.tryParse(value);
                  if (temp == null) {
                    return 'Invalid number';
                  }
                  if (temp < 0 || temp > 150) {
                    return 'Temp must be 0-150°C';
                  }
                  return null;
                },
                enabled: inputsEnabled, // Enable based on line status
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount (L)',
                  border: const OutlineInputBorder(),
                  suffixText: 'L',
                  filled: !inputsEnabled,

                  // Visually indicate disabled state
                  fillColor: !inputsEnabled ? Colors.grey.shade200 : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                  // Allow positive numbers with one decimal
                ],
                validator: (value) {
                  // Validation is checked on activation attempt
                  if (!inputsEnabled) return null; // Don't validate if disabled
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Invalid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be positive';
                  }
                  return null;
                },
                enabled: inputsEnabled,
              ),
              const SizedBox(height: 24),

              // --- Activate/Deactivate Button ---
              Center(
                child: ElevatedButton.icon(
                  icon: Icon(buttonIcon),
                  label: Text(buttonLabel),
                  onPressed: buttonAction,
                  // Calls either _requestActivation or _requestDeactivation
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonBackgroundColor,
                    foregroundColor: buttonForegroundColor,
                    minimumSize: const Size(160, 45),
                    textStyle: textTheme.labelLarge,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Spacing

              // --- Reset Error Button  ---
              if (canResetError)
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset Error'),
                    onPressed: () => _resetError(context, line),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return content;
  }
}
