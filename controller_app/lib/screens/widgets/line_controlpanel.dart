import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../viewcontroller/productionline_detail_viewcontroller.dart';

/// Builds the control panel section (inputs & buttons).
Widget buildControlPanelSection(
  BuildContext context,
  ProductionLineDetailViewController controller,
  GlobalKey<FormState> formKey,
) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Control Panel', style: theme.textTheme.titleMedium),
      const SizedBox(height: 16),

      // Input field for target temperature
      TextFormField(
        controller: controller.tempController,
        decoration: InputDecoration(
          labelText: 'Target Temperature (°C)',
          border: const OutlineInputBorder(),
          suffixText: '°C',
          filled: !controller.inputsEnabled,
          fillColor: !controller.inputsEnabled ? Colors.grey.shade200 : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
        ],
        validator: controller.validateTemp,
        enabled: controller.inputsEnabled,
      ),
      const SizedBox(height: 16),

      // Input field for target amount
      TextFormField(
        controller: controller.amountController,
        decoration: InputDecoration(
          labelText: 'Target Amount (L)',
          border: const OutlineInputBorder(),
          suffixText: 'L',
          filled: !controller.inputsEnabled,
          fillColor: !controller.inputsEnabled ? Colors.grey.shade200 : null,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          TextInputFormatter.withFunction((oldValue, newValue) =>
            newValue.copyWith(text: newValue.text.replaceAll(',', '.'))),
        ],
        validator: controller.validateAmount,
        enabled: controller.inputsEnabled,
      ),
      const SizedBox(height: 24),

      // Show activation/deactivation button
      Center(
        child: ElevatedButton.icon(
          icon: Icon(controller.buttonIcon),
          label: Text(controller.buttonLabel),
          onPressed: controller.isActive
              ? () => controller.requestDeactivation()
              : () => controller.requestActivation(formKey, context),
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.buttonBackgroundColor,
            foregroundColor: controller.buttonForegroundColor,
            minimumSize: const Size(160, 45),
            textStyle: theme.textTheme.labelLarge,
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Show reset error button only if there is an error
      if (controller.canResetError)
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Error'),
            onPressed: () => controller.requestResetError(),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
          ),
        ),
    ],
  );
}

/// Wraps the control panel into a card.
Widget buildControlPanelCard(
  BuildContext context,
  ProductionLineDetailViewController controller,
  GlobalKey<FormState> formKey,
) {
  return Card(
    margin: const EdgeInsets.only(top: 0),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: buildControlPanelSection(context, controller, formKey),
    ),
  );
}
