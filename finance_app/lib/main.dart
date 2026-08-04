import 'package:flutter/material.dart';
import 'screens/01_splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DT7AgencyFinanceApp());
}

class DT7AgencyFinanceApp extends StatelessWidget {
  const DT7AgencyFinanceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DT7 Agency Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
