import 'package:flutter/material.dart';
import 'screens/vriyda_splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VriydaPortalApp());
}

class VriydaPortalApp extends StatelessWidget {
  const VriydaPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vriyda Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF14173E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF818CF8),
          surface: Color(0xFF1B1B4D),
        ),
        fontFamily: '-apple-system',
        useMaterial3: true,
      ),
      home: const VriydaSplashScreen(),
    );
  }
}
