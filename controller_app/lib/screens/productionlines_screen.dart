import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:controller_app/simulation.dart';
import '../main.dart';
import 'productionline_detail_screen.dart';


// Production Lines Screen also default homescreen
class ProductionLines extends StatefulWidget {
  const ProductionLines({super.key});

  @override
  State<ProductionLines> createState() => _ProductionLineState();
}


class _ProductionLineState extends State<ProductionLines> {
  String? _selectedLineId;
  int _navigationIndex = 0;

  //Method for line selection on homescreen
  void _selectLine(String lineId) {
    if (!mounted) return;
    setState(() {
      // If the same line is selected and secondary is active, deselect it
      if (_selectedLineId == lineId &&
          Breakpoints.mediumAndUp.isActive(context)) {
        _selectedLineId = null;
      } else {
        _selectedLineId = lineId;
      }
    });
  }

  // Helper to build the list view.
  Widget _buildListView(BuildContext context,
      PasteurizationSimulation service) {
    final lines = service.lines;
    final colorScheme = Theme
        .of(context)
        .colorScheme;
    final textTheme = Theme
        .of(context)
        .textTheme;



    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];

          // --- Status & Icon/Color Logic ---
          final bool isFilling = line.status == LineStatus.filling;
          final bool isHeating = line.status == LineStatus.heating;
          final bool isRunning = line.status == LineStatus.running;
          final bool isError = line.status == LineStatus.error;
          // Combine active states that should show progress
          final bool isActive = isFilling || isHeating || isRunning;

          IconData statusIcon = Icons.device_unknown;
          Color statusColor = colorScheme.onSurfaceVariant;

          // Determine icon/color based on status
          switch (line.status) {
            case LineStatus.filling:
              statusIcon = Icons.water_drop_outlined;
              statusColor = Colors.blue.shade600;
              break;
            case LineStatus.heating:
              statusIcon = Icons.thermostat_auto_outlined;
              statusColor = Colors.orange.shade700;
              break;
            case LineStatus.stopped:
              statusIcon = Icons.stop_circle_outlined;
              statusColor = colorScheme.onSurfaceVariant;
              break;
            case LineStatus.error:
              statusIcon = Icons.error;
              statusColor = colorScheme.error;
              break;
            case LineStatus.running:
              statusIcon = Icons.play_circle_fill;
              statusColor = Colors.green.shade600;
              break;
          }
          final bool isSelected = _selectedLineId == line.id && Breakpoints.mediumAndUp.isActive(context);

          // Build list tile within a card
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: Icon(statusIcon, color: statusColor),
              title: Text(line.name),
              subtitle: Text(
                'Status: ${line.statusString} | Temp:${line.currentTemp
                    .toStringAsFixed(1)}°C | Amount: ${line.processedAmount
                    .toStringAsFixed(1)}/${line.targetAmount.toStringAsFixed(
                    1)}L',
          style: textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
            ),
              selected: isSelected,
              onTap: () => _selectLine(line.id),

              selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
              selectedColor: colorScheme.onPrimaryContainer,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, String lineId) {

    final bool isSecondaryActive = Breakpoints.mediumAndUp.isActive(context);
    return Scaffold(
      appBar: !isSecondaryActive ? AppBar(
        title: Text("$lineId"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedLineId = null;
            });
          },
        ),
      ) : null, // No AppBar needed for secondary body
      body: ProductionLineDetailScreen(lineId: lineId),
    );
  }


// Build Method for ProductionLines
  @override
  Widget build(BuildContext context) {
    final bool isMediumOrLarger = Breakpoints.mediumAndUp.isActive(context);
    final simulation = context.watch<PasteurizationSimulation>();
    final bool shouldShowSecondary =
        _selectedLineId != null &&
            _navigationIndex == 0 &&
            isMediumOrLarger;
    final WidgetBuilder? secondaryBodyBuilder = shouldShowSecondary
        ? (builderContext) => _buildDetailContent(builderContext, _selectedLineId!)
        : null;

    return AdaptiveScaffold(
      selectedIndex: _navigationIndex,
      onSelectedIndexChange: (index) {
        setState(() {
          _navigationIndex = index;
          _selectedLineId = null;
        });
      },
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.list_alt), label: "Lines"),
        NavigationDestination(icon: Icon(Icons.settings), label: "Settings")
      ],
      appBar: AppBar(
        title: Text(
          _navigationIndex == 0 ? 'Production Lines' : 'Settings',
        ),
      ),
      body: (_) {
        switch (_navigationIndex) {
          case 0:
            if (!isMediumOrLarger && _selectedLineId != null) {
              return _buildDetailContent(context, _selectedLineId!);
            }
            return _buildListView(context, simulation);
          case 1:
            return const SettingsScreen();
          default:
            return const Center(child: Text("Error"));
        }
      },
      secondaryBody: secondaryBodyBuilder,

    );
  }
}