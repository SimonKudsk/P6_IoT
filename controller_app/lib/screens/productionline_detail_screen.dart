import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controller/pasteurization_base.dart';
import '../viewcontroller/productionline_detail_viewcontroller.dart';
import 'widgets/line_details.dart';
import 'widgets/line_controlpanel.dart';

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
  late ProductionLineDetailViewController _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllersInitialized) {
      final simulation = context.read<PasteurizationBase>();
      final line = simulation.getLineById(widget.lineId)!;
      _controller = ProductionLineDetailViewController(
        line: line,
        colorScheme: Theme.of(context).colorScheme,
        tempController: _tempController,
        amountController: _amountController,
        service: simulation,
      );
      _tempController.text = _controller.initialTempText;
      _amountController.text = _controller.initialAmountText;
      _controllersInitialized = true;
    }
  }

  @override
  void dispose() {
    _tempController.dispose();
    _amountController.dispose();
    super.dispose();
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

    // Build the main content widget
    Widget content = Material(
      type: MaterialType.transparency,  // don’t paint a background here
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildInformationCard(
                context,
                line,
                textTheme,
                _controller.statusColor,
                _controller.isActive,
                _controller.amountProgress,
              ),
              const SizedBox(height: 16.0),  // a bit of breathing room
              buildControlPanelCard(
                context,
                _controller,
                _formKey,
              ),
            ],
          ),
        ),
      ),
    );
    return content;
  }
}
