import 'package:flutter/material.dart';

import 'screens/sign_in_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const AltrixApp());
}

class AltrixApp extends StatelessWidget {
  const AltrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Altrixs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const SignInScreen(),
    );
  }
}
