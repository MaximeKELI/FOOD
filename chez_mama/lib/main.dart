import 'package:flutter/material.dart';
import 'ui/chezmama_theme.dart';
import 'screens/splash/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChezMamaApp());
}

class ChezMamaApp extends StatelessWidget {
  const ChezMamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChezMama',
      theme: ChezMamaTheme.light(),
      home: const SplashScreen(),
    );
  }
}
