import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/presentation/screens/sign_in_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AltrixApp(),
    ),
  );
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
