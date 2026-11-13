import 'package:flutter/material.dart';
import 'screens/chairman_dashboard_screen.dart';
import 'services/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = await SessionManager.getSession();
  runApp(VriydaPortalApp(initialSession: session));
}

class VriydaPortalApp extends StatelessWidget {
  final UserSession? initialSession;
  const VriydaPortalApp({super.key, this.initialSession});

  @override
  Widget build(BuildContext context) {
    final defaultChairman = UserSession(
      id: 'usr-demo-owner',
      token: 'demo-chairman-token',
      email: 'chairman@sairavindra.edu',
      name: 'Chairman',
      role: 'owner',
      organizationName: 'Sai Ravindra School',
      mustChangePassword: false,
    );

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
      home: ChairmanDashboardScreen(user: initialSession ?? defaultChairman),
    );
  }
}
