import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isAuthenticated = await AuthService.isAuthenticated();
  runApp(DT7FinanceApp(isAuthenticated: isAuthenticated));
}

class DT7FinanceApp extends StatelessWidget {
  final bool isAuthenticated;

  const DT7FinanceApp({Key? key, required this.isAuthenticated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DT7 Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: isAuthenticated ? const HomeDashboardScreen() : const LoginScreen(),
    );
  }
}
