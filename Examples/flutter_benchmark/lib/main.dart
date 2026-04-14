// Examples/flutter_benchmark/lib/main.dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: BenchmarkHomePage());
  }
}

class BenchmarkHomePage extends StatefulWidget {
  const BenchmarkHomePage({super.key});

  @override
  State<BenchmarkHomePage> createState() => _BenchmarkHomePageState();
}

class _BenchmarkHomePageState extends State<BenchmarkHomePage> {
  double _size = 0.0;
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();

    // Start animation after first frame
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _size = 100.0;
        _opacity = 1.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnimatedIcon(Icons.photo),
            const SizedBox(height: 25),
            _buildAnimatedIcon(Icons.camera_alt),
            const SizedBox(height: 25),
            _buildAnimatedIcon(Icons.star),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Opacity(
        opacity: _opacity,
        child: Icon(icon, size: 60, color: Colors.white),
      ),
    );
  }
}
