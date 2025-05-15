import 'package:flutter/material.dart';
import 'package:controller_app/screens/productionline_detail_screen.dart';
import 'package:controller_app/controller/pasteurization_base.dart';
import 'package:controller_app/controller/pasteurization_simulation.dart';
import 'package:controller_app/controller/pasteurization_controller.dart';

/// ViewController for the main app shell.
/// Handles model creation, theme setup, and route definitions.
class MainViewController {
  final bool useSimulation;

  MainViewController(this.useSimulation);

  /// Creates the model based on the simulation flag.
  /// Can be either a simulation or a real MQTT controller.
  PasteurizationBase createModel() {
    return useSimulation
        ? PasteurizationSimulation()
        : PasteurizationController(
            'flutter-ui-${DateTime.now().millisecondsSinceEpoch}',
          );
  }

  /// Create a map of routes for the app.
  Map<String, WidgetBuilder> routes() {
    return {
      ProductionLineDetailScreen.routeName: (context) {
        final lineId =
            ModalRoute.of(context)?.settings.arguments as String?;
        if (lineId == null) {
          return const Scaffold(
            body: Center(child: Text("Error: No Line Id provided")),
          );
        }
        return ProductionLineDetailScreen(lineId: lineId);
      },
    };
  }
}
