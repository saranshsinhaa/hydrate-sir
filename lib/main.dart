import 'package:flutter/material.dart';

import 'app/theme/theme.dart';

void main() {
  runApp(const HydrateSirApp());
}

class HydrateSirApp extends StatelessWidget {
  const HydrateSirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrate, Sir',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      themeMode: ThemeMode.light,
      home: const Scaffold(
        body: Center(child: Text('Hargreaves, at your service.')),
      ),
    );
  }
}
