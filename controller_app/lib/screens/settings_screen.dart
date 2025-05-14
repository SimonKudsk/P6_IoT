import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:controller_app/model/settings_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettings>(
      builder: (context, settings, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Use simulation data'),
              subtitle: const Text('Uses simulation instead of real data when enabled.'),
              value: settings.useSimulation,
              onChanged: (val) => settings.useSimulation = val,
            ),
          ],
        );
      },
    );
  }
}
