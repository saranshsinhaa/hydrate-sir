import 'package:flutter/material.dart';

void main() {
  runApp(const HydrateSirApp());
}

/// Placeholder shell; replaced screen by screen as features land.
class HydrateSirApp extends StatelessWidget {
  const HydrateSirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Hydrate, Sir',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text('Hargreaves, at your service.'))),
    );
  }
}
