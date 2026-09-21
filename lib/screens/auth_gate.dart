import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';

/// Root widget that decides what to show based on auth state:
/// - Loading -> splash/progress indicator
/// - Not signed in -> LoginScreen
/// - Signed in -> HomeScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    if (authService.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!authService.isSignedIn) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}