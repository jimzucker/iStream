import 'package:flutter/material.dart';

import 'ui/pipeline_form_screen.dart';

void main() {
  runApp(const IStreamApp());
}

class IStreamApp extends StatelessWidget {
  const IStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iStream',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const PipelineFormScreen(),
    );
  }
}
