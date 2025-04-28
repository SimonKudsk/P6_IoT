import 'package:controller_app/screens/Productionline_detail_screen.dart';
import 'package:controller_app/screens/productionlines_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:controller_app/simulation.dart';

void main() {
  runApp(
    //ChangeNotifierProvider used to run the simulation
    ChangeNotifierProvider(
      create: (context) => PasteurizationSimulation(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Theme/design code ---

    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
    final appTheme = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: colorScheme.surfaceContainerLow,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surfaceContainerLow,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,

        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
      ),

      cardTheme: CardTheme(
        elevation: 0,
        color: colorScheme.surface,
        margin: const EdgeInsets.only(bottom: 8.0),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0)),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );


    // --- MAterialApp definition ---

    return MaterialApp(

      title: 'Production App',
      home: const ProductionLines(),
      debugShowCheckedModeBanner: false,
      theme: appTheme,

      routes: {
        ProductionLineDetailScreen.routeName: (context) {
          final lineId = ModalRoute.of(context)?.settings.arguments as String?;
          if (lineId == null) {
            return const Scaffold(
              body: Center(child: Text("Error: No Line Id provided")),
            );
          }
              return ProductionLineDetailScreen(lineId: lineId);
        },
      },
    );
  }
}

// --- Settings screen ---

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(
      'Settings placeholder',
      textAlign: TextAlign.center,
    ),
    );
  }
}




