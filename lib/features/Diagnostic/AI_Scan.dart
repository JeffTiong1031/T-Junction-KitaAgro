import 'package:flutter/material.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Diagnostics')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text('Scan a leaf to detect diseases'),
            const SizedBox(height: 20),
            FloatingActionButton.large(
              onPressed: () {},
              child: const Icon(Icons.camera_alt),
            ),
          ],
        ),
      ),
    );
  }
}
