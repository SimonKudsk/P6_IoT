import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

    return MaterialApp(
      title: 'Pasteurization App',
      theme: ThemeData(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
      ),
      home: const PasteurizationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class PasteurizationScreen extends StatefulWidget {
  const PasteurizationScreen({super.key});

  @override
  State<PasteurizationScreen> createState() => _PasteurizationScreenState();
}

class _PasteurizationScreenState extends State<PasteurizationScreen> {
  int? _selectedListItemIndex;
  final List<String> _lines = ['Pasteurization line 1', 'Pasteurization line 2'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool isItemSelected = _selectedListItemIndex != null;
    final bool showSecondaryBody = isItemSelected && Breakpoints.medium.isActive(context);
    final bool showSmallBody = isItemSelected && !Breakpoints.medium.isActive(context);

    return AdaptiveScaffold(
      // No key
      destinations: const <NavigationDestination>[
        NavigationDestination(icon: Icon(Icons.list_alt), label: 'Lines'),
        NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
      ],
      selectedIndex: 0,
      body: (_) => _buildListView(context, colorScheme),
      secondaryBody: showSecondaryBody ? (_) => _buildDetailContent(context, colorScheme) : null,
      smallBody: showSmallBody ? (_) => Scaffold(
        appBar: AppBar(
          title: Text(_lines[_selectedListItemIndex!]),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => setState(() => _selectedListItemIndex = null),
          ),
        ),
        body: _buildDetailContent(context, colorScheme),
      ) : null,
      appBar: AppBar(
        title: Text(isItemSelected ? _lines[_selectedListItemIndex!] : 'Pasteurization lines'),
        leading: showSmallBody
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedListItemIndex = null),
        )
            : null,
        actions: const [],
      ),
    );
  }

  Widget _buildListView(BuildContext context, ColorScheme colorScheme) {
    // Use SafeArea to avoid OS intrusions (status bar, bottom nav bar space if shown)
    return SafeArea(
      top: false, // AppBar provides top padding
      // bottom: true, // Keep default true for potential bottom nav bar
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        // Use Column + Expanded for ListView to ensure proper layout
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Ensure SearchBar takes full width
          children: <Widget>[
            const SizedBox(height: 16),
            // **MODIFICATION:** Use Expanded around the ListView
            Expanded(
              child: ListView.builder(
                // REMOVED: shrinkWrap and physics (not needed with Expanded)
                itemCount: _lines.length,
                itemBuilder: (context, i) => Card( // Using CardTheme
                  child: ListTile(
                    title: Text(_lines[i]),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => setState(() => _selectedListItemIndex = i),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colorScheme.surface,
      child: Center(
        child: ElevatedButton(
          onPressed: _selectedListItemIndex == null ? null : () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Activating ${_lines[_selectedListItemIndex!]}...')),
            );
          },
          child: const Text('Activate'),
        ),
      ),
    );
  }
}