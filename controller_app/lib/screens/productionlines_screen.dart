import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:provider/provider.dart';
import '../model/line.dart';
import '../viewcontroller/productionlines_screen_viewcontroller.dart';
import 'settings_screen.dart';
import '../controller/pasteurization_base.dart';
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

  List<NavigationDestination> _buildDestinations() => const [
    NavigationDestination(icon: Icon(Icons.list_alt), label: "Lines"),
    NavigationDestination(icon: Icon(Icons.settings), label: "Settings"),
  ];

  /// Builds the app bar for the screen
  AppBar _buildAppBar(bool isDesktop) {
    return AppBar(
      title: Text(
        _navigationIndex == 0 ? 'Production Lines' : 'Settings',
      ),
      leading: (!isDesktop && _navigationIndex == 0 && _selectedLineId != null)
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedLineId = null),
            )
          : null,
    );
  }

  /// Builds the main content of the screen
  Widget _buildMainContent(BuildContext context, PasteurizationBase service, bool isDesktop) {
    switch (_navigationIndex) {
      case 0:
        if (!isDesktop && _selectedLineId != null) {
          return _buildDetailPane(context, _selectedLineId!);
        }
        return _buildListView(context, service);
      case 1:
        return const SettingsScreen();
      default:
        return const Center(child: Text("Error"));
    }
  }


  /// Builds a card for each production line in the list
  Widget _buildListCard(BuildContext context, ProductionLinesScreenViewController controller, Line line) {
    final statusIcon = controller.getStatusIcon(line);
    final statusColor = controller.getStatusColor(line, Theme.of(context).colorScheme);
    final isSelected = _selectedLineId == line.id && Breakpoints.mediumAndUp.isActive(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: Icon(statusIcon, color: statusColor),
        title: Text(line.name),
        subtitle: Text(
          controller.subtitle(line),
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        selected: isSelected,
        onTap: () {
          final newSelection = controller.computeNewSelection(
            _selectedLineId,
            line.id,
            Breakpoints.mediumAndUp.isActive(context),
          );
          setState(() => _selectedLineId = newSelection);
        },
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        selectedColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  /// Builds the list view of production lines
  Widget _buildListView(BuildContext context, PasteurizationBase service) {
    final controller = ProductionLinesScreenViewController(service);
    final lines = controller.lines;
    return SafeArea(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          return _buildListCard(context, controller, lines[index]);
        },
      ),
    );
  }

  /// Builds the detail pane for a selected production line
  Widget _buildDetailPane(BuildContext context, String lineId) {
    final isSecondaryActive = Breakpoints.mediumAndUp.isActive(context);
    return Scaffold(
      appBar: !isSecondaryActive
          ? AppBar(
              title: Text(lineId),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedLineId = null),
              ),
            )
          : null,
      body: ProductionLineDetailScreen(lineId: lineId),
    );
  }

  /// Builds the main screen layout
  @override
  Widget build(BuildContext context) {
    final bool isMediumOrLarger = Breakpoints.mediumAndUp.isActive(context);
    final service = context.watch<PasteurizationBase>();
    final bool shouldShowSecondary =
        _selectedLineId != null &&
            _navigationIndex == 0 &&
            isMediumOrLarger;

    // Use AdaptiveScaffold to create a responsive layout, adapting to the screen size
    return AdaptiveScaffold(
      selectedIndex: _navigationIndex,
      onSelectedIndexChange: (index) {
        setState(() {
          _navigationIndex = index;
          _selectedLineId = null;
        });
      },
      destinations: _buildDestinations(),
      appBar: _buildAppBar(isMediumOrLarger),
      body: (_) => _buildMainContent(context, service, isMediumOrLarger),
      secondaryBody: shouldShowSecondary
          ? (builderContext) => _buildDetailPane(builderContext, _selectedLineId!)
          : null,
    );
  }
}