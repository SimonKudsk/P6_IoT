import 'package:controller_app/app_theme.dart';
import 'package:controller_app/screens/productionlines_screen.dart';
import 'package:controller_app/viewcontroller/main_view_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:controller_app/model/settings_model.dart';
import 'package:controller_app/controller/pasteurization_base.dart';

void main() async {
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the app settings
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppSettings(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        // Create the main view controller and model based on settings
        final controller = MainViewController(settings.useSimulation);
        final model = controller.createModel();
        final appTheme = AppTheme.createTheme();

        // Create the main app widget
        Widget app = MaterialApp(
          title: 'Production App',
          home: const ProductionLines(),
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          routes: controller.routes(),
        );

        return ChangeNotifierProvider<PasteurizationBase>(
          key: ValueKey(settings.useSimulation), // forces rebuild when toggled
          create: (_) => model,
          child: app,
        );
      },
    );
  }
}