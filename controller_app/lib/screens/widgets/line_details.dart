import 'package:flutter/material.dart';
import '../../model/line.dart';

/// Builds the status and info display for a production line.
Widget buildStatusSection(Line line, TextTheme textTheme, Color statusColor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Line Status: ${line.statusString}',
        style: textTheme.titleLarge?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      Text('Error Message: ${line.displayErrorMsg}'),
      Text('Lot number: ${line.displayLotNumber}'),
      Text('Current Temp: ${line.displayTemp}°C (Target: ${line.displayTargetTemp}°C)'),
      Text('Processed Amount: ${line.displayAmount} / ${line.displayTargetAmount} L'),
    ],
  );
}

/// Builds the progress indicator for a production line.
Widget buildProgressSection(
    BuildContext context,
    bool isActive,
    double? amountProgress,
    Color statusColor,
) {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1, bottom: 8),
        child: Opacity(
          opacity: (isActive && amountProgress != null) ? 1.0 : 0.2,
          child: LinearProgressIndicator(
            value: amountProgress ?? 0,
            minHeight: 6,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            valueColor:
            AlwaysStoppedAnimation<Color>(statusColor),
          ),
        ),
      ),
    ],
  );
}

/// Wraps status and progress into a card.
Widget buildInformationCard(
  BuildContext context,
  Line line,
  TextTheme textTheme,
  Color statusColor,
  bool isActive,
  double? amountProgress,
) {
  return Card(
    margin: const EdgeInsets.only(bottom: 0),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildStatusSection(line, textTheme, statusColor),
          const SizedBox(height: 16),
          buildProgressSection(context, isActive, amountProgress, statusColor),
        ],
      ),
    ),
  );
}
